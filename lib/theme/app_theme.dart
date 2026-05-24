import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFF0F7F4); 
  static const Color surface = Color(0xFFFFFFFF);
  
  static const Color primary = Color(0xFF26A69A); 
  static const Color primaryDark = Color(0xFF00796B); 
  static const Color accent = Color(0xFFA5D6A7); 
  
  static const Color textMain = Color(0xFF263238); 
  static const Color textLight = Color(0xFF78909C);
  
  static const Color timelineLine = Color(0xFF80CBC4); 
  static const Color purpleHeart = Color(0xFF9C27B0); 
}

class AppTheme {
  static const BoxDecoration mainGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE0F2F1), 
        Color(0xFFE8F5E9), 
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

// --- YENİ: Harita Türleri Katman Seçici (Madde 3) ---
class AppMapStyles {
  static const Map<String, String> styles = {
    'Standart (OSM)': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'Topoğrafik': 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    'Açık Tema (Carto)': 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    'Koyu Tema (Carto)': 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
  };
  
  // Uygulama genelinde kullanılacak aktif harita stili
  static String currentStyle = 'Standart (OSM)';
}