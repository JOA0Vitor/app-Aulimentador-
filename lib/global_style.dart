import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Color customWhite = Colors.white;
Color customBlue = Colors.blue;
Color customRed = Colors.red;
Color customBlack = Colors.black;
Color customYellow = const Color(0xFFF8BB15);
Color customGrey = const Color(0xFF38454D);
Color? customGreyLight = Colors.grey[100];

BorderSide customBorderSide = BorderSide(
  color: customBlack,
  width: 1.0,
);

OutlineInputBorder customOutlineInputBorder = OutlineInputBorder(
  borderSide: BorderSide(
    color: customWhite,
    width: 1.0,
  ),
);

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Color get buttonColor =>
      _isDarkMode ? Colors.grey[800]! : customGrey; // Cor do fundo do botão
  Color get buttonTextColor =>
      _isDarkMode ? customWhite : customYellow; // Cor do texto do botão

  void setTheme(bool isDarkMode) {
    _isDarkMode = isDarkMode;
    notifyListeners();
  }

  Future<void> saveThemePreference(bool isDarkTheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDarkTheme);
  }

  Future<bool> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkTheme') ?? false;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
