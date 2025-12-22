import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManualWaterScreen extends StatefulWidget {
  @override
  _ManualWaterScreenState createState() => _ManualWaterScreenState();
}

class _ManualWaterScreenState extends State<ManualWaterScreen> {
  int _selectedMl = 200; // valor por defecto

  final List<int> mlOptions = [100, 200, 300];

  final DatabaseReference _waterRef = FirebaseDatabase.instance.ref().child(
    'manual_water',
  );

  Future<void> _dispenseWater() async {
    try {
      await _waterRef.child('ml').set(_selectedMl); // ← int puro

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Dispensando $_selectedMl ml de agua!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dispensar agua')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop, size: 120, color: Colors.blue),
              SizedBox(height: 40),
              Text(
                'Dispensar agua manualmente',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 50),
              Text('Cantidad:', style: TextStyle(fontSize: 22)),
              SizedBox(height: 20),
              Wrap(
                spacing: 16,
                children: mlOptions.map((ml) {
                  return ChoiceChip(
                    label: Text('$ml ml', style: TextStyle(fontSize: 20)),
                    selected: _selectedMl == ml,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedMl = ml;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 80),
              ElevatedButton.icon(
                onPressed: _dispenseWater,
                icon: Icon(Icons.local_drink, size: 50),
                label: Text(
                  'Dispensar $_selectedMl ml',
                  style: TextStyle(fontSize: 28),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 25),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
