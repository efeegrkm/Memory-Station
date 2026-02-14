// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/timeline_screen.dart';
// Aşağıdaki satır, Web'de ve diğer platformlarda kimlik doğrulama ayarlarını getirir
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlatırken "hangi platformdayım?" diye sorup ona göre ayar çekiyoruz.
  // Bu satır o bembeyaz ekran hatasını çözer.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MemoryStationApp());
}

class MemoryStationApp extends StatelessWidget {
  const MemoryStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Station',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Türkçe Tarih Desteği
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      home: const TimelineScreen(),
    );
  }
}