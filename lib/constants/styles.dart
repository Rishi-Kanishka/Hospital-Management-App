import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyles {
  static TextStyle titleStyle = GoogleFonts.inter(
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 0,
    ),
  );
  static TextStyle subTextSecondary = GoogleFonts.inter(
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.42,
      height: 0,
    ),
  );

  static TextStyle buttonTextStyle = GoogleFonts.inter(
    textStyle: const TextStyle(
      color: Colors.black,
      fontSize: 17,
      fontWeight: FontWeight.w500,
      height: 0.08,
    ),
  );

  static TextStyle buttonTextSecondary = GoogleFonts.inter(
    textStyle: const TextStyle(
      color: Color(0xFFD7DDE4),
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.42,
      height: 0,
    ),
  );

  static const Color bg = Color(0xFF000000);
  static const Color buttonColor = Color(0xFF43D10A);
}
