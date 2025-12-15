import 'package:flutter/material.dart';

class RepeatSelectionScreen extends StatefulWidget {
  final List<int> initialDays;

  const RepeatSelectionScreen({Key? key, required this.initialDays}) : super(key: key);

  @override
  _RepeatSelectionScreenState createState() => _RepeatSelectionScreenState();
}

class _RepeatSelectionScreenState extends State<RepeatSelectionScreen> {
  late List<bool> selectedDays;

  final List<String> dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  @override
  void initState() {
    super.initState();
    selectedDays = List.filled(7, false);
    for (int day in widget.initialDays) {
      if (day >= 0 && day < 7) selectedDays[day] = true;
    }
  }

  void _saveAndPop() {
    List<int> result = [];
    for (int i = 0; i < 7; i++) {
      if (selectedDays[i]) result.add(i);
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Repetir'),
        actions: [
          TextButton(
            onPressed: _saveAndPop,  // ← Usa la función que siempre guarda
            child: Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Ninguna'),
            onTap: () => Navigator.pop(context, []),
          ),
          ListTile(
            title: Text('Diaria'),
            onTap: () => Navigator.pop(context, [0,1,2,3,4,5,6]),
          ),
          ListTile(
            title: Text('Lunes a viernes'),
            onTap: () => Navigator.pop(context, [1,2,3,4,5]),
          ),
          ListTile(
            title: Text('Fines de semana'),
            onTap: () => Navigator.pop(context, [0,6]),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Días específicos', style: Theme.of(context).textTheme.titleMedium),
          ),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              return ChoiceChip(
                label: Text(dayNames[index]),
                selected: selectedDays[index],
                onSelected: (selected) {
                  setState(() {
                    selectedDays[index] = selected;
                  });
                  // Opcional: guardar automáticamente al tocar un chip
                  // _saveAndPop();
                },
              );
            }),
          ),
          SizedBox(height: 80), // Espacio para el botón flotante si lo quieres
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveAndPop,  // ← Botón grande y visible para guardar manual
        child: Icon(Icons.check),
        tooltip: 'Guardar selección',
      ),
    );
  }
}