import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // ← NECESARIO para Consumer y Provider.of
import '../providers/menu_provider.dart';
import '../models/menu_info.dart';
import '../services/notification_service.dart';  // ← Para requestPermissions
import 'clock_screen.dart';
import 'alarm_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<MenuInfo> menuItems = [
    MenuInfo(MenuType.clock, title: 'Reloj', icon: Icons.timelapse),
    MenuInfo(MenuType.alarm, title: 'Alarmas', icon: Icons.alarm),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();  // Pide permisos al inicio
    });
  }

@override
Widget build(BuildContext context) {
  return Consumer<MenuProvider>(
    builder: (context, menuProvider, child) {
      final currentMenu = menuProvider.currentMenu;

      return Scaffold(
        body: currentMenu == MenuType.clock ? ClockScreen() : AlarmScreen(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentMenu == MenuType.clock ? 0 : 1,
          onTap: (index) {
            final selectedMenu = menuItems[index];
            menuProvider.updateMenu(selectedMenu);
          },
          items: menuItems.map((item) => BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.title,
          )).toList(),
        ),
      );
    },
  );
  }
}