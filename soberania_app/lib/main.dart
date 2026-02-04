import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'ui/brand.dart';

void main() {
  runApp(const SoberaniaApp());
}

class SoberaniaApp extends StatelessWidget {
  const SoberaniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Brand.black),
      scaffoldBackgroundColor: Brand.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Brand.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return MaterialApp(
      title: 'Soberania Digital',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      home: const WelcomeScreen(),
    );
  }
}
