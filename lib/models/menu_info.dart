import 'package:flutter/material.dart';

enum MenuType { food, water, alarm }

class MenuInfo {
  final MenuType menuType;
  final String title;
  final IconData icon;

  MenuInfo(this.menuType, {required this.title, required this.icon});
}