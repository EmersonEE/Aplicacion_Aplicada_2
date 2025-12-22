import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

class AlarmStorage {
  static const String _key = 'alarms_data';

  static Future<void> saveAlarms(List<Alarm> alarms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {};
      for (var alarm in alarms) {
        final localKey = alarm.key ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
        data[localKey] = alarm.toJson();
      }
      await prefs.setString(_key, jsonEncode(data));
    } catch (e) {
      print('Error guardando alarmas localmente: $e');
    }
  }

  static Future<List<Alarm>> loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) return [];

      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<Alarm> alarms = [];

      data.forEach((key, value) {
        final json = Map<String, dynamic>.from(value);
        final alarm = Alarm.fromJson(json);
        alarm.key = key;
        alarms.add(alarm);
      });

      return alarms..sort((a, b) => a.time.compareTo(b.time));
    } catch (e) {
      print('Error cargando alarmas desde local: $e');
      return [];
    }
  }
}