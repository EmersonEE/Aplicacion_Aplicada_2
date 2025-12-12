import 'package:firebase_database/firebase_database.dart';
import '../models/alarm.dart';

class FirebaseAlarmService {
  // Referencia pública
  static final DatabaseReference db =
      FirebaseDatabase.instance.ref().child('alarms');

  // Sube todas las alarmas a Firebase
  static Future<void> uploadAlarms(List<Alarm> alarms) async {
    try {
      final Map<String, dynamic> data = {
        for (var alarm in alarms) alarm.id.toString(): alarm.toJson()
      };
      await db.set(data);
    } catch (e) {
      print('Error subiendo alarmas a Firebase: $e');
    }
  }

  // Stream para escuchar cambios en tiempo real
  static Stream<List<Alarm>> get alarmsStream {
    return db.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return <Alarm>[];

      return data.entries.map((entry) {
        final json = Map<String, dynamic>.from(entry.value);
        return Alarm.fromJson(json);
      }).toList()
        ..sort((a, b) => a.time.compareTo(b.time));
    });
  }

  // Opcional: borrar todo
  static Future<void> clearAll() async => await db.remove();
}