import 'package:flutter/material.dart';

Color customWhite = Colors.white;
Color customBlue = Colors.blue;
Color customRed = Colors.red;
Color customBlack = Colors.black;
Color customYellow = const Color(0xFFF8BB15);
Color customGrey = const Color(0xFF38454D);
Color customGreyLightbg = const Color(0x21616161);

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

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
