import 'package:flutter/material.dart';

import '../api/xano_api.dart';
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

  final _api = XanoApi();
  bool _loadingResults = true;
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
      ),
      PhaseOption(
        'Continuity',
        l10n.t('phase_continuity_label'),
        l10n.t('phase_continuity_subtitle'),
      ),
      PhaseOption(
        'Control',
        l10n.t('phase_control_label'),
        l10n.t('phase_control_subtitle'),
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
              content: Text(AppLocalizations.of(context).t('results_new_generated')),
              backgroundColor: Brand.black,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      // Em erro (429, rede, etc.), não altera _allQuestionsAnswered para não esconder Resultados
    } finally {
      if (mounted) {
        setState(() => _loadingResults = false);
      }
    }
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
    return '$d/$m ${h}:$min';
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
      backgroundColor: Brand.surface,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showPanel = constraints.maxWidth > 800;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            l10n.t('phases_choose'),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Brand.black,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.t('phases_choose_subtext'),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.black54,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...phases.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                elevation: 0,
                                color: Brand.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Brand.border),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  title: Text(
                                    p.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Text(p.subtitle),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) => QuestionsScreen(
                                              phase: p.value,
                                              phaseLabel: p.label,
                                              byPilar: true,
                                            ),
                                          ),
                                        )
                                        .then((_) => _checkIfAllAnswered());
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (_allQuestionsAnswered) ...[
                            const SizedBox(height: 12),
                            Card(
                              elevation: 0,
                              color: Brand.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Brand.border),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                leading: const Icon(
                                  Icons.bar_chart_rounded,
                                  color: Brand.white,
                                  size: 28,
                                ),
                                title: Text(
                                  l10n.t('results_title'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Brand.white,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  _lastResultsGeneratedAt != null
                                      ? '${l10n.t('results_generated_at')}: ${_formatTimestamp(_lastResultsGeneratedAt!)}'
                                      : l10n.t('results_view_scores'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Brand.white,
                                  size: 28,
                                ),
                                onTap: () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) => const ResultsScreen(),
                                        ),
                                      )
                                      .then((_) => _checkIfAllAnswered());
                                },
                              ),
                            ),
                          ] else if (!_loadingResults) ...[
                            const SizedBox(height: 12),
                            Text(
                              l10n.t('results_available_hint'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (showPanel) const ChatPanel(questionContext: null),
              ],
            );
          },
        ),
      ),
    );
  }
}
