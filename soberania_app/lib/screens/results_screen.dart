import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../api/rag_api.dart';
import '../api/xano_api.dart';
import '../models/models.dart';
import '../storage/app_storage.dart';
import '../l10n/app_localizations.dart';
import '../ui/brand.dart';
import '../widgets/chat_panel.dart';
import '../widgets/custom_radar_chart.dart';
import 'assessment_intro_screen.dart';

/// Dados agregados para os gráficos.
class ResultsData {
  final Map<String, double> scoreByPilar; // Compliance, Control, Continuity
  final List<String> pilars;
  final Map<String, double> scoreByDominio; // Soberania de Dados, etc.
  final List<String> dominios;

  ResultsData({
    required this.scoreByPilar,
    required this.pilars,
    required this.scoreByDominio,
    required this.dominios,
  });
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _api = XanoApi();
  final _rag = RagApi();
  final _storage = AppStorage();

  bool _loading = true;
  String? _error;
  ResultsData? _data;
  String? _userName;
  String? _userEmail;
  String? _botOverview;
  bool _overviewLoading = false;

  static const _phaseOrder = ['Quick_Wins', 'Foundational', 'Efficient', 'Optimized'];

  String get _languageCode {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('en')) return 'en';
    if (code.startsWith('es')) return 'es';
    return 'pt';
  }

  String _localizedPilar(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context);
    switch (raw.trim().toLowerCase()) {
      case 'compliance':
        return l10n.t('phase_compliance_label');
      case 'continuity':
        return l10n.t('phase_continuity_label');
      case 'control':
        return l10n.t('phase_control_label');
      default:
        return raw;
    }
  }

  String _localizedDominio(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context);
    switch (raw.trim().toLowerCase()) {
      case 'continuidade e portabilidade':
      case 'continuity and portability':
      case 'continuidad y portabilidad':
        return l10n.t('domain_continuity_portability');
      case 'governança e conformidade':
      case 'governance and compliance':
      case 'gobernanza y cumplimiento':
        return l10n.t('domain_governance_compliance');
      case 'soberania operacional':
      case 'operational sovereignty':
      case 'soberanía operacional':
        return l10n.t('domain_operational_sovereignty');
      case 'soberania organizacional':
      case 'organizational sovereignty':
      case 'soberanía organizacional':
        return l10n.t('domain_organizational_sovereignty');
      case 'soberania de dados':
      case 'data sovereignty':
      case 'soberanía de datos':
        return l10n.t('domain_data_sovereignty');
      case 'soberania de infraestrutura':
      case 'infrastructure sovereignty':
      case 'soberanía de infraestructura':
        return l10n.t('domain_infrastructure_sovereignty');
      default:
        return raw;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });

    try {
      final token = await _storage.getAuthToken();
      final assessmentId = await _storage.getAssessmentId();
      _userName = await _storage.getUserName();
      _userEmail = await _storage.getUserEmail();
      if (token == null) throw StateError('Sem authToken. Faça login.');
      if (assessmentId == null) throw StateError('Sem assessment.');

      final progress = await _api.getProgress(
        authToken: token,
        assessmentId: assessmentId,
      );

      final rawAnswers = progress['answers'];
      final answers = <SavedAnswer>[];
      if (rawAnswers is List) {
        for (final a in rawAnswers) {
          if (a is Map) {
            answers.add(SavedAnswer.fromJson(a.cast<String, dynamic>()));
          }
        }
      }

      final questionMap = <int, Question>{};
      for (final phase in _phaseOrder) {
        final raw = await _api.listQuestions(authToken: token, phase: phase);
        for (final e in raw) {
          if (e is Map) {
            final q = Question.fromJson(e.cast<String, dynamic>());
            questionMap[q.id] = q;
          }
        }
      }

      final byPilar = <String, List<int>>{};
      final byDominio = <String, List<int>>{};
      for (final a in answers) {
        final q = questionMap[a.questionId];
        if (q == null || a.score == null) continue;
        final pct = scoreTextToPercent(a.score);
        byPilar.putIfAbsent(q.pilar, () => []).add(pct);
        final dom = (q.dominio ?? '').trim();
        if (dom.isNotEmpty) {
          byDominio.putIfAbsent(dom, () => []).add(pct);
        }
      }

      double avg(List<int> list) =>
          list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;

      final scoreByPilar = <String, double>{};
      for (final e in byPilar.entries) {
        scoreByPilar[e.key] = avg(e.value).roundToDouble();
      }
      final pilars = scoreByPilar.keys.toList()
        ..sort((a, b) => a.compareTo(b));

      final scoreByDominio = <String, double>{};
      for (final e in byDominio.entries) {
        scoreByDominio[e.key] = avg(e.value).roundToDouble();
      }
      final dominios = scoreByDominio.keys.toList()
        ..sort((a, b) => a.compareTo(b));

      _data = ResultsData(
        scoreByPilar: scoreByPilar,
        pilars: pilars,
        scoreByDominio: scoreByDominio,
        dominios: dominios,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
      if (mounted && _data != null && _error == null) _loadBotOverview();
    }
  }

  Future<void> _loadBotOverview() async {
    if (_data == null) return;
    setState(() {
      _botOverview = null;
      _overviewLoading = true;
    });
    try {
      final ctx = _buildResultsContext();
      if (ctx.isEmpty) {
        setState(() => _overviewLoading = false);
        return;
      }
      final resp = await _rag.ask(
        _languageCode == 'en'
            ? 'Write ONE short paragraph in English summarizing the results of this digital sovereignty assessment. Use at most 4 sentences, highlighting the main strengths and improvement opportunities in an executive and objective tone.'
            : _languageCode == 'es'
                ? 'Escriba UN párrafo corto en español resumiendo los resultados de este assessment de soberanía digital. Use un máximo de 4 frases, destacando las principales fortalezas y oportunidades de mejora, de forma ejecutiva y objetiva.'
                : 'Escreva UM parágrafo curto, em português, resumindo os resultados deste assessment de soberania digital. Use no máximo 4 frases, destacando principais pontos fortes e principais oportunidades de melhoria, de forma executiva e objetiva.',
        questionContext: ctx,
        languageCode: _languageCode,
      );
      if (mounted && resp.answer.trim().isNotEmpty) {
        // Garante no mínimo 1 parágrafo enxuto na UI: pega só o primeiro parágrafo
        // e limita o tamanho máximo do texto.
        var text = resp.answer.trim();
        final paragraphs = text.split('\n\n');
        if (paragraphs.isNotEmpty) {
          text = paragraphs.first.trim();
        }
        const maxChars = 600;
        if (text.length > maxChars) {
          text = '${text.substring(0, maxChars).trim()}...';
        }
        setState(() {
          _botOverview = text;
          _overviewLoading = false;
        });
      } else if (mounted) {
        setState(() => _overviewLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _overviewLoading = false);
    }
  }

  String _buildResultsContext() {
    if (_data == null) return '';
    final l10n = AppLocalizations.of(context);
    final pilarScores = _data!.pilars
        .map((p) => '${_localizedPilar(context, p)}: ${_data!.scoreByPilar[p]?.toInt() ?? 0}%')
        .join(', ');
    final dominioScores = _data!.dominios
        .map((d) => '${_localizedDominio(context, d)}: ${_data!.scoreByDominio[d]?.toInt() ?? 0}%')
        .join(', ');
    if (_languageCode == 'en') {
      return 'RESULTS BY PILLAR: $pilarScores. RESULTS BY DOMAIN: $dominioScores.';
    }
    if (_languageCode == 'es') {
      return 'RESULTADOS POR PILAR: $pilarScores. RESULTADOS POR DOMINIO: $dominioScores.';
    }
    return '${l10n.t('results_score_by_pillar').toUpperCase()}: $pilarScores. ${l10n.t('results_score_by_domain').toUpperCase()}: $dominioScores.';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? subtitle;
    if ((_userName != null && _userName!.isNotEmpty) || (_userEmail != null && _userEmail!.isNotEmpty)) {
      final parts = <String>[];
      if (_userName != null && _userName!.isNotEmpty) parts.add(_userName!);
      if (_userEmail != null && _userEmail!.isNotEmpty) parts.add(_userEmail!);
      subtitle = '${l10n.t('results_provided_by')} ${parts.join(', ')}';
    }

    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(
        context,
        title: l10n.t('results_title'),
        subtitle: subtitle,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: l10n.t('back_to_pillars'),
            ),
            IconButton(
              icon: const Icon(Icons.home_rounded),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AssessmentIntroScreen()),
                  (_) => false,
                );
              },
              tooltip: l10n.t('go_to_intro'),
            ),
          ],
        ),
        leadingWidth: 96,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : _data == null
                    ? Center(child: Text(l10n.t('results_no_data')))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final showPanel = constraints.maxWidth > 1100;
                          final chartsColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              _BotOverviewCard(
                                overview: _botOverview,
                                loading: _overviewLoading,
                              ),
                              const SizedBox(height: 24),
                              _ChartCard(
                                title: l10n.t('results_score_by_pillar'),
                                child: _PilarBarChart(
                                  data: _data!,
                                  labelBuilder: (p) => _localizedPilar(context, p),
                                ),
                              ),
                              if (_data!.dominios.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                _ChartCard(
                                  title: l10n.t('results_score_by_domain'),
                                  height: 400,
                                  child: _DominioRadarChart(
                                    data: _data!,
                                    labelBuilder: (d) => _localizedDominio(context, d),
                                  ),
                                ),
                              ],
                              if (!showPanel) ...[
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 400,
                                  child: Card(
                                    elevation: 0,
                                    color: Brand.white,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Brand.border),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: ChatPanel(resultsContext: _buildResultsContext()),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),
                            ],
                          );
                          if (showPanel) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: chartsColumn,
                                  ),
                                ),
                                ChatPanel(resultsContext: _buildResultsContext()),
                              ],
                            );
                          }
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: chartsColumn,
                          );
                        },
                      ),
      ),
    );
  }
}

