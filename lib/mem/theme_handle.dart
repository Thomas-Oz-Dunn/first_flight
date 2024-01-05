import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const THEME_KEY = "theme_key";
const LOCATION_KEY = "LocationFidelity";

class MyPreferences {

  void setTheme(bool value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(THEME_KEY, value);
  }

  Future<bool> getTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(THEME_KEY) ?? false;
  }
}

class ModelThemeProvider extends ChangeNotifier {
  late bool _isDark;
  late MyPreferences _preferences;

  bool get isDark => _isDark;

  ModelThemeProvider() {
    _isDark = false;
    _preferences = MyPreferences();
    getPreferences();
  }

  // Switching the themes
  set isDark(bool value) {
    _isDark = value;
    _preferences.setTheme(value);
    notifyListeners();
  }

  getPreferences() async {
    _isDark = await _preferences.getTheme();
    notifyListeners();
  }
}
