import 'package:flutter/material.dart';

import '../api/xano_api.dart';
import '../models/models.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import '../widgets/chat_panel.dart';
import 'login_screen.dart';
import 'questions_screen.dart';
import 'results_screen.dart';

class PhasesScreen extends StatefulWidget {
  const PhasesScreen({super.key});

  @override
  State<PhasesScreen> createState() => _PhasesScreenState();
}

class _PhasesScreenState extends State<PhasesScreen> {
  static const phases = <PhaseOption>[
    // IMPORTANTE: esses valores precisam bater com o enum do Xano.
    PhaseOption('Quick_Wins', 'Quick Wins', 'Ações rápidas com alto impacto'),
    PhaseOption(
      'Foundational',
      'Foundational',
      'Base de governança e controles',
    ),
    PhaseOption('Efficient', 'Efficient', 'Eficiência operacional e automação'),
    PhaseOption('Optimized', 'Optimized', 'Maturidade avançada e resiliência'),
  ];

  final _api = XanoApi();
  bool _loadingResults = true;
  bool _allQuestionsAnswered = false;

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
      for (final p in phases) {
        final raw = await _api.listQuestions(authToken: token, phase: p.value);
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
      final allAnswered = totalQuestions > 0 && answeredIds.length >= totalQuestions;
      if (mounted) setState(() => _allQuestionsAnswered = allAnswered);
    } catch (_) {
      if (mounted) setState(() => _allQuestionsAnswered = false);
    } finally {
      if (mounted) setState(() => _loadingResults = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkIfAllAnswered();
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
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(context, title: 'Fases'),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Escolha uma fase para responder',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Brand.black,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _logout(context),
                                icon: const Icon(Icons.logout),
                                label: const Text('Sair'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_allQuestionsAnswered) ...[
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
                                title: const Text(
                                  'Resultados',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Brand.white,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Ver seus gráficos de pontuação',
                                  style: TextStyle(
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
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ResultsScreen(),
                                    ),
                                  ).then((_) => _checkIfAllAnswered());
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else if (!_loadingResults)
                            Text(
                              'Responda todas as questões de todas as fases para ver os resultados.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          const SizedBox(height: 12),
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
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  subtitle: Text(p.subtitle),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => QuestionsScreen(
                                          phase: p.value,
                                          phaseLabel: p.label,
                                        ),
                                      ),
                                    ).then((_) => _checkIfAllAnswered());
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Obs: os valores das fases precisam bater com seu enum no Xano.\n'
                            'Se der erro de "not one of the allowable values", copie o valor exato do enum no Swagger do Xano.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                          ),
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
