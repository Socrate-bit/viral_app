import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryBlack = Color(0xFF000000);
  static const Color techWhite = Color(0xFFFAFAFA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  
  // Grey shades
  static const Color darkGrey = Color(0xFF1A1A1A);
  static const Color mediumGrey = Color(0xFF333333);
  static const Color lightGrey = Color(0xFF666666);
  static const Color veryLightGrey = Color(0xFF999999);
  
  // Accent colors
  static const Color gradientOrange = Color(0xFFFF9500);
  static const Color gradientRed = Color(0xFFFF3B30);
  
  // Background colors
  static const Color backgroundColor = primaryBlack;
  static const Color cardBackground = darkGrey;
  static const Color surfaceColor = mediumGrey;
  
  // Text colors
  static const Color primaryText = techWhite;
  static const Color secondaryText = lightGrey;
  static const Color tertiaryText = veryLightGrey;
  
  // Icon colors
  static const Color activeIcon = techWhite;
  static const Color inactiveIcon = lightGrey;
  
  // Shadow
  static const Color shadow = Color(0x40000000);
  
  // Gradients
  static const LinearGradient studioButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientOrange, gradientRed],
  );

  // ColorScheme
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    background: backgroundColor,
    surface: cardBackground,
    primary: gradientOrange,
    secondary: gradientRed,
    onBackground: primaryText,
    onSurface: primaryText,
    onPrimary: pureWhite,
    onSecondary: pureWhite,
  );
}
