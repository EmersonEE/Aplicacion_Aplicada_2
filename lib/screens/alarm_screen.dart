import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../services/notification_service.dart';
import '../services/alarm_storage.dart';
import 'alarm_edit_screen.dart';
import '../services/firebase_service.dart';

class AlarmScreen extends StatefulWidget {
  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<Alarm> alarms = [];
  int nextId = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlarms();
    });
  }

  // Función auxiliar para mostrar texto de repetición
  String _repeatText(List<int> days) {
    if (days.isEmpty) return '';
    if (days.length == 7) return 'Diaria';
    if (days.length == 5 && !days.contains(0) && !days.contains(6)) return 'Lunes a viernes';
    if (days.length == 2 && days.contains(0) && days.contains(6)) return 'Fines de semana';

    const dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return days.map((d) => dayNames[d]).join(', ');
  }

  Future<void> _loadAlarms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseAlarmService.db.get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<Alarm> firebaseAlarms = data.entries.map((e) {
          final json = Map<String, dynamic>.from(e.value);
          return Alarm.fromJson(json);
        }).toList();

        setState(() {
          alarms = firebaseAlarms;
          if (alarms.isNotEmpty) {
            nextId = alarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
          }
        });
      } else {
        final local = await AlarmStorage.loadAlarms();
        setState(() {
          alarms = local;
          if (alarms.isNotEmpty) {
            nextId = alarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
          }
        });
        await FirebaseAlarmService.uploadAlarms(alarms);
      }

      for (final alarm in alarms) {
        if (alarm.isEnabled) {
          await NotificationService.scheduleAlarm(
            id: alarm.id,
            title: alarm.title,
            body: '¡Hora de alimentar!',
            scheduledDate: alarm.time,
          );
        }
      }

      FirebaseAlarmService.alarmsStream.listen((updatedAlarms) {
        if (mounted) {
          setState(() {
            alarms = updatedAlarms;
          });
        }
      });
    } catch (e) {
      final local = await AlarmStorage.loadAlarms();
      setState(() {
        alarms = local;
        _isLoading = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAlarms() async {
    await AlarmStorage.saveAlarms(alarms);
    await FirebaseAlarmService.uploadAlarms(alarms);
  }

  void _addAlarm() async {
    final result = await Navigator.push<Alarm>(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(
          onSave: (alarm) {
            Navigator.pop(context, alarm);
          },
        ),
      ),
    );

    if (result != null) {
      final newAlarm = Alarm(
        id: nextId++,
        title: result.title,
        time: result.time,
        grams: result.grams,
        repeatDays: result.repeatDays,  // ← Guardamos repetición
      );

      setState(() {
        alarms.add(newAlarm);
      });
      await _saveAlarms();
      await NotificationService.scheduleAlarm(
        id: newAlarm.id,
        title: newAlarm.title,
        body: '¡Hora de alimentar!',
        scheduledDate: newAlarm.time,
      );
    }
  }

  Future<void> _editAlarm(Alarm existingAlarm) async {
    final result = await Navigator.push<Alarm>(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(
          existingAlarm: existingAlarm,
          onSave: (alarm) {
            Navigator.pop(context, alarm);
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        existingAlarm.title = result.title;
        existingAlarm.time = result.time;
        existingAlarm.grams = result.grams;
        existingAlarm.repeatDays = result.repeatDays;  // ← Actualizamos repetición
      });
      await _saveAlarms();

      if (existingAlarm.isEnabled) {
        await NotificationService.cancelAlarm(existingAlarm.id);
        await NotificationService.scheduleAlarm(
          id: existingAlarm.id,
          title: existingAlarm.title,
          body: '¡Hora de alimentar!',
          scheduledDate: existingAlarm.time,
        );
      }
    }
  }

  void _toggleAlarm(Alarm alarm) async {
    setState(() {
      alarm.isEnabled = !alarm.isEnabled;
    });
    await _saveAlarms();

    if (alarm.isEnabled) {
      await NotificationService.scheduleAlarm(
        id: alarm.id,
        title: alarm.title,
        body: '¡Hora de alimentar!',
        scheduledDate: alarm.time,
      );
    } else {
      await NotificationService.cancelAlarm(alarm.id);
    }
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    final index = alarms.indexOf(alarm);
    setState(() {
      alarms.remove(alarm);
    });
    await _saveAlarms();
    await NotificationService.cancelAlarm(alarm.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarma eliminada'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            setState(() {
              alarms.insert(index, alarm);
            });
            await _saveAlarms();
            if (alarm.isEnabled) {
              await NotificationService.scheduleAlarm(
                id: alarm.id,
                title: alarm.title,
                body: '¡Hora de alimentar!',
                scheduledDate: alarm.time,
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alarmas')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : alarms.isEmpty
              ? Center(child: Text('No hay alarmas. ¡Agrega una!'))
              : ListView.builder(
                  itemCount: alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = alarms[index];
                    return Dismissible(
                      key: Key(alarm.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      onDismissed: (direction) => _deleteAlarm(alarm),
                      child: ListTile(
                        title: Text(alarm.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('HH:mm').format(alarm.time)),
                            Text('${alarm.grams}g de alimento'),
                            if (alarm.repeatDays.isNotEmpty)
                              Text(
                                _repeatText(alarm.repeatDays),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                        trailing: Switch(
                          value: alarm.isEnabled,
                          onChanged: (_) => _toggleAlarm(alarm),
                        ),
                        onTap: () => _editAlarm(alarm),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: Icon(Icons.add_alarm),
      ),
    );
  }
}