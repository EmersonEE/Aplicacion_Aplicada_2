import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ManualFeedScreen extends StatefulWidget {
  @override
  _ManualFeedScreenState createState() => _ManualFeedScreenState();
}

class _ManualFeedScreenState extends State<ManualFeedScreen> {
  int _selectedGrams = 40; // valor por defecto

  final List<int> gramOptions = [20, 40, 60];

  final DatabaseReference _historyRef =
      FirebaseDatabase.instance.ref().child('feed_history');

  Future<void> _dispenseFood() async {
    // Subir evento a Firebase
    try {
      await _historyRef.push().set({
        'grams': _selectedGrams,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'manual',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Dispensando $_selectedGrams g de alimento ahora!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar alimentación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alimentar ahora'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, size: 100, color: Colors.blue),
              SizedBox(height: 32),
              Text(
                'Dispensar comida manualmente',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Text('Cantidad:', style: TextStyle(fontSize: 20)),
              SizedBox(height: 16),
              Wrap(
                spacing: 16,
                children: gramOptions.map((grams) {
                  return ChoiceChip(
                    label: Text('$grams g', style: TextStyle(fontSize: 18)),
                    selected: _selectedGrams == grams,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedGrams = grams;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: _dispenseFood,
                icon: Icon(Icons.restaurant, size: 40),
                label: Text(
                  'Dispensar $_selectedGrams g',
                  style: TextStyle(fontSize: 24),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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