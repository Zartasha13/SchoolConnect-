import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1746A2);
  static const Color lightGreen = Color(0xFF8BE3B3);

  // static ThemeData lightTheme ki jagah getter use kiya hai
  static ThemeData get lightTheme => ThemeData(
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Roboto',
    primaryColor: primaryBlue,

    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      elevation: 0,
      centerTitle: true,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primaryBlue,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
    ),
  );
}
