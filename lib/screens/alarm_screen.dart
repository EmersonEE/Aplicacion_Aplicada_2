import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../services/notification_service.dart';
import '../services/alarm_storage.dart';
import 'alarm_edit_screen.dart';

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

    setState(() {
      _isLoading = true;
    });

    try {
      final loadedAlarms = await AlarmStorage.loadAlarms();

      if (!mounted) return;

      setState(() {
        alarms = loadedAlarms;
        if (alarms.isNotEmpty) {
          nextId = alarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
        }
        _isLoading = false;
      });

      // Reprogramar alarmas habilitadas al abrir la app
      for (final alarm in alarms) {
        if (alarm.isEnabled) {
          DateTime scheduledDate = alarm.time;

          if (scheduledDate.isBefore(DateTime.now())) {
            scheduledDate = DateTime(
              scheduledDate.year,
              scheduledDate.month,
              scheduledDate.day + 1,
              scheduledDate.hour,
              scheduledDate.minute,
            );
            alarm.time = scheduledDate; // Actualiza la hora mostrada
          }

          try {
            await NotificationService.scheduleAlarm(
              id: alarm.id,
              title: alarm.title,
              body: '¡Hora de despertar!',
              scheduledDate: scheduledDate,
            );
          } catch (e) {
            print('Error reprogramando alarma ${alarm.id}: $e');
          }
        }
      }
      await _saveAlarms(); // Guarda las horas actualizadas
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando alarmas: $e')));
      }
    }
  }

  Future<void> _saveAlarms() async {
    await AlarmStorage.saveAlarms(alarms);
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
