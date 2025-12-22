import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import 'repeat_selection_screen.dart';

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
  late int _grams;
  late Map<String, bool> _repeatDays;

  final List<int> gramOptions = [20, 40, 60];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingAlarm?.title ?? 'Alarma');
    _selectedTime = widget.existingAlarm?.time ?? DateTime.now().add(Duration(hours: 1));
    _grams = widget.existingAlarm?.grams ?? 40;
    _repeatDays = Map.from(widget.existingAlarm?.repeatDays ?? {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _repeatText() {
    final active = _repeatDays.entries.where((e) => e.value).map((e) => e.key).toList();
    if (active.isEmpty) return 'Ninguna';
    if (active.length == 7) return 'Diaria';
    if (active.length == 5 && active.contains('mon') && active.contains('tue') && active.contains('wed') && active.contains('thu') && active.contains('fri')) return 'Lunes a viernes';
    if (active.length == 2 && active.contains('sat') && active.contains('sun')) return 'Fines de semana';

    const dayNames = {'sun': 'Dom', 'mon': 'Lun', 'tue': 'Mar', 'wed': 'Mié', 'thu': 'Jue', 'fri': 'Vie', 'sat': 'Sáb'};
    return active.map((d) => dayNames[d] ?? '').join(', ');
  }

  void _saveAlarm() {
    final title = _titleController.text.trim().isEmpty ? 'Alarma' : _titleController.text.trim();

    final alarm = widget.existingAlarm != null
        ? Alarm(
            key: widget.existingAlarm!.key,
            title: title,
            time: _selectedTime,
            isEnabled: widget.existingAlarm!.isEnabled,
            grams: _grams,
            repeatDays: _repeatDays,
          )
        : Alarm(
            title: title,
            time: _selectedTime,
            grams: _grams,
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
            child: Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(  // ← Para evitar overflow
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
                    final result = await Navigator.push<Map<String, bool>>(
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
              SizedBox(height: 16),
              Text('Cantidad de alimento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: gramOptions.map((grams) {
                  return ChoiceChip(
                    label: Text('$grams g'),
                    selected: _grams == grams,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _grams = grams;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
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