import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/notification_service.dart';
import '../services/alarm_storage.dart';

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

      // Reprogramar alarmas habilitadas
      for (final alarm in alarms) {
        if (alarm.isEnabled) {
          await NotificationService.scheduleAlarm(
            id: alarm.id,
            title: alarm.title,
            body: '¡Hora de despertar!',
            scheduledDate: alarm.time,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando alarmas: $e')),
        );
      }
    }
  }

  Future<void> _saveAlarms() async {
    await AlarmStorage.saveAlarms(alarms);
  }

  void _addAlarm() async {
    final now = DateTime.now();
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(Duration(hours: 1))),
    );

    if (selectedTime != null) {
      DateTime alarmTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(Duration(days: 1));
      }

      final alarm = Alarm(id: nextId++, title: 'Alarma ${nextId - 1}', time: alarmTime);

      setState(() {
        alarms.add(alarm);
      });
      await _saveAlarms();

      await NotificationService.scheduleAlarm(
        id: alarm.id,
        title: alarm.title,
        body: '¡Hora de despertar!',
        scheduledDate: alarm.time,
      );
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

  void _deleteAlarm(Alarm alarm) async {
    setState(() {
      alarms.remove(alarm);
    });
    await _saveAlarms();
    await NotificationService.cancelAlarm(alarm.id);
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
                    return ListTile(
                      title: Text(alarm.title),
                      subtitle: Text(alarm.time.toString().substring(11, 16)),
                      trailing: Switch(
                        value: alarm.isEnabled,
                        onChanged: (_) => _toggleAlarm(alarm),
                      ),
                      onLongPress: () => _deleteAlarm(alarm),
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