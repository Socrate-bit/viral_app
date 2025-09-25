import 'package:flutter/material.dart';
import 'colors.dart';

class AppFont {
  // Police (Font Family)
  static const String fontFamily = 'SF Pro Display'; // Default iOS font

  // FontSize
  static const double fontSizeXSmall = 12.0;
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 24.0;
  static const double fontSizeXXLarge = 32.0;

  // Weighted (Font Weight)
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // Colors (Text Colors)
  static const Color primaryTextColor = AppColors.primaryText;
  static const Color secondaryTextColor = AppColors.secondaryText;
  static const Color tertiaryTextColor = AppColors.tertiaryText;

  // TextTheme
  static TextTheme get textTheme => TextTheme(
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      color: primaryTextColor,
      fontSize: fontSizeMedium,
      fontWeight: weightRegular,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      color: primaryTextColor,
      fontSize: fontSizeSmall,
      fontWeight: weightRegular,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      color: secondaryTextColor,
      fontSize: fontSizeXSmall,
      fontWeight: weightRegular,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      color: primaryTextColor,
      fontSize: fontSizeXLarge,
      fontWeight: weightBold,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      color: primaryTextColor,
      fontSize: fontSizeLarge,
      fontWeight: weightSemiBold,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      color: primaryTextColor,
      fontSize: fontSizeMedium,
      fontWeight: weightMedium,
    ),
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      color: primaryTextColor,
      fontSize: fontSizeXXLarge,
      fontWeight: weightBold,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      color: primaryTextColor,
      fontSize: fontSizeXLarge,
      fontWeight: weightSemiBold,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      color: primaryTextColor,
      fontSize: fontSizeSmall,
      fontWeight: weightMedium,
    ),
  );
}
