import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // ← ESTE ES EL IMPORT CLAVE PARA ChangeNotifierProvider
import 'services/notification_service.dart';
import 'screens/main_screen.dart';
import 'providers/menu_provider.dart';  // ← Import para MenuProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
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