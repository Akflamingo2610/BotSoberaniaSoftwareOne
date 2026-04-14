import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../api/rag_api.dart';
import '../api/backend_api.dart';
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
  final _api = BackendApi();
  final _rag = RagApi();
  final _storage = AppStorage();
  final GlobalKey _pdfKey = GlobalKey();

  bool _loading = true;
  String? _error;
  ResultsData? _data;
  String? _userName;
  String? _userEmail;
  String? _botOverview;
  bool _overviewLoading = false;
  bool _exportingPdf = false;
  String? _quickQuestion;
  int _quickQuestionNonce = 0;

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
            ? 'Write one short and clear paragraph in English summarizing these digital sovereignty assessment results. Use simple language, 3 to 4 complete sentences, and explain what the scores mean in practice. Mention the strongest point and the main opportunity for improvement. End with a direct recommendation in one sentence.'
            : _languageCode == 'es'
                ? 'Escriba un párrafo breve y claro en español resumiendo estos resultados del assessment de soberanía digital. Use lenguaje simple, de 3 a 4 frases completas, y explique qué significan los puntajes en la práctica. Mencione el punto más fuerte y la principal oportunidad de mejora. Termine con una recomendación directa en una frase.'
                : 'Escreva um parágrafo curto e claro, em português, resumindo os resultados deste assessment de soberania digital. Use linguagem simples, de 3 a 4 frases completas, e explique o que os percentuais significam na prática. Destaque o ponto mais forte e a principal oportunidade de melhoria. Termine com uma recomendação direta em uma frase.',
        questionContext: ctx,
        languageCode: _languageCode,
      );
      if (mounted && resp.answer.trim().isNotEmpty) {
        final text = _normalizeOverviewText(resp.answer);
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

  String _normalizeOverviewText(String raw) {
    var text = raw.trim();
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    if (paragraphs.isNotEmpty) {
      text = paragraphs.first.trim();
    }
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text.replaceAll('...', '.').replaceAll('…', '.').trim();

    const maxChars = 520;
    if (text.length > maxChars) {
      final clipped = text.substring(0, maxChars).trim();
      final boundary = _lastSentenceBoundary(clipped);
      if (boundary >= (maxChars * 0.55).floor()) {
        text = clipped.substring(0, boundary + 1).trim();
      } else {
        final lastSpace = clipped.lastIndexOf(' ');
        text = (lastSpace > 0 ? clipped.substring(0, lastSpace) : clipped).trim();
      }
    }

    // Garante término conclusivo sem reticências/corte no meio.
    text = text.replaceFirst(RegExp(r'[,:;]\s*$'), '').trim();
    if (!_hasTerminalPunctuation(text)) {
      text = '$text.';
    }
    return text;
  }

  int _lastSentenceBoundary(String text) {
    final chars = text.split('');
    for (var i = chars.length - 1; i >= 0; i--) {
      final c = chars[i];
      if (c == '.' || c == '!' || c == '?') return i;
    }
    return -1;
  }

  bool _hasTerminalPunctuation(String text) {
    return text.endsWith('.') || text.endsWith('!') || text.endsWith('?');
  }

  void _triggerQuickQuestion(String question) {
    setState(() {
      _quickQuestion = question.trim();
      _quickQuestionNonce += 1;
    });
  }

  String _buildPilarQuestion(String pilar, int score) {
    final localized = _localizedPilar(context, pilar);
    if (_languageCode == 'en') {
      return 'Explain, in a simple and concise way, what $score% in $localized means for our current maturity.';
    }
    if (_languageCode == 'es') {
      return 'Explique de forma simple y breve qué significa $score% en $localized para nuestra madurez actual.';
    }
    return 'Explique de forma simples e objetiva o que significa $score% em $localized para nossa maturidade atual.';
  }

  String _buildDomainQuestion(String domain, int score) {
    final localized = _localizedDominio(context, domain);
    if (_languageCode == 'en') {
      return 'Explain what the domain "$localized" means and what our score of $score% indicates today.';
    }
    if (_languageCode == 'es') {
      return 'Explique qué significa el dominio "$localized" y qué indica hoy nuestra puntuación de $score%.';
    }
    return 'Explique o que significa o domínio "$localized" e o que a nossa pontuação de $score% indica hoje.';
  }

  Future<void> _exportResultsPdf() async {
    if (_exportingPdf || _loading || _data == null) return;
    setState(() => _exportingPdf = true);
    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _pdfKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Aumenta nitidez para gráficos e textos no PDF final.
      final ui.Image image = await boundary.toImage(pixelRatio: 2.4);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final doc = pw.Document();
      final pw.MemoryImage chartImage = pw.MemoryImage(pngBytes);

      final title = _languageCode == 'en'
          ? 'Digital Sovereignty Assessment Results'
          : _languageCode == 'es'
              ? 'Resultados del Assessment de Soberanía Digital'
              : 'Resultados do Assessment de Soberania Digital';

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Expanded(
                  child: pw.Container(
                    width: double.infinity,
                    child: pw.Image(chartImage, fit: pw.BoxFit.contain),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'resultados_soberania_digital.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageCode == 'en'
                ? 'Could not generate the PDF. Please try again.'
                : _languageCode == 'es'
                    ? 'No fue posible generar el PDF. Inténtelo nuevamente.'
                    : 'Nao foi possivel gerar o PDF. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
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
        compactTrailingActions: true,
        actionsPadding: const EdgeInsetsDirectional.only(end: 6, start: 4),
        trailing: Tooltip(
          message: l10n.t('btn_generate_pdf'),
          child: SizedBox(
            height: 36,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.assessmentCtaBlue,
                foregroundColor: Brand.white,
                padding: const EdgeInsets.fromLTRB(14, 8, 20, 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _exportingPdf ? null : _exportResultsPdf,
              icon: _exportingPdf
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Brand.white,
                      ),
                    )
                  : Image.asset(
                      'assets/images/PDF.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.picture_as_pdf,
                        color: Brand.white,
                        size: 22,
                      ),
                    ),
              label: Text(
                l10n.t('btn_generate_pdf').toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
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
                          final contentWidth = showPanel
                              ? (constraints.maxWidth - 360).clamp(0, constraints.maxWidth)
                              : constraints.maxWidth;
                          final sideBySideCharts = contentWidth >= 980;
                          final resultsContent = RepaintBoundary(
                            key: _pdfKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                _BotOverviewCard(
                                  overview: _botOverview,
                                  loading: _overviewLoading,
                                ),
                                const SizedBox(height: 24),
                                if (_data!.dominios.isNotEmpty && sideBySideCharts) ...[
                                  // Altura fixa para a linha: os dois cartões ficam iguais (scroll tem altura ilimitada).
                                  SizedBox(
                                    height: 528,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: _ChartCard(
                                            title: l10n
                                                .t('results_score_by_pillar'),
                                            subtitle: _languageCode == 'en'
                                                ? 'Tap a bar or percentage to ask the bot for an explanation.'
                                                : _languageCode == 'es'
                                                    ? 'Toque una barra o porcentaje para pedir una explicación al bot.'
                                                    : 'Toque em uma barra ou porcentagem para pedir explicação ao bot.',
                                            fillChartHeight: true,
                                            child: _PilarBarChart(
                                              data: _data!,
                                              labelBuilder: (p) =>
                                                  _localizedPilar(context, p),
                                              onPilarTap: (pilar, score) {
                                                _triggerQuickQuestion(
                                                  _buildPilarQuestion(
                                                    pilar,
                                                    score,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _ChartCard(
                                            title: l10n
                                                .t('results_score_by_domain'),
                                            subtitle: _languageCode == 'en'
                                                ? 'Tap a domain label or point on the radar to see what your percentage means.'
                                                : _languageCode == 'es'
                                                    ? 'Toque una etiqueta de dominio o un punto de la red para ver qué significa su porcentaje.'
                                                    : 'Toque no nome do domínio ou em um ponto do gráfico de teia para ver o que sua porcentagem significa.',
                                            fillChartHeight: true,
                                            child: _DominioRadarChart(
                                              data: _data!,
                                              labelBuilder: (d) =>
                                                  _localizedDominio(
                                                context,
                                                d,
                                              ),
                                              onDomainTap: (domain, score) {
                                                _triggerQuickQuestion(
                                                  _buildDomainQuestion(
                                                    domain,
                                                    score,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  _ChartCard(
                                    title: l10n.t('results_score_by_pillar'),
                                    subtitle: _languageCode == 'en'
                                        ? 'Tap a bar or percentage to ask the bot for an explanation.'
                                        : _languageCode == 'es'
                                            ? 'Toque una barra o porcentaje para pedir una explicación al bot.'
                                            : 'Toque em uma barra ou porcentagem para pedir explicação ao bot.',
                                    child: _PilarBarChart(
                                      data: _data!,
                                      labelBuilder: (p) => _localizedPilar(context, p),
                                      onPilarTap: (pilar, score) {
                                        _triggerQuickQuestion(
                                          _buildPilarQuestion(pilar, score),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                if (_data!.dominios.isNotEmpty && !sideBySideCharts) ...[
                                  const SizedBox(height: 24),
                                  _ChartCard(
                                    title: l10n.t('results_score_by_domain'),
                                    subtitle: _languageCode == 'en'
                                        ? 'Tap a domain label or point on the radar to see what your percentage means.'
                                        : _languageCode == 'es'
                                            ? 'Toque una etiqueta de dominio o un punto de la red para ver qué significa su porcentaje.'
                                            : 'Toque no nome do domínio ou em um ponto do gráfico de teia para ver o que sua porcentagem significa.',
                                    height: 400,
                                    child: _DominioRadarChart(
                                      data: _data!,
                                      labelBuilder: (d) => _localizedDominio(context, d),
                                      onDomainTap: (domain, score) {
                                        _triggerQuickQuestion(
                                          _buildDomainQuestion(domain, score),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 32),
                              ],
                            ),
                          );
                          if (showPanel) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: resultsContent,
                                  ),
                                ),
                                ChatPanel(
                                  resultsContext: _buildResultsContext(),
                                  quickQuestion: _quickQuestion,
                                  quickQuestionNonce: _quickQuestionNonce,
                                ),
                              ],
                            );
                          }
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                resultsContent,
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
                                      child: ChatPanel(
                                        resultsContext: _buildResultsContext(),
                                        quickQuestion: _quickQuestion,
                                        quickQuestionNonce: _quickQuestionNonce,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
  final String? subtitle;
  final Widget child;
  final double height;
  /// Em [Row] lado a lado: gráfico preenche a altura para igualar o cartão vizinho.
  final bool fillChartHeight;

  const _ChartCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.height = 220,
    this.fillChartHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final chartSlot = fillChartHeight
        ? Expanded(child: child)
        : SizedBox(height: height, child: child);

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
          mainAxisSize: fillChartHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Brand.black,
                  ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            chartSlot,
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
  final void Function(String domain, int score)? onDomainTap;

  const _DominioRadarChart({
    required this.data,
    required this.labelBuilder,
    this.onDomainTap,
  });

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
      onDomainTap: (index, _, value) {
        if (index < 0 || index >= data.dominios.length) return;
        onDomainTap?.call(data.dominios[index], value.round());
      },
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
  final void Function(String pilar, int score)? onPilarTap;

  const _PilarBarChart({
    required this.data,
    required this.labelBuilder,
    this.onPilarTap,
  });

  void _handleFallbackTap(Offset localPosition, Size size) {
    if (onPilarTap == null || data.pilars.isEmpty || size.width <= 0) return;
    final n = data.pilars.length;
    final rawIndex = ((localPosition.dx / size.width) * n).floor();
    final index = rawIndex.clamp(0, n - 1);
    final pilar = data.pilars[index];
    final score = (data.scoreByPilar[pilar] ?? 0).round();
    onPilarTap!(pilar, score);
  }

  Color _colorForPilar(String pilar) {
    final key = pilar.toLowerCase().trim();
    if (key.contains('compliance') || key.contains('conform')) {
      return const Color(0xFFF7675E);
    }
    if (key.contains('continuity') || key.contains('contin')) {
      return const Color(0xFF3366FF);
    }
    if (key.contains('control') || key.contains('controle')) {
      return Brand.controlPurple;
    }
    return Brand.accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    final items = <BarChartGroupData>[];
    for (var i = 0; i < data.pilars.length; i++) {
      final p = data.pilars[i];
      final color = _colorForPilar(p);
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
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.6),
                ],
              ),
            ),
          ],
          showingTooltipIndicators: const [0],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final chart = BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barTouchData: BarTouchData(
              touchCallback: (event, response) {
                if (onPilarTap == null) return;
                final isTapEvent =
                    event is FlTapDownEvent ||
                    event is FlTapUpEvent ||
                    event is FlLongPressStart ||
                    event is FlLongPressEnd;
                if (!isTapEvent) return;
                final spot = response?.spot;
                if (spot == null) return;
                final index = spot.touchedBarGroupIndex;
                if (index < 0 || index >= data.pilars.length) return;
                final pilar = data.pilars[index];
                final score = (data.scoreByPilar[pilar] ?? 0).round();
                onPilarTap!(pilar, score);
              },
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
                  showTitles: false,
                  reservedSize: 0,
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

        return MouseRegion(
          cursor: onPilarTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) => _handleFallbackTap(
              details.localPosition,
              Size(constraints.maxWidth, constraints.maxHeight),
            ),
            child: chart,
          ),
        );
      },
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
