import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFFDFBF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFFF9A9E);
  static const Color primaryDark = Color(0xFFE87C82);
  static const Color accent = Color(0xFFFECFEF);
  static const Color textMain = Color(0xFF5D4037);
  static const Color textLight = Color(0xFFA1887F);
  static const Color timelineLine = Color(0xFFFFD1D1);
  
  // Yeni Gradyan Renkleri
  static const Color gradientStart = Color(0xFFFAE3E3); // Hafif kırmızımsı
  static const Color gradientEnd = Color(0xFFFFFDF5);   // Krem
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.quicksandTextTheme().apply(
        bodyColor: AppColors.textMain,
        displayColor: AppColors.textMain,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      // Input dekorasyonları için varsayılan tema
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  // Yeni: Hafif kırmızı ışık saçan gölge
  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.25), // Kırmızımsı parlama
      offset: const Offset(5, 5),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.8),
      offset: const Offset(-5, -5),
      blurRadius: 15,
      spreadRadius: 1,
    ),
  ];
  
  // Arka plan gradyanı
  static BoxDecoration mainGradientDecoration = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFFFFE5E5), // Sağ üst (Kırmızımsı)
        Color(0xFFFFFBF0), // Sol alt (Krem)
      ],
    ),
  );
}