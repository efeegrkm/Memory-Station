import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Yeni Turkuaz & Yeşil & Pastel Tonlar
  static const Color background = Color(0xFFF0F7F4); // Çok açık nane yeşili
  static const Color surface = Color(0xFFFFFFFF);
  
  static const Color primary = Color(0xFF26A69A); // Turkuaz
  static const Color primaryDark = Color(0xFF00796B); // Koyu Turkuaz
  static const Color accent = Color(0xFFA5D6A7); // Pastel Yeşil
  
  static const Color textMain = Color(0xFF263238); // Koyu Gri/Mavi
  static const Color textLight = Color(0xFF78909C);
  
  static const Color timelineLine = Color(0xFF80CBC4); // Çizgi rengi
  static const Color purpleHeart = Color(0xFF9C27B0); // Timeline'daki Mor Kalp
}

class AppTheme {
  // DÜZELTME: Gradyan tanımı buraya, AppTheme sınıfının içine taşındı.
  static const BoxDecoration mainGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE0F2F1), // Açık Turkuaz
        Color(0xFFE8F5E9), // Açık Yeşil
      ],
    ),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.accent,
      ),
      textTheme: GoogleFonts.quicksandTextTheme().apply(
        bodyColor: AppColors.textMain,
        displayColor: AppColors.textMain,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textMain),
      ),
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

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.15),
      offset: const Offset(4, 4),
      blurRadius: 15,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.8),
      offset: const Offset(-4, -4),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];
}