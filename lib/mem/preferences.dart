import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeKey = "theme_key";
const locationKey = "LocationFidelity";
const favoritesKey = "Favorites";
const historyKey = "History";
const viewingsKey = "Viewings";
const emailKey = "email";

class MyPreferences {

  void setTheme(bool value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(themeKey, value);
  }

  Future<bool> getTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(themeKey) ?? false;
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


Future<List<String>> getViewableOrbitIDs() async {
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

  List<String> viewable = [];
  List<String>? savedData = sharedPreferences.getStringList(favoritesKey);

  if (savedData != null) {
    viewable += savedData;
  }
  
  List<String>? viewData = sharedPreferences.getStringList(viewingsKey);
  if (viewData != null) {
    viewable += viewData;
  }

  return viewable;
}
