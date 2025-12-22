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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlarms();
    });
  }

  String _repeatText(Map<String, bool> days) {
    final active = days.entries.where((e) => e.value).map((e) => e.key).toList();
    if (active.isEmpty) return '';
    if (active.length == 7) return 'Diaria';
    if (active.length == 5 && active.contains('mon') && active.contains('tue') && active.contains('wed') && active.contains('thu') && active.contains('fri')) return 'Lunes a viernes';
    if (active.length == 2 && active.contains('sat') && active.contains('sun')) return 'Fines de semana';

    const dayNames = {
      'sun': 'Dom',
      'mon': 'Lun',
      'tue': 'Mar',
      'wed': 'Mié',
      'thu': 'Jue',
      'fri': 'Vie',
      'sat': 'Sáb'
    };
    return active.map((d) => dayNames[d] ?? '').join(', ');
  }

  Future<void> _loadAlarms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final firebaseAlarms = await FirebaseAlarmService.loadAlarmsFromFirebase();
      if (firebaseAlarms.isNotEmpty) {
        setState(() => alarms = firebaseAlarms);
        await AlarmStorage.saveAlarms(alarms);
      } else {
        final local = await AlarmStorage.loadAlarms();
        setState(() => alarms = local);
        for (final alarm in alarms) {
          if (alarm.key == null) {
            final newKey = await FirebaseAlarmService.addAlarm(alarm);
            alarm.key = newKey;
          }
        }
        await AlarmStorage.saveAlarms(alarms);
      }

      for (final alarm in alarms) {
        if (alarm.isEnabled) {
          await NotificationService.scheduleAlarm(
            id: alarm.hashCode,  // Usamos hashCode como ID temporal para notificaciones
            title: alarm.title,
            body: '¡Hora de alimentar!',
            scheduledDate: alarm.time,
          );
        }
      }

      FirebaseAlarmService.alarmsStream.listen((updatedAlarms) {
        if (mounted) {
          setState(() => alarms = updatedAlarms);
          AlarmStorage.saveAlarms(alarms);
        }
      });
    } catch (e) {
      final local = await AlarmStorage.loadAlarms();
      setState(() => alarms = local);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAlarms() async {
    await AlarmStorage.saveAlarms(alarms);
    for (final alarm in alarms) {
      if (alarm.key == null) {
        final newKey = await FirebaseAlarmService.addAlarm(alarm);
        alarm.key = newKey;
      } else {
        await FirebaseAlarmService.updateAlarm(alarm.key!, alarm);
      }
    }
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
      final newKey = await FirebaseAlarmService.addAlarm(result);
      result.key = newKey;
      setState(() {
        alarms.add(result);
      });
      await AlarmStorage.saveAlarms(alarms);
      await NotificationService.scheduleAlarm(
        id: result.hashCode,
        title: result.title,
        body: '¡Hora de alimentar!',
        scheduledDate: result.time,
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
        existingAlarm.repeatDays = result.repeatDays;
      });
      await _saveAlarms();

      if (existingAlarm.isEnabled) {
        await NotificationService.cancelAlarm(existingAlarm.hashCode);
        await NotificationService.scheduleAlarm(
          id: existingAlarm.hashCode,
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
        id: alarm.hashCode,
        title: alarm.title,
        body: '¡Hora de alimentar!',
        scheduledDate: alarm.time,
      );
    } else {
      await NotificationService.cancelAlarm(alarm.hashCode);
    }
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    final index = alarms.indexOf(alarm);
    setState(() {
      alarms.remove(alarm);
    });
    await AlarmStorage.saveAlarms(alarms);
    await FirebaseAlarmService.deleteAlarm(alarm.key!);
    await NotificationService.cancelAlarm(alarm.hashCode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarma eliminada'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            setState(() {
              alarms.insert(index, alarm);
            });
            await AlarmStorage.saveAlarms(alarms);
            if (alarm.key == null) {
              final newKey = await FirebaseAlarmService.addAlarm(alarm);
              alarm.key = newKey;
            } else {
              await FirebaseAlarmService.updateAlarm(alarm.key!, alarm);
            }
            if (alarm.isEnabled) {
              await NotificationService.scheduleAlarm(
                id: alarm.hashCode,
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
                      key: Key(alarm.key ?? alarm.hashCode.toString()),
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
                            if (alarm.repeatDays.values.any((v) => v))
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