import 'package:alarmapp/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // ← ESTE ES EL IMPORT CLAVE PARA ChangeNotifierProvider
import 'services/notification_service.dart';
import 'screens/main_screen.dart';
import 'providers/menu_provider.dart';  // ← Import para MenuProvider
import 'firebase_options.dart'; // ← este archivo ya lo tienes
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  await analytics.logEvent(name: "Prueba", parameters: {'timestamp': DateTime.now().toIso8601String()});
  tz.initializeTimeZones();
  final guatemalaLocation = tz.getLocation('America/Guatemala');
  tz.setLocalLocation(guatemalaLocation);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MenuProvider(),
      child: MaterialApp(
        title: 'Mi App de Alarmas',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: MainScreen(),
      ),
    );
  }
}