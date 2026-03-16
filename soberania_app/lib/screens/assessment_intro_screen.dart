import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import '../widgets/chat_panel.dart';
import 'login_screen.dart';
import 'phases_screen.dart';

class AssessmentIntroScreen extends StatelessWidget {
  const AssessmentIntroScreen({super.key});

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
      body: SafeArea(
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
    );
  }

  static Widget _bulletList(BuildContext context, List<String> items) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.black87, height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items
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
                  Expanded(child: Text(item, style: style)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ContentColumn extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onLogout;

  const _ContentColumn({required this.onContinue, required this.onLogout});

  @override
  State<_ContentColumn> createState() => _ContentColumnState();
}

class _ContentColumnState extends State<_ContentColumn> {
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 21 / 9,
                        child: Image.asset(
                          'assets/images/GettyImages-1286804873.jpg.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
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
                    Text(
                      l10n.t('intro_assessment_card_title'),
                      style: titleStyle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.t('intro_assessment_card_body'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text(l10n.t('intro_framework_title'), style: titleStyle),
              const SizedBox(height: 16),
              AssessmentIntroScreen._bulletList(context, [
                l10n.t('intro_framework_bullet_1'),
                l10n.t('intro_framework_bullet_2'),
                l10n.t('intro_framework_bullet_3'),
              ]),
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
                          icon: Icons.rule_folder_outlined,
                          title: l10n.t('intro_compliance_title'),
                          imagePath:
                              'assets/images/GettyImages-1207090508.jpg.jpeg',
                          bullets: [
                            l10n.t('intro_compliance_bullet_1'),
                            l10n.t('intro_compliance_bullet_2'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PillarCard(
                          icon: Icons.shield_outlined,
                          title: l10n.t('intro_control_title'),
                          imagePath:
                              'assets/images/GettyImages-1223115939.jpg.jpeg',
                          bullets: [
                            l10n.t('intro_control_bullet_1'),
                            l10n.t('intro_control_bullet_2'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PillarCard(
                          icon: Icons.autorenew_outlined,
                          title: l10n.t('intro_continuity_title'),
                          imagePath:
                              'assets/images/GettyImages-1254270100.jpg.jpeg',
                          bullets: [
                            l10n.t('intro_continuity_bullet_1'),
                            l10n.t('intro_continuity_bullet_2'),
                          ],
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
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.t('intro_about_card_title'),
                body: l10n.t('intro_about_card_body'),
                imagePath: 'assets/images/GettyImages-1293443512.jpg.jpeg',
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.t('intro_sov_title'),
                body: l10n.t('intro_sov_body'),
                imagePath: 'assets/images/GettyImages-1255349939.jpg.jpeg',
              ),
              const SizedBox(height: 20),

              _SectionCard(
                title: l10n.t('intro_assessment_card_title'),
                body: l10n.t('intro_assessment_card_body'),
                imagePath: 'assets/images/GettyImages-1316015053.jpg.jpeg',
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
  final IconData icon;
  final String title;
  final List<String> bullets;
  final String? imagePath;

  const _PillarCard({
    required this.icon,
    required this.title,
    required this.bullets,
    this.imagePath,
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
          Icon(icon, size: 24, color: Brand.black),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Brand.black,
            ),
          ),
          const SizedBox(height: 8),
          AssessmentIntroScreen._bulletList(context, bullets),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String body;
  final String? imagePath;

  const _SectionCard({required this.title, required this.body, this.imagePath});

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
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Brand.black,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
                  height: 1.6,
                ),
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
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: textContent,
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: imageWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 240,
                    child: Image.asset(imagePath!, fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
