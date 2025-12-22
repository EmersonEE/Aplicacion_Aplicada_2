import 'package:flutter/material.dart';

class RepeatSelectionScreen extends StatefulWidget {
  final Map<String, bool> initialDays;

  const RepeatSelectionScreen({Key? key, required this.initialDays}) : super(key: key);

  @override
  _RepeatSelectionScreenState createState() => _RepeatSelectionScreenState();
}

class _RepeatSelectionScreenState extends State<RepeatSelectionScreen> {
  late Map<String, bool> selectedDays;

  final List<String> dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  final List<String> dayKeys = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  @override
  void initState() {
    super.initState();
    selectedDays = Map.from(widget.initialDays);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Repetir'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, selectedDays),
            child: Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Ninguna'),
            onTap: () => Navigator.pop(context, {
              "sun": false, "mon": false, "tue": false, "wed": false, "thu": false, "fri": false, "sat": false
            }),
          ),
          ListTile(
            title: Text('Diaria'),
            onTap: () => Navigator.pop(context, {
              "sun": true, "mon": true, "tue": true, "wed": true, "thu": true, "fri": true, "sat": true
            }),
          ),
          ListTile(
            title: Text('Lunes a viernes'),
            onTap: () => Navigator.pop(context, {
              "sun": false, "mon": true, "tue": true, "wed": true, "thu": true, "fri": true, "sat": false
            }),
          ),
          ListTile(
            title: Text('Fines de semana'),
            onTap: () => Navigator.pop(context, {
              "sun": true, "mon": false, "tue": false, "wed": false, "thu": false, "fri": false, "sat": true
            }),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Días específicos', style: Theme.of(context).textTheme.titleMedium),
          ),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final key = dayKeys[index];
              return ChoiceChip(
                label: Text(dayNames[index]),
                selected: selectedDays[key] ?? false,
                onSelected: (selected) {
                  setState(() {
                    selectedDays[key] = selected;
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}