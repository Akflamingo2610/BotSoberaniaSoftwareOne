import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'l10n/locale_scope.dart';
import 'storage/app_storage.dart';
import 'screens/welcome_screen.dart';
import 'ui/brand.dart';

void main() {
  runApp(const SoberaniaApp());
}

class SoberaniaApp extends StatefulWidget {
  const SoberaniaApp({super.key});

  @override
  State<SoberaniaApp> createState() => _SoberaniaAppState();
}

class _SoberaniaAppState extends State<SoberaniaApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final code = await AppStorage().getLocale();
    if (mounted) setState(() => _locale = Locale(code));
  }

  Future<void> _setLocale(String code) async {
    await AppStorage().setLocale(code);
    if (mounted) setState(() => _locale = Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    final locale = _locale ?? const Locale('pt');
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

    return LocaleScope(
      locale: locale,
      setLocale: _setLocale,
      child: Builder(
        builder: (ctx) => MaterialApp(
          title: AppLocalizations.of(ctx).t('app_title'),
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: const [
          Locale('pt'),
          Locale('en'),
          Locale('es'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: base.copyWith(
          appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        ),
        home: const WelcomeScreen(),
        ),
      ),
    );
  }
}
