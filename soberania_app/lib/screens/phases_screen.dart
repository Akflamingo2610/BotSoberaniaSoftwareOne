import 'package:flutter/material.dart';

import '../api/backend_api.dart';
import '../models/models.dart';
import '../storage/app_storage.dart';
import '../l10n/app_localizations.dart';
import '../ui/brand.dart';
import '../widgets/chat_panel.dart';
import 'assessment_intro_screen.dart';
import 'login_screen.dart';
import 'questions_screen.dart';
import 'results_screen.dart';

class PhasesScreen extends StatefulWidget {
  const PhasesScreen({super.key});

  @override
  State<PhasesScreen> createState() => _PhasesScreenState();
}

class _PhasesScreenState extends State<PhasesScreen> {
  DateTime? _lastResultsGeneratedAt;

  final _api = BackendApi();
  bool _allQuestionsAnswered = false;
  static const List<String> _phaseValuesForValidation = <String>[
    'Compliance',
    'Continuity',
    'Control',
  ];

  List<PhaseOption> _localizedPhases(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      PhaseOption(
        'Compliance',
        l10n.t('phase_compliance_label'),
        l10n.t('phase_compliance_subtitle'),
        descriptionKey: 'phase_compliance_card_body',
      ),
      PhaseOption(
        'Continuity',
        l10n.t('phase_continuity_label'),
        l10n.t('phase_continuity_subtitle'),
        descriptionKey: 'phase_continuity_card_body',
      ),
      PhaseOption(
        'Control',
        l10n.t('phase_control_label'),
        l10n.t('phase_control_subtitle'),
        descriptionKey: 'phase_control_card_body',
      ),
    ];
  }

  Future<void> _checkIfAllAnswered() async {
    try {
      final token = await AppStorage().getAuthToken();
      final assessmentId = await AppStorage().getAssessmentId();
      if (token == null || assessmentId == null) {
        if (mounted) setState(() => _allQuestionsAnswered = false);
        return;
      }

      var totalQuestions = 0;
      final answeredIds = <int>{};
      for (final phaseValue in _phaseValuesForValidation) {
        final raw = await _api.listQuestionsByPilar(
          authToken: token,
          pilar: phaseValue,
        );
        for (final e in raw) {
          if (e is Map && e['id'] != null) {
            totalQuestions++;
          }
        }
      }
      final progress = await _api.getProgress(
        authToken: token,
        assessmentId: assessmentId,
      );
      final rawAnswers = progress['answers'];
      if (rawAnswers is List) {
        for (final a in rawAnswers) {
          if (a is Map) {
            final q = a['question'];
            if (q != null) {
              answeredIds.add((q as num).toInt());
            }
          }
        }
      }
      final allAnswered =
          totalQuestions > 0 && answeredIds.length >= totalQuestions;
      final lastGenerated = await AppStorage().getLastResultsGeneratedAt();

      // Gera/atualiza resultado e mostra notificação ao chegar no Home (assimila todas as respostas)
      final wasNotAllAnswered = !_allQuestionsAnswered;
      if (allAnswered) {
        await AppStorage().setLastResultsGeneratedAt(DateTime.now());
      }

      if (mounted) {
        setState(() {
          _allQuestionsAnswered = allAnswered;
          _lastResultsGeneratedAt = allAnswered
              ? DateTime.now()
              : lastGenerated;
        });
        if (allAnswered && wasNotAllAnswered) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).t('results_new_generated'),
              ),
              backgroundColor: Brand.black,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      // Em erro (429, rede, etc.), não altera _allQuestionsAnswered para não esconder Resultados
    } finally {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkIfAllAnswered();
    });
  }

  static String _formatTimestamp(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  Future<void> _logout(BuildContext context) async {
    await AppStorage().clearAll();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phases = _localizedPhases(context);
    return Scaffold(
      // Tom próximo das montanhas se o asset atrasar; evita cinza do tema (web).
      backgroundColor: const Color(0xFF3a4f63),
      appBar: soberaniaAppBar(
        context,
        title: l10n.t('phases_title'),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AssessmentIntroScreen()),
              (_) => false,
            );
          },
          tooltip: l10n.t('go_to_intro'),
        ),
        trailing: TextButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout, size: 18, color: Brand.black),
          label: Text(
            l10n.t('btn_logout'),
            style: const TextStyle(color: Brand.black),
          ),
        ),
      ),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Sem ImageFiltered: no Flutter Web costuma renderizar cinza em vez da imagem.
            Positioned.fill(
              child: Image.asset(
                'assets/images/montanhas.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF5a7a94), Color(0xFF2c3e50)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: const Color(0xFF4A4A4A).withValues(alpha: 0.72),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showPanel = constraints.maxWidth > 800;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, inner) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: inner.maxHeight,
                                    maxWidth: 680,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.t('phases_choose'),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: Brand.white,
                                              shadows: const [
                                                Shadow(
                                                  color: Color(0x66000000),
                                                  blurRadius: 6,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                      ),
                                    const SizedBox(height: 16),
                                    ...phases.map(
                                      (p) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _PillarBannerCard(
                                          option: p,
                                          onTap: () {
                                            Navigator.of(context)
                                                .push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        QuestionsScreen(
                                                          phase: p.value,
                                                          phaseLabel: p.label,
                                                          byPilar: true,
                                                        ),
                                                  ),
                                                )
                                                .then(
                                                  (_) => _checkIfAllAnswered(),
                                                );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Builder(
                                      builder: (context) {
                                        final enabled = _allQuestionsAnswered;
                                        final cardColor = enabled
                                            ? Brand.resultsBlue
                                            : Brand.resultsBlue.withValues(
                                                alpha: 0.45,
                                              );
                                        return Card(
                                          margin: EdgeInsets.zero,
                                          elevation: 0,
                                          color: cardColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            side: BorderSide(
                                              color: enabled
                                                  ? Brand.border
                                                  : Brand.border.withValues(
                                                      alpha: 0.45,
                                                    ),
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 14,
                                                ),
                                            leading: Icon(
                                              Icons.bar_chart_rounded,
                                              color: Brand.white.withValues(
                                                alpha: enabled ? 1 : 0.75,
                                              ),
                                              size: 28,
                                            ),
                                            title: Text(
                                              l10n.t('results_title'),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Brand.white.withValues(
                                                  alpha: enabled ? 1 : 0.78,
                                                ),
                                                fontSize: 18,
                                              ),
                                            ),
                                            subtitle: Text(
                                              enabled
                                                  ? (_lastResultsGeneratedAt !=
                                                          null
                                                      ? '${l10n.t('results_generated_at')}: ${_formatTimestamp(_lastResultsGeneratedAt!)}'
                                                      : l10n.t(
                                                          'results_view_scores',
                                                        ))
                                                  : l10n.t(
                                                      'results_available_hint',
                                                    ),
                                              style: TextStyle(
                                                color: Brand.white.withValues(
                                                  alpha: enabled ? 0.82 : 0.72,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                            trailing: Icon(
                                              Icons.chevron_right,
                                              color: Brand.white.withValues(
                                                alpha: enabled ? 1 : 0.7,
                                              ),
                                              size: 28,
                                            ),
                                            onTap: enabled
                                                ? () {
                                                    Navigator.of(context)
                                                        .push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                const ResultsScreen(),
                                                          ),
                                                        )
                                                        .then(
                                                          (_) =>
                                                              _checkIfAllAnswered(),
                                                        );
                                                  }
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            );
                          },
                        ),
                      ),
                      if (showPanel) const ChatPanel(questionContext: null),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarBannerCard extends StatelessWidget {
  const _PillarBannerCard({required this.option, required this.onTap});

  final PhaseOption option;
  final VoidCallback onTap;

  static Color _baseColor(String value) {
    switch (value) {
      case 'Compliance':
        return Brand.accentRed;
      case 'Continuity':
        return Brand.accentBlue;
      case 'Control':
        return Brand.controlPurple;
      default:
        return Brand.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final base = _baseColor(option.value);
    final panelBg = Color.lerp(Brand.white, base, 0.15) ?? Brand.white;
    const accentWidth = 9.0;

    final textBlock = Container(
      width: double.infinity,
      color: panelBg,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            option.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Brand.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            option.subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t(option.descriptionKey),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Brand.black.withValues(alpha: 0.88),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.chevron_right, color: Colors.black45, size: 22),
          ),
        ],
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Brand.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Brand.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: accentWidth),
                child: textBlock,
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: accentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color.lerp(Colors.white, base, 0.62) ?? base,
                        Color.lerp(Colors.white, base, 0.90) ?? base,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
