import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../api/rag_api.dart';
import '../api/xano_api.dart';
import '../models/models.dart';
import '../storage/app_storage.dart';
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
        'Faça um overview executivo dos resultados deste assessment de soberania digital. '
        'Dê uma leitura em 2-3 parágrafos, destacando pontos fortes e áreas de melhoria.',
        questionContext: ctx,
      );
      if (mounted && resp.answer.trim().isNotEmpty) {
        setState(() {
          _botOverview = resp.answer.trim();
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
    final pilarScores = _data!.pilars
        .map((p) => '$p: ${_data!.scoreByPilar[p]?.toInt() ?? 0}%')
        .join(', ');
    final dominioScores = _data!.dominios
        .map((d) => '$d: ${_data!.scoreByDominio[d]?.toInt() ?? 0}%')
        .join(', ');
    return 'RESULTADOS POR PILAR: $pilarScores. RESULTADOS POR DOMÍNIO: $dominioScores.';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    String? subtitle;
    if ((_userName != null && _userName!.isNotEmpty) || (_userEmail != null && _userEmail!.isNotEmpty)) {
      final parts = <String>[];
      if (_userName != null && _userName!.isNotEmpty) parts.add(_userName!);
      if (_userEmail != null && _userEmail!.isNotEmpty) parts.add(_userEmail!);
      subtitle = 'Fornecidos por ${parts.join(' e ')}';
    }

    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(
        context,
        title: 'Resultados',
        subtitle: subtitle,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Voltar para pilares',
            ),
            IconButton(
              icon: const Icon(Icons.home_rounded),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AssessmentIntroScreen()),
                  (_) => false,
                );
              },
              tooltip: 'Ir para introdução',
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
                    ? const Center(child: Text('Nenhum dado disponível.'))
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
                                title: 'Visão Geral (Radar)',
                                height: 400,
                                child: _RadarChart(data: _data!),
                              ),
                              const SizedBox(height: 24),
                              _ChartCard(
                                title: 'Score por Pilar',
                                child: _PilarBarChart(data: _data!),
                              ),
                              if (_data!.dominios.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                _ChartCard(
                                  title: 'Score por Domínio',
                                  height: 400,
                                  child: _DominioRadarChart(data: _data!),
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
                          'O Bot está analisando os resultados...',
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

  const _DominioRadarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.dominios.isEmpty) {
      return const Center(child: Text('Sem dados para radar'));
    }

    final values = data.dominios
        .map((d) => (data.scoreByDominio[d] ?? 0).toDouble())
        .toList();

    return CustomRadarChart(
      labels: data.dominios,
      values: values,
      fillColor: _radarBlue,
      borderColor: _radarBlue,
      gridColor: Brand.border,
      textColor: Brand.black,
    );
  }
}

class _PilarBarChart extends StatelessWidget {
  final ResultsData data;

  const _PilarBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data.pilars
        .map((p) => BarChartGroupData(
              x: data.pilars.indexOf(p),
              barRods: [
                BarChartRodData(
                  toY: (data.scoreByPilar[p] ?? 0).toDouble(),
                  color: Brand.black,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
              showingTooltipIndicators: [0],
            ))
        .toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Brand.black,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final pilar = data.pilars[group.x];
              return BarTooltipItem(
                '$pilar\n${rod.toY.toInt()}%',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                      data.pilars[value.toInt()],
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

/// Azul similar ao Excel para o radar.
const _radarBlue = Color(0xFF1E88E5);

class _RadarChart extends StatelessWidget {
  final ResultsData data;

  const _RadarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.pilars.isEmpty) {
      return const Center(child: Text('Sem dados para radar'));
    }

    final values = data.pilars
        .map((p) => (data.scoreByPilar[p] ?? 0).toDouble())
        .toList();

    return CustomRadarChart(
      labels: data.pilars,
      values: values,
      fillColor: _radarBlue,
      borderColor: _radarBlue,
      gridColor: Brand.border,
      textColor: Brand.black,
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
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
