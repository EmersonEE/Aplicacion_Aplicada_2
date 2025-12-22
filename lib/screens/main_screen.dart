import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../models/menu_info.dart';
import '../services/notification_service.dart';
import '../screens/manual_feed_screen.dart';
import '../screens/manual_water_screen.dart';
import 'alarm_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<MenuInfo> menuItems = [
    MenuInfo(MenuType.food, title: 'Comida', icon: Icons.restaurant),
    MenuInfo(MenuType.water, title: 'Agua', icon: Icons.water_drop),
    MenuInfo(MenuType.alarm, title: 'Alarmas', icon: Icons.alarm),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        final currentMenu = menuProvider.currentMenu;

        return Scaffold(
          body: currentMenu == MenuType.food
              ? ManualFeedScreen()
              : currentMenu == MenuType.water
                  ? ManualWaterScreen()  // ← Ahora sí muestra la pantalla de agua
                  : AlarmScreen(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentMenu == MenuType.food
                ? 0
                : currentMenu == MenuType.water
                    ? 1
                    : 2,
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