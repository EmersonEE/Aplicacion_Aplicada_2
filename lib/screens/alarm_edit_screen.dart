import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import 'repeat_selection_screen.dart'; // ← Nuevo archivo que creamos antes

class AlarmEditScreen extends StatefulWidget {
  final Alarm? existingAlarm;
  final Function(Alarm alarm) onSave;

  const AlarmEditScreen({
    Key? key,
    this.existingAlarm,
    required this.onSave,
  }) : super(key: key);

  @override
  _AlarmEditScreenState createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late TextEditingController _titleController;
  late DateTime _selectedTime;
  late List<int> _repeatDays;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingAlarm?.title ?? 'Alarma');
    _selectedTime = widget.existingAlarm?.time ?? DateTime.now().add(Duration(hours: 1));
    _repeatDays = widget.existingAlarm?.repeatDays ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _repeatText() {
    if (_repeatDays.isEmpty) return 'Ninguna';
    if (_repeatDays.length == 7) return 'Diaria';
    if (_repeatDays.length == 5 && !_repeatDays.contains(0) && !_repeatDays.contains(6)) return 'Lunes a viernes';
    if (_repeatDays.length == 2 && _repeatDays.contains(0) && _repeatDays.contains(6)) return 'Fines de semana';

    const dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return _repeatDays.map((d) => dayNames[d]).join(', ');
  }

  void _saveAlarm() {
    final title = _titleController.text.trim().isEmpty ? 'Alarma' : _titleController.text.trim();

    final alarm = widget.existingAlarm != null
        ? Alarm(
            id: widget.existingAlarm!.id,
            title: title,
            time: _selectedTime,
            isEnabled: widget.existingAlarm!.isEnabled,
            repeatDays: _repeatDays,
          )
        : Alarm(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: title,
            time: _selectedTime,
            repeatDays: _repeatDays,
          );

    widget.onSave(alarm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingAlarm == null ? 'Nueva alarma' : 'Editar alarma'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: Text(
              'Guardar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título de la alarma',
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 32),
            Card(
              child: ListTile(
                title: Text('Hora', style: TextStyle(fontSize: 18)),
                subtitle: Text(
                  DateFormat('HH:mm').format(_selectedTime),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(Icons.access_time, size: 40),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedTime),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedTime = DateTime(
                        _selectedTime.year,
                        _selectedTime.month,
                        _selectedTime.day,
                        picked.hour,
                        picked.minute,
                      );
                      if (_selectedTime.isBefore(DateTime.now())) {
                        _selectedTime = _selectedTime.add(Duration(days: 1));
                      }
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text('Repetir', style: TextStyle(fontSize: 18)),
                subtitle: Text(_repeatText(), style: TextStyle(fontSize: 18)),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final result = await Navigator.push<List<int>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RepeatSelectionScreen(initialDays: _repeatDays),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _repeatDays = result;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAlarm,
        icon: Icon(Icons.check),
        label: Text('Guardar alarma'),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}