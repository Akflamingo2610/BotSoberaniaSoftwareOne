import 'package:flutter/material.dart';

/// Escopo do idioma atual; permite que qualquer tela altere o locale.
class LocaleScope extends InheritedWidget {
  const LocaleScope({
    super.key,
    required this.locale,
    required this.setLocale,
    required super.child,
  });

  final Locale locale;
  final Future<void> Function(String localeCode) setLocale;

  static LocaleScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleScope>();
  }

  @override
  bool updateShouldNotify(LocaleScope old) => locale != old.locale;
}
