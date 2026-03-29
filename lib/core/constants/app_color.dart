import 'package:flutter/material.dart';

class AppColor {
  static final AppColor _instance = AppColor._internal();
  factory AppColor() => _instance;
  AppColor._internal();

  static const Color primary = Color(0xFF2C6A6D);
  static const Color primaryDark = Color(0xFF1F5055);
  static const Color primarySoft = Color(0xFFE3F0F1);
  static const Color brandWarm = Color(0xFFF4EA59);
  static const Color brandHighlight = Color(0xFFF8EF5A);

  static const Color backgroundColor = Colors.white;

  static const Color secondary = Colors.black;

  static const Color grey = Colors.grey;

  static const Color green = Color(0xFF2A7A63);

  static const Color scaffold = Colors.white;

  static const Color text = Color(0xFF143033);

  static const Color accent = Color(0xFFE1D94A);
  static const Color accentLight = Color(0xFFFCF9CF);

  static const Color alert = Color(0xFFC9453C);
  static const Color alertLight = Color(0xFFFDEDEA);

  static const Color warning = Color(0xFFC7923E);
  static const Color warningLight = Color(0xFFFAF1DE);

  static const Color info = Color(0xFF2D6BE0);
  static const Color infoLight = Color(0xFFEAF0FC);

  static const Color neutral1 = Color(0xFF839A9B);
  static const Color neutral2 = Color(0xFF5F7678);
  static const Color neutral3 = Color(0xFF355052);

  static const Color safe = Color(0xFFE9F1F1);
  static const Color safe1 = Color(0xFFF8FBFB);
  static const Color safe2 = Color(0xFFF5FAFA);
  static const Color safe3 = Color(0xFFF3F9F9);

  Color getColorFromName(String? colorName) {
    if (colorName == null) return Colors.transparent;

    switch (colorName.toLowerCase().trim()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      case 'multi':
        // Return a default color or handle logic for multi-color icons
        return Colors.blueGrey;
      default:
        return Colors.grey.shade300;
    }
  }
}
