import 'package:flutter/material.dart';
import '../models/menu_info.dart';

class MenuProvider extends ChangeNotifier {
  MenuType _currentMenu = MenuType.clock;
  MenuInfo _currentMenuInfo = MenuInfo(MenuType.clock, title: 'Reloj', icon: Icons.timelapse);

  MenuType get currentMenu => _currentMenu;
  MenuInfo get currentMenuInfo => _currentMenuInfo;

  void updateMenu(MenuInfo menuInfo) {
    _currentMenu = menuInfo.menuType;
    _currentMenuInfo = menuInfo;
    notifyListeners();
  }
}