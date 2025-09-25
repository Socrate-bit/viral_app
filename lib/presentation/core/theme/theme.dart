import 'package:flutter/material.dart';
import 'colors.dart';
import 'app_font.dart';

class AppTheme {
  // ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundColor,
      cardColor: AppColors.cardBackground,
      colorScheme: AppColors.darkColorScheme,
      textTheme: AppFont.textTheme,
    );
  }

  // TextTheme (loaded from AppFont)
  static TextTheme get textTheme => AppFont.textTheme;

  // Custom element theme (add as needed)
}
