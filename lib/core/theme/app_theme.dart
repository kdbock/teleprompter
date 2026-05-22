import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF64B5F6);
  
  // Prompter Colors
  static const Color prompterBackground = Colors.black;
  static const Color prompterText = Colors.white;
  static const Color prompterHighlight = Color(0xFF4CAF50);
  
  // Role Colors
  static const Color publisherColor = Color(0xFF9C27B0); // Purple
  static const Color editorColor = Color(0xFF2196F3); // Blue
  static const Color creatorColor = Color(0xFFFF9800); // Orange
  
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
  
  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
  
  // Prompter Theme (for teleprompter screen)
  static TextStyle prompterTextStyle({double fontSize = 32.0}) {
    return GoogleFonts.roboto(
      fontSize: fontSize,
      color: prompterText,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );
  }
}
