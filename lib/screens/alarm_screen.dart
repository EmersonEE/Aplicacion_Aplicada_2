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
  Future<void> _loadAlarms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Primero intenta cargar desde Firebase
      //    Firebase (esto será casi instantáneo si hay internet)
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
        // 2. Si Firebase está vacío → carga desde SharedPreferences (respaldo)
        final local = await AlarmStorage.loadAlarms();
        setState(() {
          alarms = local;
          if (alarms.isNotEmpty) {
            nextId = alarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
          }
        });
        // y sube lo local a Firebase por primera vez
        await FirebaseAlarmService.uploadAlarms(alarms);
      }

      // Reprogramar todas las alarmas habilitadas
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

      // 3. Escuchar cambios en tiempo real (para futuras sincronizaciones)
      FirebaseAlarmService.alarmsStream.listen((updatedAlarms) {
        if (mounted) {
          setState(() {
            alarms = updatedAlarms;
          });
        }
      });

    } catch (e) {
      // Si falla internet, carga desde local
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
    // Guardar localmente (por si no hay internet)
    await AlarmStorage.saveAlarms(alarms);
    // Subir a Firebase (si hay internet, si no hay internet simplemente no hace nada)
    await FirebaseAlarmService.uploadAlarms(alarms);
  }
  void _addAlarm() async {
    final newId = nextId++;
    final result = await Navigator.push<Alarm>(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(
          onSave: (alarm) {
            Navigator.pop(
              context,
              Alarm(id: newId, title: alarm.title, time: alarm.time),
            );
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        alarms.add(result);
      });
      await _saveAlarms();
      await NotificationService.scheduleAlarm(
        id: result.id,
        title: result.title,
        body: '¡Hora de despertar!',
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
      });
      await _saveAlarms();

      if (existingAlarm.isEnabled) {
        await NotificationService.cancelAlarm(existingAlarm.id);
        await NotificationService.scheduleAlarm(
          id: existingAlarm.id,
          title: existingAlarm.title,
          body: '¡Hora de despertar!',
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
        body: '¡Hora de despertar!',
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
                body: '¡Hora de despertar!',
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
                    subtitle: Text(DateFormat('HH:mm').format(alarm.time)),
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
