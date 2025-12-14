import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';

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
  late int _portions;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingAlarm?.title ?? 'Alarma');
    _selectedTime = widget.existingAlarm?.time ?? DateTime.now().add(Duration(hours: 1));
    _portions = widget.existingAlarm?.portions ?? 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveAlarm() {
    final title = _titleController.text.trim().isEmpty ? 'Alarma' : _titleController.text.trim();

    final alarm = widget.existingAlarm != null
        ? Alarm(
            id: widget.existingAlarm!.id,
            title: title,
            time: _selectedTime,
            isEnabled: widget.existingAlarm!.isEnabled,
            portions: _portions,  // ← AQUÍ ESTABA EL ERROR: faltaba pasar _portions
          )
        : Alarm(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: title,
            time: _selectedTime,
            portions: _portions,  // ← Aquí también
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
            child: Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                title: Text('Cantidad de alimento', style: TextStyle(fontSize: 18)),
                subtitle: Text('$_portions porción${_portions == 1 ? '' : 'es'}', style: TextStyle(fontSize: 24)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (_portions > 1) setState(() => _portions--);
                      },
                    ),
                    Text('$_portions', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: () {
                        if (_portions < 10) setState(() => _portions++);
                      },
                    ),
                  ],
                ),
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