class _BotOverviewCard extends StatelessWidget {
  final String? overview;
  final bool loading;

  const _BotOverviewCard({this.overview, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 0,
      color: Brand.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.smart_toy, color: Brand.black, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: loading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Brand.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.t('results_overview_loading'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Brand.black,
                              ),
                        ),
                      ],
                    )
                  : overview != null && overview!.isNotEmpty
                      ? SelectableText(
                          overview!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: Brand.black,
                              ),
                        )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;

  const _ChartCard({
    required this.title,
    required this.child,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Brand.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Brand.black,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de teia (radar) para domínios.
class _DominioRadarChart extends StatelessWidget {
  final ResultsData data;
  final String Function(String) labelBuilder;

  const _DominioRadarChart({required this.data, required this.labelBuilder});

  @override
  Widget build(BuildContext context) {
    if (data.dominios.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).t('results_radar_empty')));
    }

    final values = data.dominios
        .map((d) => (data.scoreByDominio[d] ?? 0).toDouble())
        .toList();

    return CustomRadarChart(
      labels: data.dominios.map(labelBuilder).toList(),
      values: values,
      // Usa paleta da marca: preenchimento suave em azul, borda em vermelho.
      fillColor: Brand.accentBlue,
      borderColor: Brand.accentRed,
      gridColor: Brand.border,
      textColor: Brand.black,
    );
  }
}

class _PilarBarChart extends StatelessWidget {
  final ResultsData data;
  final String Function(String) labelBuilder;

  const _PilarBarChart({required this.data, required this.labelBuilder});

  @override
  Widget build(BuildContext context) {
    final palette = <Color>[
      Brand.accentRed,
      Brand.accentBlue,
      Brand.accentOrange,
    ];

    final items = <BarChartGroupData>[];
    for (var i = 0; i < data.pilars.length; i++) {
      final p = data.pilars[i];
      final color = palette[i % palette.length];
      items.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (data.scoreByPilar[p] ?? 0).toDouble(),
              width: 28,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  color.withOpacity(0.9),
                  color.withOpacity(0.6),
                ],
              ),
            ),
          ],
          showingTooltipIndicators: const [0],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Brand.black,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final pilar = labelBuilder(data.pilars[group.x]);
              return BarTooltipItem(
                '$pilar\n${rod.toY.toInt()}%',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.pilars.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labelBuilder(data.pilars[value.toInt()]),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Brand.black,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 28,
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  fontSize: 10,
                  color: Brand.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Brand.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: items,
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.black,
                foregroundColor: Brand.white,
              ),
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).t('results_retry')),
            ),
          ],
        ),
      ),
    );
  }
}
