import 'package:firebase_database/firebase_database.dart';
import '../models/alarm.dart';

class FirebaseAlarmService {
  static final DatabaseReference db = FirebaseDatabase.instance.ref().child('alarms');

  // Añadir alarma (Firebase genera la clave)
  static Future<String> addAlarm(Alarm alarm) async {
    final ref = db.push();
    await ref.set(alarm.toJson());
    return ref.key!;
  }

  // Actualizar alarma
  static Future<void> updateAlarm(String key, Alarm alarm) async {
    await db.child(key).update(alarm.toJson());
  }

  // Eliminar alarma
  static Future<void> deleteAlarm(String key) async {
    await db.child(key).remove();
  }

  // Cargar todas
  static Future<List<Alarm>> loadAlarmsFromFirebase() async {
    final snapshot = await db.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final List<Alarm> alarms = [];

    data.forEach((key, value) {
      final json = Map<String, dynamic>.from(value);
      final alarm = Alarm.fromJson(json);
      alarm.key = key.toString();
      alarms.add(alarm);
    });

    return alarms..sort((a, b) => a.time.compareTo(b.time));
  }

  // Stream en tiempo real
  static Stream<List<Alarm>> get alarmsStream {
    return db.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return <Alarm>[];

      final List<Alarm> alarms = [];
      data.forEach((key, value) {
        final json = Map<String, dynamic>.from(value);
        final alarm = Alarm.fromJson(json);
        alarm.key = key.toString();
        alarms.add(alarm);
      });

      return alarms..sort((a, b) => a.time.compareTo(b.time));
    });
  }
}