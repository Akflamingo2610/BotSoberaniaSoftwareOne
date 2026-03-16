import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_scope.dart';

/// Paleta minimalista baseada na marca (preto/branco).
class Brand {
  static const Color black = Color(0xFF0B0B0B);
  static const Color white = Colors.white;
  static const Color surface = Color(0xFFF6F6F6);
  static const Color border = Color(0xFFE6E6E6);

  /// Acentos inspirados na identidade da SoftwareOne
  /// (usados em gráficos e destaques, com moderação).
  static const Color accentRed = Color(0xFFE30613); // vermelho principal
  static const Color accentBlue = Color(0xFF4E79A7); // azul de suporte
  static const Color accentOrange = Color(0xFFF28E2B); // laranja para contraste
}

const String _awsLogoAsset = 'assets/images/Aws_logo_black.png';
const String _softwareOneLogoAsset = 'assets/images/logo_da_software.png';

/// Logo da AWS (à direita do header).
/// [size] define altura e largura da caixa para manter proporção igual ao SoftwareOne.
class AwsMark extends StatelessWidget {
  final double size;
  const AwsMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2,
      height: size,
      child: Image.asset(
        _awsLogoAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _AwsMarkFallback(height: size),
      ),
    );
  }
}

class _AwsMarkFallback extends StatelessWidget {
  final double height;
  const _AwsMarkFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Icon(Icons.cloud, size: height, color: Brand.black),
    );
  }
}

/// Logo SoftwareOne (apenas a imagem).
/// [size] define altura; largura proporcional para manter proporção igual à AWS.
class SoftwareOneMark extends StatelessWidget {
  final double size;
  const SoftwareOneMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2,
      height: size,
      child: Image.asset(
        _softwareOneLogoAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _SoftwareOneFallback(size: size),
      ),
    );
  }
}

class _SoftwareOneFallback extends StatelessWidget {
  final double size;
  const _SoftwareOneFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Brand.black,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '1',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Brand.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

PreferredSizeWidget soberaniaAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  Widget? leading,
  double? leadingWidth,
  Widget? trailing,
  bool showBack = true,
}) {
  return AppBar(
    backgroundColor: Brand.white,
    surfaceTintColor: Brand.white,
    elevation: 0,
    leading: leading,
    leadingWidth: leadingWidth,
    automaticallyImplyLeading: showBack && leading == null,
    titleSpacing: 16,
    title: Row(
      children: [
        Text(
          AppLocalizations.of(context).t('app_title'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Brand.black,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 1,
          height: 20,
          color: Brand.border,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: subtitle != null && subtitle.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Brand.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Brand.black.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Brand.black,
                  ),
                ),
        ),
        const SoftwareOneMark(size: 36),
        const SizedBox(width: 16),
        const AwsMark(size: 36),
      ],
    ),
    actions: [
      if (trailing != null) trailing,
      const LanguageButton(),
    ],
    iconTheme: const IconThemeData(color: Brand.black),
  );
}

/// Botão de idioma (PT/EN/ES) para o app bar; pode ser usado em qualquer tela.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = LocaleScope.of(context);
    if (scope == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<String>(
      tooltip: 'Idioma / Language',
      icon: const Icon(Icons.language, color: Brand.black),
      onSelected: (code) => scope.setLocale(code),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'pt', child: Text(l10n.t('lang_pt'))),
        PopupMenuItem(value: 'en', child: Text(l10n.t('lang_en'))),
        PopupMenuItem(value: 'es', child: Text(l10n.t('lang_es'))),
      ],
    );
  }
}
