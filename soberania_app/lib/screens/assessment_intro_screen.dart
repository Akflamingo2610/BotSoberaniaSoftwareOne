import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../l10n/app_localizations.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import '../widgets/chat_panel.dart';
import 'login_screen.dart';
import 'phases_screen.dart';

class AssessmentIntroScreen extends StatefulWidget {
  const AssessmentIntroScreen({super.key});

  @override
  State<AssessmentIntroScreen> createState() => _AssessmentIntroScreenState();
}

class _AssessmentIntroScreenState extends State<AssessmentIntroScreen> {
  String? _quickQuestion;
  int _quickQuestionNonce = 0;

  static const Color _complianceColor = Color(0xFFF7675E);
  static const Color _continuityColor = Color(0xFF3366FF);
  static const Color _controlColor = Color(0xFFB0A7FF);

  Future<void> _continue(BuildContext context) async {
    // Salva flag de que já viu a introdução
    await AppStorage().setIntroSeen(true);
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const PhasesScreen()));
  }

  Future<void> _logout(BuildContext context) async {
    await AppStorage().clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(
        context,
        title: l10n.t('intro_page_title'),
        subtitle: l10n.t('intro_page_subtitle'),
        showBack: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Brand.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () => _continue(context),
                child: Text(
                  l10n.t('btn_start_assessment').toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, size: 18, color: Brand.black),
              label: Text(
                l10n.t('btn_logout'),
                style: const TextStyle(color: Brand.black),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/pedrasluzjpg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Brand.surface),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1100;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ContentColumn(
                          onContinue: () => _continue(context),
                          onLogout: () => _logout(context),
                        ),
                      ),
                      SizedBox(
                        width: 420,
                        child: ChatPanel(
                          welcomeMessage: l10n.t('intro_chat_welcome'),
                        ),
                      ),
                    ],
                  );
                }
                return _ContentColumn(
                  onContinue: () => _continue(context),
                  onLogout: () => _logout(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onKeywordTap(String conceptKey) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    String question;
    switch (lang) {
      case 'en':
        if (conceptKey == 'compliance') {
          question = 'What does Compliance mean in digital sovereignty, in simple terms?';
        } else if (conceptKey == 'control') {
          question = 'What does Control mean in digital sovereignty, in simple terms?';
        } else {
          question = 'What does Continuity mean in digital sovereignty, in simple terms?';
        }
        break;
      case 'es':
        if (conceptKey == 'compliance') {
          question = '¿Qué significa Compliance en soberanía digital, de forma simple?';
        } else if (conceptKey == 'control') {
          question = '¿Qué significa Control en soberanía digital, de forma simple?';
        } else {
          question = '¿Qué significa Continuity en soberanía digital, de forma simple?';
        }
        break;
      default:
        if (conceptKey == 'compliance') {
          question = 'O que significa Compliance em soberania digital, de forma simples?';
        } else if (conceptKey == 'control') {
          question = 'O que significa Control em soberania digital, de forma simples?';
        } else {
          question = 'O que significa Continuity em soberania digital, de forma simples?';
        }
    }

    setState(() {
      _quickQuestion = question;
      _quickQuestionNonce++;
    });
  }

  static Widget _bulletList(
    BuildContext context,
    List<String> items, {
    ValueChanged<String>? onKeywordTap,
  }) {
    final visibleItems = items.where((e) => e.trim().isNotEmpty).toList();
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.black87, height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: visibleItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: style?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Expanded(
                    child: highlightedText(
                      context,
                      item,
                      style: style,
                      onKeywordTap: onKeywordTap,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  static Widget highlightedText(
    BuildContext context,
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
    ValueChanged<String>? onKeywordTap,
  }) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: _buildHighlightedSpans(text, baseStyle, onKeywordTap),
      ),
      textAlign: textAlign ?? TextAlign.justify,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  static List<InlineSpan> _buildHighlightedSpans(
    String text,
    TextStyle baseStyle,
    ValueChanged<String>? onKeywordTap,
  ) {
    final spans = <InlineSpan>[];
    final regex = RegExp(
      r'\b(compliance|conformidade|conformidad|cumplimiento|continuity|continuidade|continuidad|control|controle)\b',
      caseSensitive: false,
    );
    var lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      final token = text.substring(match.start, match.end);
      final normalized = token.toLowerCase();
      Color color = baseStyle.color ?? Brand.black;
      String? conceptKey;
      if (normalized == 'compliance' ||
          normalized == 'conformidade' ||
          normalized == 'conformidad' ||
          normalized == 'cumplimiento') {
        color = _complianceColor;
        conceptKey = 'compliance';
      } else if (normalized == 'continuity' ||
          normalized == 'continuidade' ||
          normalized == 'continuidad') {
        color = _continuityColor;
        conceptKey = 'continuity';
      } else if (normalized == 'control' || normalized == 'controle') {
        color = _controlColor;
        conceptKey = 'control';
      }
      spans.add(
        TextSpan(
          text: token,
          style: baseStyle.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            decoration: conceptKey == null || onKeywordTap == null
                ? TextDecoration.none
                : TextDecoration.underline,
            decorationColor: color,
          ),
          recognizer: conceptKey == null || onKeywordTap == null
              ? null
              : (TapGestureRecognizer()..onTap = () => onKeywordTap(conceptKey!)),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }
}

class _ContentColumn extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onLogout;
  final ValueChanged<String>? onKeywordTap;

  const _ContentColumn({
    required this.onContinue,
    required this.onLogout,
    this.onKeywordTap,
  });

  @override
  State<_ContentColumn> createState() => _ContentColumnState();
}

class _ContentColumnState extends State<_ContentColumn> {
  String _keywordHint(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('en')) {
      return 'Tip: click on Compliance, Control, or Continuity to get a quick explanation in the chat.';
    }
    if (code.startsWith('es')) {
      return 'Consejo: haga clic en Compliance, Control o Continuity para obtener una explicación rápida en el chat.';
    }
    return 'Dica: clique em Compliance, Control ou Continuity para ver uma explicação rápida no chat.';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w900,
      color: Brand.black,
      letterSpacing: -0.3,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Brand.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Brand.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final imageHeight = constraints.maxWidth < 700 ? 190.0 : 240.0;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: imageHeight,
                            width: double.infinity,
                            child: Image.asset(
                              'assets/images/GettyImages-1286804873.jpg.jpeg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.t('intro_page_title'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF4169E1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AssessmentIntroScreenState.highlightedText(
                      context,
                      l10n.t('intro_assessment_card_title'),
                      style: titleStyle,
                      onKeywordTap: widget.onKeywordTap,
                    ),
                    const SizedBox(height: 12),
                    _AssessmentIntroScreenState.highlightedText(
                      context,
                      l10n.t('intro_assessment_card_body'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black87,
                        height: 1.6,
                      ),
                      onKeywordTap: widget.onKeywordTap,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _AssessmentIntroScreenState.highlightedText(
                  context,
                  l10n.t('intro_framework_title'),
                  style: titleStyle,
                  onKeywordTap: widget.onKeywordTap,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _AssessmentIntroScreenState.highlightedText(
                  context,
                  l10n.t('intro_framework_intro'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                    height: 1.55,
                  ),
                  onKeywordTap: widget.onKeywordTap,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD6E3FF)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.touch_app, size: 16, color: Color(0xFF4169E1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _keywordHint(context),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF2C4A9A),
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _AssessmentIntroScreenState._bulletList(context, [
                  l10n.t('intro_framework_bullet_1'),
                  l10n.t('intro_framework_bullet_2'),
                  l10n.t('intro_framework_bullet_3'),
                ], onKeywordTap: widget.onKeywordTap),
              ),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 820;
                  final itemWidth = isNarrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 32) / 3;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _PillarCard(
                          title: l10n.t('intro_compliance_title'),
                          imagePath:
                              'assets/images/GettyImages-1207090508.jpg.jpeg',
                          bullets: [
                            l10n.t('intro_compliance_bullet_1'),
                            l10n.t('intro_compliance_bullet_2'),
                          ],
                          onKeywordTap: widget.onKeywordTap,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PillarCard(
                          title: l10n.t('intro_control_title'),
                          imagePath:
                              'assets/images/GettyImages-1223115939.jpg.jpeg',
                          bullets: [
                            l10n.t('intro_control_bullet_1'),
                            l10n.t('intro_control_bullet_2'),
                          ],
                          onKeywordTap: widget.onKeywordTap,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PillarCard(
                          title: l10n.t('intro_continuity_title'),
                          imagePath:
                              'assets/images/GettyImages-1254270100.jpg.jpeg',
                          bullets: [
                            l10n.t('intro_continuity_bullet_1'),
                            l10n.t('intro_continuity_bullet_2'),
                          ],
                          onKeywordTap: widget.onKeywordTap,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              _SectionCard(
                title: l10n.t('intro_partnership_title'),
                body: l10n.t('intro_partnership_body'),
                imagePath: 'assets/images/GettyImages-1254770264.jpg.jpeg',
                onKeywordTap: widget.onKeywordTap,
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.t('intro_about_card_title'),
                body: l10n.t('intro_about_card_body'),
                imagePath: 'assets/images/GettyImages-1293443512.jpg.jpeg',
                onKeywordTap: widget.onKeywordTap,
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.t('intro_sov_title'),
                body: l10n.t('intro_sov_body'),
                imagePath: 'assets/images/GettyImages-1255349939.jpg.jpeg',
                onKeywordTap: widget.onKeywordTap,
              ),
              const SizedBox(height: 20),

              _SectionCard(
                title: l10n.t('intro_assessment_card_title'),
                body: l10n.t('intro_assessment_card_body'),
                imagePath: 'assets/images/GettyImages-1316015053.jpg.jpeg',
                onKeywordTap: widget.onKeywordTap,
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final String title;
  final List<String> bullets;
  final String? imagePath;
  final ValueChanged<String>? onKeywordTap;

  const _PillarCard({
    required this.title,
    required this.bullets,
    this.imagePath,
    this.onKeywordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(imagePath!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _AssessmentIntroScreenState.highlightedText(
            context,
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Brand.black,
            ),
            onKeywordTap: onKeywordTap,
          ),
          const SizedBox(height: 8),
          _AssessmentIntroScreenState._bulletList(
            context,
            bullets,
            onKeywordTap: onKeywordTap,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String body;
  final String? imagePath;
  final ValueChanged<String>? onKeywordTap;

  const _SectionCard({
    required this.title,
    required this.body,
    this.imagePath,
    this.onKeywordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brand.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasImage = imagePath != null;
          final isWide = hasImage && constraints.maxWidth >= 840;
          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AssessmentIntroScreenState.highlightedText(
                context,
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Brand.black,
                  letterSpacing: -0.2,
                ),
                onKeywordTap: onKeywordTap,
              ),
              const SizedBox(height: 12),
              _AssessmentIntroScreenState.highlightedText(
                context,
                body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
                  height: 1.6,
                ),
                onKeywordTap: onKeywordTap,
              ),
            ],
          );

          if (!hasImage) {
            return Padding(
              padding: const EdgeInsets.all(14),
              child: textContent,
            );
          }

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(imagePath!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(padding: const EdgeInsets.all(14), child: textContent),
              ],
            );
          }

          final imageWidth = (constraints.maxWidth * 0.42).clamp(280.0, 360.0);
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: textContent,
                  ),
                ),
                SizedBox(
                  width: imageWidth,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox.expand(
                      child: Image.asset(
                        imagePath!,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
