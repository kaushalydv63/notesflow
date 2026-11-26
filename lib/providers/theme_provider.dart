import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const String _darkModeKey = 'is_dark_mode';
  final ValueNotifier<bool> isDarkNotifier = ValueNotifier<bool>(false);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkNotifier.value = prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> toggleTheme() async {
    final next = !isDarkNotifier.value;
    isDarkNotifier.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, next);
  }
}