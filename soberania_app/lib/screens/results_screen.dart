import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../api/xano_api.dart';
import '../models/models.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';

/// Dados agregados para os gráficos.
class ResultsData {
  final Map<String, double> scoreByPilar; // Compliance, Control, Continuity
  final Map<String, double> scoreByPhase; // Quick Wins, Foundational, etc.
  final List<String> pilars;

  ResultsData({
    required this.scoreByPilar,
    required this.scoreByPhase,
    required this.pilars,
  });
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _api = XanoApi();
  final _storage = AppStorage();

  bool _loading = true;
  String? _error;
  ResultsData? _data;
  String? _userName;
  String? _userEmail;

  static const _phaseOrder = ['Quick_Wins', 'Foundational', 'Efficient', 'Optimized'];
  static const _phaseLabels = {
    'Quick_Wins': 'Quick Wins',
    'Foundational': 'Foundational',
    'Efficient': 'Efficient',
    'Optimized': 'Optimized',
  };

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
      final byPhase = <String, List<int>>{};
      for (final a in answers) {
        final q = questionMap[a.questionId];
        if (q == null || a.score == null) continue;
        final pct = scoreTextToPercent(a.score);

        byPilar.putIfAbsent(q.pilar, () => []).add(pct);
        byPhase.putIfAbsent(q.phase, () => []).add(pct);
      }

      double avg(List<int> list) =>
          list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;

      final scoreByPilar = <String, double>{};
      for (final e in byPilar.entries) {
        scoreByPilar[e.key] = avg(e.value).roundToDouble();
      }

      final scoreByPhase = <String, double>{};
      for (final e in byPhase.entries) {
        scoreByPhase[e.key] = avg(e.value).roundToDouble();
      }

      final pilars = scoreByPilar.keys.toList()
        ..sort((a, b) => a.compareTo(b));

      _data = ResultsData(
        scoreByPilar: scoreByPilar,
        scoreByPhase: scoreByPhase,
        pilars: pilars,
      );
      // Timestamp de geração é salvo em QuestionsScreen ao completar questões
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar às fases',
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : _data == null
                    ? const Center(child: Text('Nenhum dado disponível.'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            _ChartCard(
                              title: 'Score por Pilar',
                              child: _PilarBarChart(data: _data!),
                            ),
                            const SizedBox(height: 24),
                            _ChartCard(
                              title: 'Score por Fase',
                              child: _PhaseBarChart(data: _data!),
                            ),
                            const SizedBox(height: 24),
                            _ChartCard(
                              title: 'Visão Geral (Radar)',
                              height: 400,
                              child: _RadarChart(data: _data!),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
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

class _PhaseBarChart extends StatelessWidget {
  final ResultsData data;

  const _PhaseBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final orderedPhases = _ResultsScreenState._phaseOrder
        .where((p) => data.scoreByPhase.containsKey(p))
        .toList();

    final items = orderedPhases
        .map((phase) {
          final i = orderedPhases.indexOf(phase);
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (data.scoreByPhase[phase] ?? 0).toDouble(),
                color: Brand.black,
                width: 36,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        })
        .toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Brand.black,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final phase = orderedPhases[group.x];
              final label = _ResultsScreenState._phaseLabels[phase] ?? phase;
              return BarTooltipItem(
                '$label\n${rod.toY.toInt()}%',
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
                if (value.toInt() >= 0 && value.toInt() < orderedPhases.length) {
                  final phase = orderedPhases[value.toInt()];
                  final label = _ResultsScreenState._phaseLabels[phase] ?? phase;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Brand.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 40,
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

    final entries = data.pilars
        .map((p) => RadarEntry(value: (data.scoreByPilar[p] ?? 0).toDouble()))
        .toList();

    // Datasets invisíveis para forçar escala 0–100% (0, 25, 50, 75, 100).
    // Max 125 + tickCount 5 gera ticks 0, 25, 50, 75, 100, 125; labels mostram 0–100.
    final minEntries = List.generate(data.pilars.length, (_) => const RadarEntry(value: 0));
    final maxEntries = List.generate(data.pilars.length, (_) => const RadarEntry(value: 125));

    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 5,
        titlePositionPercentageOffset: 0.15,
        ticksTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Brand.black,
        ),
        dataSets: [
          RadarDataSet(
            fillColor: Colors.transparent,
            borderColor: Colors.transparent,
            borderWidth: 0,
            dataEntries: minEntries,
          ),
          RadarDataSet(
            fillColor: Colors.transparent,
            borderColor: Colors.transparent,
            borderWidth: 0,
            dataEntries: maxEntries,
          ),
          RadarDataSet(
            fillColor: _radarBlue.withValues(alpha: 0.15),
            borderColor: _radarBlue,
            borderWidth: 2,
            dataEntries: entries,
            entryRadius: 4,
          ),
        ],
        titleTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Brand.black,
        ),
        getTitle: (index, angle) => RadarChartTitle(
          text: data.pilars[index],
        ),
        radarBackgroundColor: Brand.surface,
        tickBorderData: const BorderSide(color: Brand.border, width: 1),
        gridBorderData: const BorderSide(color: Brand.border, width: 1),
        borderData: FlBorderData(show: false),
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
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
