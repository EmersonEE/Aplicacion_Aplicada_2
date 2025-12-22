import 'package:flutter/material.dart';
import '../models/menu_info.dart';

class MenuProvider extends ChangeNotifier {
  MenuType _currentMenu = MenuType.food;  // Pestaña inicial: Comida
  MenuInfo _currentMenuInfo = MenuInfo(
    MenuType.food,
    title: 'Comida',
    icon: Icons.restaurant,
  );

  MenuType get currentMenu => _currentMenu;
  MenuInfo get currentMenuInfo => _currentMenuInfo;

  void updateMenu(MenuInfo menuInfo) {
    _currentMenu = menuInfo.menuType;
    _currentMenuInfo = menuInfo;
    notifyListeners();
  }
}