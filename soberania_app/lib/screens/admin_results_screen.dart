import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/aws_norm_correlation.dart';
import '../models/models.dart';
import '../ui/brand.dart';
import '../widgets/custom_radar_chart.dart';

class AdminResultsScreen extends StatefulWidget {
  const AdminResultsScreen({
    super.key,
    required this.assessment,
    this.userName = '',
  });

  final Map<String, dynamic> assessment;
  final String userName;

  @override
  State<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _RoadmapStep {
  final String period;
  final String title;
  final String description;
  final String impact;

  const _RoadmapStep({
    required this.period,
    required this.title,
    required this.description,
    required this.impact,
  });
}

class _AdminResultsScreenState extends State<AdminResultsScreen> {
  bool _exportingPdf = false;

  static const _pilars = ['Compliance', 'Continuity', 'Control'];

  static const _pilarLabels = {
    'Compliance': 'Conformidade',
    'Continuity': 'Continuidade',
    'Control': 'Controle',
  };

  static const _scoreOrder = [
    'Não alinhado',
    'Pouco alinhado',
    'Parcialmente alinhado',
    'Bem alinhado',
    'Totalmente alinhado',
  ];

  // Ordem canônica dos domínios na matriz (para manter a tabela estável).
  static const _domainOrder = [
    'Soberania de Dados',
    'Soberania Operacional',
    'Soberania de Infraestrutura',
    'Soberania Organizacional',
    'Governança e Conformidade',
    'Continuidade e Portabilidade',
  ];

  static const _domainAliases = {
    'governanca e conformidade': 'Governança e Conformidade',
    'governan�a e conformidade': 'Governança e Conformidade',
    'soberania operacional': 'Soberania Operacional',
    'soberania de dados': 'Soberania de Dados',
    'soberania de infraestrutura': 'Soberania de Infraestrutura',
    'soberania organizacional': 'Soberania Organizacional',
    'continuidade e portabilidade': 'Continuidade e Portabilidade',
  };

  // Ordem canônica dos pilares técnicos (base: Assessment_OTIMIZADO_176).
  static const _technicalPilarOrder = [
    'Residência e Localização',
    'Restrição de Acesso',
    'Independência e Transparência',
    'Resiliência e Sobrevivência',
  ];

  static const _technicalPilarAliases = {
    'residência e localização': 'Residência e Localização',
    'residencia e localizacao': 'Residência e Localização',
    'resid�ncia e localiza��o': 'Residência e Localização',
    'restrição de acesso': 'Restrição de Acesso',
    'restricao de acesso': 'Restrição de Acesso',
    'restri��o de acesso': 'Restrição de Acesso',
    'independência e transparência': 'Independência e Transparência',
    'independencia e transparencia': 'Independência e Transparência',
    'independ�ncia e transpar�ncia': 'Independência e Transparência',
    'resiliência e sobrevivência': 'Resiliência e Sobrevivência',
    'resiliencia e sobrevivencia': 'Resiliência e Sobrevivência',
    'resili�ncia e sobreviv�ncia': 'Resiliência e Sobrevivência',
  };

  // Threshold abaixo do qual a resposta é considerada um "gap"
  // (Pouco alinhado, Parcialmente alinhado e Não alinhado).
  static const int _gapThreshold = 75;

  // Top N de serviços/normas exibidos por linha da matriz.
  static const int _topServices = 4;
  static const int _topNorms = 4;

  /// Divide uma string de itens separados por vírgula ou " · ".
  List<String> _splitItems(String? raw) {
    if (raw == null) return const [];
    final s = raw.replaceAll(' · ', ',').replaceAll('·', ',');
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Pega os top N itens por peso somado mantendo ordem por peso desc.
  List<String> _topItems(Map<String, double> weights, int n) {
    final entries = weights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).map((e) => e.key).toList();
  }

  /// Constrói dinamicamente a matriz de rastreabilidade a partir das respostas
  /// reais do cliente. Para cada domínio, identifica os "gaps" (perguntas com
  /// score < 75%) e agrega serviços AWS e normas/leis associados, ponderando
  /// cada item pelo peso do gap (5 - score/25). Domínios já maduros (sem
  /// perguntas-problema) recebem os serviços/normas mais comuns do domínio
  /// rotulados como "manutenção".
  ///
  /// As normas vindas do banco (`norms` / evidências da pergunta) são somadas
  /// às normas inferidas pela correlação serviço AWS → legislação/normas do
  /// protótipo (CSV matriz), para a coluna "Normas / Leis" refletir o mesmo
  /// racional do material de referência do projeto.
  List<Map<String, String>> _buildTraceability(List<dynamic> answers) {
    final byDomain = <String, List<Map<String, dynamic>>>{};
    for (final a in answers) {
      final m = a as Map<String, dynamic>;
      final dom = _normalizeDomain((m['dominio'] ?? '').toString());
      if (dom.isEmpty) continue;
      byDomain.putIfAbsent(dom, () => []).add(m);
    }

    // Fallback: se o backend vier sem `dominio`, usa agrupamento por pilar para
    // não perder a matriz final do PDF.
    if (byDomain.isEmpty) {
      for (final a in answers) {
        final m = a as Map<String, dynamic>;
        final pilar = (m['pilar'] ?? '').toString().trim();
        if (pilar.isEmpty) continue;
        final pseudoDomain = 'Pilar: ${_pilarLabels[pilar] ?? pilar}';
        byDomain.putIfAbsent(pseudoDomain, () => []).add(m);
      }
    }

    final domains = [..._domainOrder.where(byDomain.containsKey)];
    for (final d in byDomain.keys) {
      if (!domains.contains(d)) domains.add(d);
    }

    return domains.map((domain) {
      final domainAnswers = byDomain[domain]!;
      final problems = domainAnswers.where((m) {
        final s = scoreTextToPercent(m['score']?.toString());
        return s < _gapThreshold;
      }).toList();

      // Se não houver problemas, calculamos a recomendação para manutenção
      // a partir de todas as perguntas do domínio (peso = 1).
      final useAll = problems.isEmpty;
      final source = useAll ? domainAnswers : problems;

      final svcWeights = <String, double>{};
      final normWeights = <String, double>{};
      final pillars = <String>{};

      for (final m in source) {
        final pct = scoreTextToPercent(m['score']?.toString());
        // Peso vai de 1.0 (score 75) até 5.0 (score 0). Para useAll, peso 1.
        final w = useAll ? 1.0 : (5 - pct / 25).clamp(1, 5).toDouble();

        for (final svc in _splitItems(m['aws_service']?.toString())) {
          svcWeights[svc] = (svcWeights[svc] ?? 0) + w;
          for (final n in normsInferredFromAwsServiceToken(svc)) {
            normWeights[n] = (normWeights[n] ?? 0) + w;
          }
        }
        for (final n in _splitItems(m['norms']?.toString())) {
          normWeights[n] = (normWeights[n] ?? 0) + w;
        }
        final pt = (m['pilar_tecnico'] ?? '').toString().trim();
        if (pt.isNotEmpty) pillars.add(pt);
      }

      final topSvcs = _topItems(svcWeights, _topServices);
      final topNorms = _topItems(normWeights, _topNorms);

      final gap = useAll
          ? 'Manutenção — domínio maduro (${pillars.join(' · ')})'
          : (pillars.isEmpty
                ? 'Pontos a evoluir no domínio'
                : pillars.join(' · '));

      return {
        'domain': domain,
        'gap': gap,
        'technical': pillars.isEmpty ? '—' : pillars.join(' · '),
        'aws': topSvcs.isEmpty ? '—' : topSvcs.join(' · '),
        'norms': topNorms.isEmpty ? '—' : topNorms.join(' · '),
      };
    }).toList();
  }

  PdfColor _criticalityColor(double score) {
    if (score >= 75) return const PdfColor(0.18, 0.62, 0.36);
    if (score >= 50) return const PdfColor(0.31, 0.47, 0.65);
    if (score >= 25) return const PdfColor(0.95, 0.56, 0.17);
    return const PdfColor(0.89, 0.02, 0.07);
  }

  String _criticalityLabel(double score) {
    if (score >= 75) return 'Maduro';
    if (score >= 50) return 'Em evolução';
    if (score >= 25) return 'Crítico';
    return 'Urgente';
  }

  Map<String, double> _calcPilarScores(List<dynamic> answers) {
    final sums = <String, List<int>>{};
    for (final a in answers) {
      final pilar = (a as Map)['pilar']?.toString();
      final score = scoreTextToPercent(a['score']?.toString());
      if (pilar != null && pilar.isNotEmpty) {
        sums.putIfAbsent(pilar, () => []).add(score);
      }
    }
    return {
      for (final e in sums.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };
  }

  Map<String, double> _calcDominioScores(List<dynamic> answers) {
    final sums = <String, List<int>>{};
    for (final a in answers) {
      final m = a as Map;
      final dom = _normalizeDomain(m['dominio']?.toString() ?? '');
      final score = scoreTextToPercent(a['score']?.toString());
      if (dom.isNotEmpty) {
        sums.putIfAbsent(dom, () => []).add(score);
      }
    }

    // Fallback para manter o gráfico no PDF/admin caso `dominio` venha vazio.
    if (sums.isEmpty) {
      for (final a in answers) {
        final m = a as Map;
        final pilar = (m['pilar'] ?? '').toString().trim();
        if (pilar.isEmpty) continue;
        final key = 'Pilar: ${_pilarLabels[pilar] ?? pilar}';
        final score = scoreTextToPercent(m['score']?.toString());
        sums.putIfAbsent(key, () => []).add(score);
      }
    }

    return {
      for (final e in sums.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };
  }

  String _normalizeDomain(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final key = trimmed.toLowerCase();
    return _domainAliases[key] ?? trimmed;
  }

  List<MapEntry<String, double>> _orderedDomainEntries(
    Map<String, double> domainScores,
  ) {
    final ordered = <MapEntry<String, double>>[];
    for (final d in _domainOrder) {
      final v = domainScores[d];
      if (v != null) ordered.add(MapEntry(d, v));
    }
    for (final e in domainScores.entries) {
      if (!_domainOrder.contains(e.key)) ordered.add(e);
    }
    return ordered;
  }

  String _normalizeTechnicalPilar(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final key = trimmed.toLowerCase();
    if (_technicalPilarAliases.containsKey(key)) {
      return _technicalPilarAliases[key]!;
    }

    // Fallback resiliente para textos com encoding quebrado (mojibake).
    final compact = key.replaceAll(RegExp(r'[^a-z ]'), '');
    if (compact.contains('resid') && compact.contains('local')) {
      return 'Residência e Localização';
    }
    if (compact.contains('restr') && compact.contains('acess')) {
      return 'Restrição de Acesso';
    }
    if (compact.contains('independ') && compact.contains('transpar')) {
      return 'Independência e Transparência';
    }
    if (compact.contains('resilien') && compact.contains('sobreviv')) {
      return 'Resiliência e Sobrevivência';
    }

    return trimmed;
  }

  Map<String, double> _calcTechnicalPilarScores(List<dynamic> answers) {
    final sums = <String, List<int>>{};
    for (final a in answers) {
      final m = a as Map;
      final tech = _normalizeTechnicalPilar(
        m['pilar_tecnico']?.toString() ?? '',
      );
      final score = scoreTextToPercent(m['score']?.toString());
      if (tech.isNotEmpty) {
        sums.putIfAbsent(tech, () => []).add(score);
      }
    }
    return {
      for (final e in sums.entries)
        e.key: e.value.reduce((x, y) => x + y) / e.value.length,
    };
  }

  List<MapEntry<String, double>> _orderedTechnicalEntries(
    Map<String, double> technicalScores,
  ) {
    final ordered = <MapEntry<String, double>>[];
    for (final t in _technicalPilarOrder) {
      final v = technicalScores[t];
      if (v != null) ordered.add(MapEntry(t, v));
    }
    for (final e in technicalScores.entries) {
      if (!_technicalPilarOrder.contains(e.key)) ordered.add(e);
    }
    return ordered;
  }

  PdfColor _pdfBandColor(int pct) {
    if (pct >= 75) return const PdfColor(0.18, 0.62, 0.36);
    if (pct >= 50) return const PdfColor(0.31, 0.47, 0.65);
    return const PdfColor(0.95, 0.56, 0.17);
  }

  pw.Widget _pdfLinearScoreItem({required String label, required int pct}) {
    final barColor = _pdfBandColor(pct);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  label,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                '$pct%',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                flex: pct.clamp(1, 100),
                child: pw.Container(height: 8, color: barColor),
              ),
              if (pct < 100)
                pw.Expanded(
                  flex: (100 - pct).clamp(1, 99),
                  child: pw.Container(
                    height: 8,
                    color: const PdfColor(0.85, 0.85, 0.85),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _pilarColor(String pilar) {
    switch (pilar) {
      case 'Compliance':
        return const Color(0xFFF7675E);
      case 'Continuity':
        return Brand.accentBlue;
      case 'Control':
        return Brand.controlPurple;
      default:
        return Brand.accentBlue;
    }
  }

  PdfColor _pilarPdfColor(String pilar) {
    switch (pilar) {
      case 'Compliance':
        return const PdfColor(0.97, 0.40, 0.37);
      case 'Continuity':
        return const PdfColor(0.31, 0.47, 0.65);
      case 'Control':
        return const PdfColor(0.55, 0.36, 0.76);
      default:
        return const PdfColor(0.31, 0.47, 0.65);
    }
  }

  PdfColor _scorePdfColor(String score) {
    switch (score) {
      case 'Totalmente alinhado':
        return const PdfColor(0.18, 0.62, 0.36);
      case 'Bem alinhado':
        return const PdfColor(0.31, 0.47, 0.65);
      case 'Parcialmente alinhado':
        return const PdfColor(0.95, 0.56, 0.17);
      case 'Pouco alinhado':
        return const PdfColor(0.88, 0.36, 0.18);
      case 'Não alinhado':
        return const PdfColor(0.89, 0.02, 0.07);
      default:
        return PdfColors.grey;
    }
  }

  String _suggestAwsServiceForAnswer(Map<String, dynamic> answer) {
    final services = _splitItems(answer['aws_service']?.toString());
    if (services.isEmpty) return '—';
    final pct = scoreTextToPercent(answer['score']?.toString());
    final primary = pct < 50
        ? services.first
        : pct < 75
        ? services[services.length ~/ 2]
        : services.last;
    final secondary = services.firstWhere(
      (s) => s.trim().toLowerCase() != primary.trim().toLowerCase(),
      orElse: () => primary,
    );

    String actionFor(String service) {
      final s = service.toLowerCase();
      if (s.contains('cloudwatch')) {
        return 'ativar monitoramento e alertas';
      }
      if (s.contains('security hub') || s.contains('guardduty')) {
        return 'centralizar detecção e resposta';
      }
      if (s.contains('config') || s.contains('audit manager')) {
        return 'automatizar conformidade e auditoria';
      }
      if (s.contains('backup') || s.contains('disaster recovery')) {
        return 'implantar backup e recuperação';
      }
      if (s.contains('iam') || s.contains('identity center')) {
        return 'fortalecer identidade e acesso';
      }
      if (s.contains('kms')) {
        return 'padronizar criptografia e chaves';
      }
      if (s.contains('organizations') || s.contains('scp')) {
        return 'aplicar guardrails e politicas';
      }
      return 'padronizar operacao com automacao';
    }

    String impactFor(int scorePct) {
      if (scorePct < 50) {
        return 'reduzir incidentes e paradas';
      }
      if (scorePct < 75) {
        return 'aumentar previsibilidade e produtividade';
      }
      return 'escalar com resiliencia e menor custo';
    }

    final serviceLine =
        primary.trim().toLowerCase() == secondary.trim().toLowerCase()
        ? primary
        : '$primary + $secondary';
    return 'Usar: $serviceLine; '
        'acao: ${actionFor(primary)}; '
        'impacto: ${impactFor(pct)}.';
  }

  List<_RoadmapStep> _buildRoadmapSteps(
    Map<String, double> pilarScores,
    Map<String, double> domainScores,
  ) {
    final pilarEntries = pilarScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final domainEntries = domainScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    String pLabel(String raw) => _pilarLabels[raw] ?? raw;
    final weakPilar = pilarEntries.isNotEmpty
        ? pLabel(pilarEntries.first.key)
        : 'Pilar prioritário';
    final midPilar = pilarEntries.length > 1
        ? pLabel(pilarEntries[1].key)
        : weakPilar;
    final strongPilar = pilarEntries.isNotEmpty
        ? pLabel(pilarEntries.last.key)
        : weakPilar;
    final weakDomain = domainEntries.isNotEmpty
        ? domainEntries.first.key
        : 'domínio crítico';

    final weakScore = (pilarEntries.isNotEmpty ? pilarEntries.first.value : 50)
        .round();
    final midScore =
        (pilarEntries.length > 1
                ? pilarEntries[1].value
                : (pilarEntries.isNotEmpty ? pilarEntries.first.value : 55))
            .round();
    final strongScore = (pilarEntries.isNotEmpty ? pilarEntries.last.value : 60)
        .round();

    String gain(int currentScore) {
      final g = ((75 - currentScore).clamp(5, 30) / 3).round();
      return 'Ganho potencial: +$g pts';
    }

    return [
      _RoadmapStep(
        period: '0-30 dias',
        title: 'Estabilização imediata em $weakPilar',
        description:
            'Priorize ações rápidas para reduzir riscos no domínio mais crítico ($weakDomain) e aumentar a previsibilidade operacional.',
        impact: gain(weakScore),
      ),
      _RoadmapStep(
        period: '31-60 dias',
        title: 'Escalar controles em $midPilar',
        description:
            'Automatize monitoramento, evidências e processos para acelerar maturidade e reduzir esforço manual da operação.',
        impact: gain(midScore),
      ),
      _RoadmapStep(
        period: '61-90 dias',
        title: 'Otimizar valor de negócio com $strongPilar',
        description:
            'Consolidar boas práticas e expandir iniciativas para inovação, resiliência e vantagem competitiva sustentável.',
        impact: gain(strongScore),
      ),
    ];
  }

  Future<void> _exportPdf(
    List<dynamic> answers,
    Map<String, double> pilarScores,
    Map<String, double> dominioScores,
  ) async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      await ensureAwsNormTruthLoaded();
      final doc = pw.Document();
      final userName = widget.userName;
      final technicalScores = _calcTechnicalPilarScores(answers);
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final includeDetailedPages = true;

      // ════════════════════════════════════════════════════════════════════
      // FOLHA 1 — Scores + gráfico de barras desenhado + domínios
      // ════════════════════════════════════════════════════════════════════
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (ctx) {
            final dominioList = _orderedDomainEntries(dominioScores);
            final technicalList = _orderedTechnicalEntries(technicalScores);

            return pw.SizedBox(
              width: PdfPageFormat.a4.width,
              height: PdfPageFormat.a4.height,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // ── Cabeçalho (75pt) ──────────────────────────────────────
                  pw.Container(
                    height: 75,
                    color: const PdfColor(0.06, 0.06, 0.08),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Assessment de Soberania Digital',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              userName.isNotEmpty
                                  ? 'Cliente: $userName'
                                  : 'Relatório de Resultados',
                              style: const pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.grey400,
                              ),
                            ),
                          ],
                        ),
                        pw.Text(
                          dateStr,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 3 Cards de score (110pt) ──────────────────────────────
                  pw.Container(
                    height: 110,
                    color: const PdfColor(0.95, 0.95, 0.97),
                    padding: const pw.EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: pw.Row(
                      children: _pilars.map((p) {
                        final score = pilarScores[p] ?? 0;
                        final label = _pilarLabels[p] ?? p;
                        final c = _pilarPdfColor(p);
                        return pw.Expanded(
                          child: pw.Container(
                            margin: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            color: PdfColors.white,
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                              children: [
                                pw.Container(width: 5, color: c),
                                pw.Expanded(
                                  child: pw.Padding(
                                    padding: const pw.EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      12,
                                      10,
                                    ),
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.center,
                                      children: [
                                        pw.Text(
                                          label,
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            color: c,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 4),
                                        pw.Text(
                                          '${score.round()}%',
                                          style: pw.TextStyle(
                                            fontSize: 28,
                                            fontWeight: pw.FontWeight.bold,
                                            color: c,
                                          ),
                                        ),
                                        pw.SizedBox(height: 6),
                                        pw.Row(
                                          children: [
                                            pw.Expanded(
                                              flex: score.round().clamp(1, 100),
                                              child: pw.Container(
                                                height: 6,
                                                color: c,
                                              ),
                                            ),
                                            if (score.round() < 100)
                                              pw.Expanded(
                                                flex: (100 - score.round())
                                                    .clamp(1, 99),
                                                child: pw.Container(
                                                  height: 6,
                                                  color: PdfColor(
                                                    c.red,
                                                    c.green,
                                                    c.blue,
                                                    0.15,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Gráfico de barras (260pt) ─────────────────────────────
                  pw.Container(
                    height: 260,
                    color: PdfColors.white,
                    padding: const pw.EdgeInsets.fromLTRB(48, 18, 48, 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Text(
                          'Score por Pilar',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 14),
                        pw.SizedBox(
                          height: 180,
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                            children: _pilars.map((p) {
                              final score = pilarScores[p] ?? 0;
                              final label = _pilarLabels[p] ?? p;
                              final c = _pilarPdfColor(p);
                              final barH = 130 * (score / 100);
                              return pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    color: const PdfColor(0, 0, 0),
                                    child: pw.Text(
                                      '${score.round()}%',
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.white,
                                      ),
                                    ),
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Container(
                                    width: 70,
                                    height: barH,
                                    color: c,
                                  ),
                                  pw.SizedBox(height: 6),
                                  pw.Text(
                                    label,
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: c,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(height: 1, color: PdfColors.grey400),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: ['0%', '25%', '50%', '75%', '100%']
                              .map(
                                (l) => pw.Text(
                                  l,
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey500,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  // ── Score por domínio + pilar técnico (368pt) ─────────────
                  pw.Container(
                    height: 368,
                    color: const PdfColor(0.95, 0.95, 0.97),
                    padding: const pw.EdgeInsets.fromLTRB(32, 16, 32, 16),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Score por Domínio',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey800,
                                ),
                              ),
                              pw.SizedBox(height: 12),
                              if (dominioList.isEmpty)
                                pw.Text(
                                  'Sem dados de domínio',
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey500,
                                  ),
                                )
                              else
                                ...dominioList.map(
                                  (e) => _pdfLinearScoreItem(
                                    label: e.key,
                                    pct: e.value.round(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Score por Pilar Técnico',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey800,
                                ),
                              ),
                              pw.SizedBox(height: 12),
                              if (technicalList.isEmpty)
                                pw.Text(
                                  'Sem dados de pilar técnico',
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey500,
                                  ),
                                )
                              else
                                ...technicalList.map(
                                  (e) => _pdfLinearScoreItem(
                                    label: e.key,
                                    pct: e.value.round(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Rodapé (28pt) ─────────────────────────────────────────
                  pw.Container(
                    height: 28,
                    color: const PdfColor(0.06, 0.06, 0.08),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 32),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Soberania Digital — Assessment Report'
                          '${userName.isNotEmpty ? "  |  $userName" : ""}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey500,
                          ),
                        ),
                        pw.Text(
                          includeDetailedPages
                              ? 'Página 1 de 5'
                              : 'Página 1 de 1',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      if (includeDetailedPages) {
        // ════════════════════════════════════════════════════════════════════
        // FOLHAS 2, 3, 4 — Uma por pilar, tabela que preenche a página inteira
        // ════════════════════════════════════════════════════════════════════
        for (var pi = 0; pi < _pilars.length; pi++) {
          final pilar = _pilars[pi];
          final pilarAnswers = answers
              .where((a) => (a as Map)['pilar']?.toString() == pilar)
              .map((a) => Map<String, dynamic>.from(a as Map))
              .toList();

          final label = _pilarLabels[pilar] ?? pilar;
          final pilarColor = _pilarPdfColor(pilar);
          final score = pilarScores[pilar] ?? 0;
          final pageNum = pi + 2;

          final counts = <String, int>{};
          for (final a in pilarAnswers) {
            final s = a['score']?.toString() ?? '';
            if (s.isNotEmpty) counts[s] = (counts[s] ?? 0) + 1;
          }

          // Calcula a altura exata de cada linha para preencher a página
          const pageH = 841.89; // A4 em pontos
          const headerH = 90.0;
          const tblHdrH = 26.0;
          const footerH = 28.0;
          final dataH = pageH - headerH - tblHdrH - footerH;
          final rowH = pilarAnswers.isEmpty
              ? 20.0
              : dataH / pilarAnswers.length;

          doc.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.zero,
              build: (ctx) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // ── Cabeçalho colorido ──────────────────────────────────────
                  pw.Container(
                    height: headerH,
                    color: pilarColor,
                    padding: const pw.EdgeInsets.fromLTRB(28, 16, 28, 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              label,
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(24),
                              ),
                              child: pw.Text(
                                '${score.round()}%',
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: pilarColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          children: _scoreOrder.reversed
                              .where((s) => (counts[s] ?? 0) > 0)
                              .map(
                                (s) => pw.Container(
                                  margin: const pw.EdgeInsets.only(right: 6),
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.white,
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Text(
                                    '$s: ${counts[s]}',
                                    style: pw.TextStyle(
                                      fontSize: 7.5,
                                      color: _scorePdfColor(s),
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  // ── Cabeçalho da tabela ─────────────────────────────────────
                  pw.Container(
                    height: tblHdrH,
                    color: const PdfColor(0.18, 0.18, 0.22),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _tblHdrCell('Código', 42),
                        _tblHdrCell('Recomendação / Pergunta', 252),
                        _tblHdrCell('Serviço AWS Sugerido', 257),
                        _tblHdrCell('Score', 44),
                      ],
                    ),
                  ),

                  // ── Linhas de dados — preenchem EXATAMENTE o restante ───────
                  ...pilarAnswers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final a = entry.value;
                    final scoreVal = a['score']?.toString() ?? '—';
                    final suggestedService = _suggestAwsServiceForAnswer(a);
                    final sColor = _scorePdfColor(scoreVal);
                    final bg = idx.isEven
                        ? PdfColors.white
                        : const PdfColor(0.973, 0.973, 0.980);

                    return pw.Container(
                      height: rowH,
                      decoration: pw.BoxDecoration(
                        color: bg,
                        border: const pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.grey200,
                            width: 0.4,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          // Código
                          pw.Container(
                            width: 42,
                            alignment: pw.Alignment.center,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 3,
                            ),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                right: pw.BorderSide(
                                  color: PdfColors.grey200,
                                  width: 0.4,
                                ),
                              ),
                            ),
                            child: pw.Text(
                              a['question_code']?.toString() ?? '—',
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold,
                                color: pilarColor,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          // Recomendação
                          pw.Container(
                            width: 252,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                right: pw.BorderSide(
                                  color: PdfColors.grey200,
                                  width: 0.4,
                                ),
                              ),
                            ),
                            child: pw.Text(
                              a['recommendation']?.toString() ?? '—',
                              style: const pw.TextStyle(fontSize: 7.5),
                              maxLines: (rowH / 10).floor().clamp(1, 6),
                              overflow: pw.TextOverflow.clip,
                            ),
                          ),
                          // Serviço AWS sugerido (por desempenho da resposta)
                          pw.Container(
                            width: 257,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                right: pw.BorderSide(
                                  color: PdfColors.grey200,
                                  width: 0.4,
                                ),
                              ),
                            ),
                            child: pw.Text(
                              suggestedService,
                              style: pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey600,
                              ),
                              maxLines: (rowH / 9).floor().clamp(2, 8),
                              overflow: pw.TextOverflow.clip,
                            ),
                          ),
                          // Score label
                          pw.Container(
                            width: 44,
                            alignment: pw.Alignment.center,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 3,
                            ),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                right: pw.BorderSide(
                                  color: PdfColors.grey200,
                                  width: 0.4,
                                ),
                              ),
                            ),
                            child: pw.Text(
                              scoreVal,
                              style: pw.TextStyle(
                                fontSize: 6.5,
                                color: sColor,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // ── Rodapé ──────────────────────────────────────────────────
                  pw.Container(
                    height: footerH,
                    color: const PdfColor(0.06, 0.06, 0.08),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 28),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Soberania Digital — $label'
                          '${userName.isNotEmpty ? "  |  $userName" : ""}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey500,
                          ),
                        ),
                        pw.Text(
                          'Página $pageNum de 5',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ════════════════════════════════════════════════════════════════════
        // FOLHA 5 — Matriz de Rastreabilidade AWS (domínio → serviço → norma)
        // Construída dinamicamente a partir das respostas reais do cliente:
        // para cada domínio, agrega aws_service e norms (banco + correlação
        // CSV protótipo) das perguntas onde o score está abaixo do limiar (gaps).
        // ════════════════════════════════════════════════════════════════════
        final traceability = _buildTraceability(answers);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (ctx) {
              // Soma total = 595 (largura útil A4)
              const colDomain = 100.0;
              const colScore = 74.0;
              const colTechnical = 120.0;
              const colAws = 185.0;
              const colNorms = 116.0;

              const headerH = 80.0;
              const introH = 36.0;
              const tblHdrH = 32.0;
              const footerH = 28.0;
              final rowsCount = traceability.length;
              final rowH = rowsCount == 0
                  ? 0.0
                  : (PdfPageFormat.a4.height -
                            headerH -
                            introH -
                            tblHdrH -
                            footerH) /
                        rowsCount;

              return pw.SizedBox(
                width: PdfPageFormat.a4.width,
                height: PdfPageFormat.a4.height,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // ── Cabeçalho ─────────────────────────────────────────────
                    pw.Container(
                      height: headerH,
                      color: const PdfColor(0.06, 0.06, 0.08),
                      padding: const pw.EdgeInsets.fromLTRB(28, 14, 28, 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Matriz de Rastreabilidade AWS',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Mapeamento entre o resultado do assessment, '
                            'serviços AWS recomendados e normas/leis aplicáveis.',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Intro/legenda ─────────────────────────────────────────
                    pw.Container(
                      height: introH,
                      color: const PdfColor(0.96, 0.96, 0.97),
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 8,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            'Criticidade:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          ...[
                            ['Urgente < 25%', const PdfColor(0.89, 0.02, 0.07)],
                            [
                              'Crítico 25-49%',
                              const PdfColor(0.95, 0.56, 0.17),
                            ],
                            [
                              'Em evolução 50-74%',
                              const PdfColor(0.31, 0.47, 0.65),
                            ],
                            ['Maduro >= 75%', const PdfColor(0.18, 0.62, 0.36)],
                          ].map((item) {
                            final txt = item[0] as String;
                            final col = item[1] as PdfColor;
                            return pw.Container(
                              margin: const pw.EdgeInsets.only(right: 10),
                              child: pw.Row(
                                children: [
                                  pw.Container(
                                    width: 9,
                                    height: 9,
                                    decoration: pw.BoxDecoration(
                                      color: col,
                                      borderRadius: pw.BorderRadius.circular(2),
                                    ),
                                  ),
                                  pw.SizedBox(width: 4),
                                  pw.Text(
                                    txt,
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: col,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // ── Cabeçalho da tabela ───────────────────────────────────
                    pw.Container(
                      height: tblHdrH,
                      color: const PdfColor(0.18, 0.18, 0.22),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          _trcHdr('Domínio', colDomain),
                          _trcHdr('Maturidade', colScore),
                          _trcHdr('Pilar Técnico AWS', colTechnical),
                          _trcHdr('Serviços AWS Recomendados', colAws),
                          _trcHdr('Normas / Leis', colNorms),
                        ],
                      ),
                    ),

                    // ── Linhas da matriz ──────────────────────────────────────
                    ...traceability.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final domain = item['domain']!;
                      final score = dominioScores[domain] ?? 0;
                      final critColor = _criticalityColor(score);
                      final critLabel = _criticalityLabel(score);
                      final bg = idx.isEven
                          ? PdfColors.white
                          : const PdfColor(0.973, 0.973, 0.980);

                      return pw.Container(
                        height: rowH,
                        decoration: pw.BoxDecoration(
                          color: bg,
                          border: const pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey200,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            // Domínio (com barra colorida lateral)
                            pw.Container(
                              width: colDomain,
                              padding: const pw.EdgeInsets.fromLTRB(8, 8, 6, 8),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  left: pw.BorderSide(
                                    color: critColor,
                                    width: 4,
                                  ),
                                  right: const pw.BorderSide(
                                    color: PdfColors.grey200,
                                    width: 0.4,
                                  ),
                                ),
                              ),
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    domain,
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.grey900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Score / Criticidade
                            pw.Container(
                              width: colScore,
                              padding: const pw.EdgeInsets.all(6),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  right: pw.BorderSide(
                                    color: PdfColors.grey200,
                                    width: 0.4,
                                  ),
                                ),
                              ),
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    '${score.round()}%',
                                    style: pw.TextStyle(
                                      fontSize: 18,
                                      fontWeight: pw.FontWeight.bold,
                                      color: critColor,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.SizedBox(height: 3),
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: pw.BoxDecoration(
                                      color: PdfColor(
                                        critColor.red,
                                        critColor.green,
                                        critColor.blue,
                                        0.15,
                                      ),
                                      borderRadius: pw.BorderRadius.circular(3),
                                    ),
                                    child: pw.Text(
                                      critLabel,
                                      style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: critColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Pilar Técnico AWS
                            pw.Container(
                              width: colTechnical,
                              padding: const pw.EdgeInsets.all(8),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  right: pw.BorderSide(
                                    color: PdfColors.grey200,
                                    width: 0.4,
                                  ),
                                ),
                              ),
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    item['technical'] ?? '—',
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      color: PdfColors.grey800,
                                      fontStyle: pw.FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Serviços AWS
                            pw.Container(
                              width: colAws,
                              padding: const pw.EdgeInsets.all(8),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  right: pw.BorderSide(
                                    color: PdfColors.grey200,
                                    width: 0.4,
                                  ),
                                ),
                              ),
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    children: [
                                      pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: pw.BoxDecoration(
                                          color: const PdfColor(1.0, 0.60, 0.0),
                                          borderRadius:
                                              pw.BorderRadius.circular(3),
                                        ),
                                        child: pw.Text(
                                          'AWS',
                                          style: pw.TextStyle(
                                            fontSize: 7,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    item['aws']!,
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: PdfColors.grey900,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Normas / Leis
                            pw.Container(
                              width: colNorms,
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    children: [
                                      pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: pw.BoxDecoration(
                                          color: const PdfColor(
                                            0.20,
                                            0.20,
                                            0.25,
                                          ),
                                          borderRadius:
                                              pw.BorderRadius.circular(3),
                                        ),
                                        child: pw.Text(
                                          'NORMAS',
                                          style: pw.TextStyle(
                                            fontSize: 7,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    item['norms']!,
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // ── Rodapé ────────────────────────────────────────────────
                    pw.Container(
                      height: footerH,
                      color: const PdfColor(0.06, 0.06, 0.08),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 28),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text(
                                  'Soberania Digital — Matriz AWS'
                                  '${userName.isNotEmpty ? "  |  $userName" : ""}',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey500,
                                  ),
                                ),
                                if (awsNormTruthPdfFooterLine != null &&
                                    awsNormTruthPdfFooterLine!
                                        .trim()
                                        .isNotEmpty)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 2),
                                    child: pw.Text(
                                      awsNormTruthPdfFooterLine!.trim(),
                                      maxLines: 2,
                                      style: const pw.TextStyle(
                                        fontSize: 7,
                                        color: PdfColors.grey600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          pw.Text(
                            'Página 5 de 5',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      final bytes = await doc.save();
      final safeName = userName.isNotEmpty
          ? userName.replaceAll(RegExp(r'[^\w]'), '_')
          : 'cliente';
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'resultados_soberania_$safeName.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  pw.Widget _trcHdr(String text, double width) {
    return pw.Container(
      width: width,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          right: pw.BorderSide(color: PdfColor(1, 1, 1, 0.15), width: 0.5),
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
        maxLines: 2,
      ),
    );
  }

  pw.Widget _tblHdrCell(String text, double width) {
    return pw.Container(
      width: width,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          right: pw.BorderSide(color: PdfColor(1, 1, 1, 0.15), width: 0.5),
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
        maxLines: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answers = (widget.assessment['answers'] as List<dynamic>?) ?? [];
    final pilarScores = _calcPilarScores(answers);
    final dominioScores = _calcDominioScores(answers);
    final dominioKeys = dominioScores.keys.toList()..sort();
    final roadmapSteps = _buildRoadmapSteps(pilarScores, dominioScores);

    final subtitle = widget.userName.isNotEmpty
        ? 'Resultados de ${widget.userName}'
        : null;

    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(
        context,
        title: 'Resultados do Assessment',
        subtitle: subtitle,
        showBack: true,
        compactTrailingActions: true,
        actionsPadding: const EdgeInsetsDirectional.only(end: 6, start: 4),
        trailing: Tooltip(
          message: 'Gerar PDF',
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
              onPressed: _exportingPdf
                  ? null
                  : () => _exportPdf(answers, pilarScores, dominioScores),
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
              label: const Text(
                'GERAR PDF',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
      body: answers.isEmpty
          ? const Center(
              child: Text(
                'Sem respostas para exibir resultados.',
                style: TextStyle(color: Colors.black45),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Score chips ──────────────────────────────────────────
                  _ScoreChipsRow(
                    pilars: _pilars,
                    pilarScores: pilarScores,
                    pilarLabels: _pilarLabels,
                    pilarColor: _pilarColor,
                  ),
                  const SizedBox(height: 20),
                  // ── Gráficos ─────────────────────────────────────────────
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final wide = constraints.maxWidth >= 640;

                      final barCard = _ChartCard(
                        title: 'Score por Pilar',
                        height: wide ? null : 300,
                        child: _PilarBarChart(
                          pilars: _pilars,
                          pilarScores: pilarScores,
                          pilarLabels: _pilarLabels,
                          pilarColor: _pilarColor,
                        ),
                      );

                      final radarCard = _ChartCard(
                        title: 'Score por Domínio',
                        height: wide ? null : 360,
                        child: dominioKeys.isNotEmpty
                            ? CustomRadarChart(
                                labels: dominioKeys,
                                values: dominioKeys
                                    .map((k) => dominioScores[k] ?? 0)
                                    .toList(),
                                fillColor: Brand.accentBlue,
                                borderColor: Brand.accentRed,
                                gridColor: Brand.border,
                                textColor: Brand.black,
                              )
                            : const Center(
                                child: Text(
                                  'Sem dados de domínio',
                                  style: TextStyle(color: Colors.black38),
                                ),
                              ),
                      );

                      if (wide) {
                        return SizedBox(
                          height: 440,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: barCard),
                              const SizedBox(width: 16),
                              Expanded(child: radarCard),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: [
                          barCard,
                          const SizedBox(height: 16),
                          radarCard,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _RoadmapTimelineCard(
                    title: 'Cronograma de Evolução da Soberania Digital',
                    subtitle:
                        'Plano de 90 dias para aumentar potencial e maturidade com base nos resultados atuais do assessment.',
                    steps: roadmapSteps,
                  ),
                  const SizedBox(height: 28),
                  // ── Análise completa por pilar ────────────────────────────
                  const _SectionHeader(title: 'Análise Completa das Respostas'),
                  const SizedBox(height: 12),
                  ..._pilars.map((pilar) {
                    final pilarAnswers = answers
                        .where((a) => (a as Map)['pilar']?.toString() == pilar)
                        .map((a) => Map<String, dynamic>.from(a as Map))
                        .toList();
                    return _PilarAnalysisCard(
                      pilar: pilar,
                      label: _pilarLabels[pilar] ?? pilar,
                      color: _pilarColor(pilar),
                      score: pilarScores[pilar],
                      answers: pilarAnswers,
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ── Chips de resumo ─────────────────────────────────────────────────────────

class _ScoreChipsRow extends StatelessWidget {
  const _ScoreChipsRow({
    required this.pilars,
    required this.pilarScores,
    required this.pilarLabels,
    required this.pilarColor,
  });

  final List<String> pilars;
  final Map<String, double> pilarScores;
  final Map<String, String> pilarLabels;
  final Color Function(String) pilarColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: pilars.map((p) {
        final score = pilarScores[p];
        if (score == null) return const SizedBox.shrink();
        final color = pilarColor(p);
        final label = pilarLabels[p] ?? p;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${score.round()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Card de gráfico ─────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.height});

  final String title;
  final Widget child;
  final double? height;

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
          mainAxisSize: height == null ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 16),
            height != null
                ? SizedBox(height: height, child: child)
                : Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _RoadmapTimelineCard extends StatelessWidget {
  const _RoadmapTimelineCard({
    required this.title,
    required this.subtitle,
    required this.steps,
  });

  final String title;
  final String subtitle;
  final List<_RoadmapStep> steps;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Brand.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            ...steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              final isLast = idx == steps.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 36,
                      child: Column(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Brand.assessmentCtaBlue,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: Brand.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 54,
                              margin: const EdgeInsets.only(top: 4),
                              color: Brand.border,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: Brand.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Brand.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.period,
                              style: const TextStyle(
                                color: Brand.assessmentCtaBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Brand.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step.description,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Gráfico de barras ────────────────────────────────────────────────────────

class _PilarBarChart extends StatelessWidget {
  const _PilarBarChart({
    required this.pilars,
    required this.pilarScores,
    required this.pilarLabels,
    required this.pilarColor,
  });

  final List<String> pilars;
  final Map<String, double> pilarScores;
  final Map<String, String> pilarLabels;
  final Color Function(String) pilarColor;

  @override
  Widget build(BuildContext context) {
    final ordered = pilars.where(pilarScores.containsKey).toList();
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < ordered.length; i++) {
      final p = ordered[i];
      final color = pilarColor(p);
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: pilarScores[p]!,
              width: 36,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
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

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Brand.black,
            getTooltipItem: (group, _, rod, __) {
              final label = pilarLabels[ordered[group.x]] ?? ordered[group.x];
              return BarTooltipItem(
                '$label\n${rod.toY.toInt()}%',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}%',
                style: const TextStyle(
                  fontSize: 10,
                  color: Brand.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Brand.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: bars,
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

// ── Cabeçalho de seção ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ── Card de análise por pilar ────────────────────────────────────────────────

class _PilarAnalysisCard extends StatefulWidget {
  const _PilarAnalysisCard({
    required this.pilar,
    required this.label,
    required this.color,
    required this.answers,
    this.score,
  });

  final String pilar;
  final String label;
  final Color color;
  final List<Map<String, dynamic>> answers;
  final double? score;

  @override
  State<_PilarAnalysisCard> createState() => _PilarAnalysisCardState();
}

class _PilarAnalysisCardState extends State<_PilarAnalysisCard> {
  bool _expanded = false;

  static const _scoreColors = {
    'Totalmente alinhado': Color(0xFF2E9E5B),
    'Bem alinhado': Color(0xFF4E79A7),
    'Parcialmente alinhado': Color(0xFFF28E2B),
    'Pouco alinhado': Color(0xFFE05C2F),
    'Não alinhado': Color(0xFFE30613),
  };

  static const _scoreOrder = [
    'Não alinhado',
    'Pouco alinhado',
    'Parcialmente alinhado',
    'Bem alinhado',
    'Totalmente alinhado',
  ];

  Map<String, int> _countByScore() {
    final counts = <String, int>{};
    for (final a in widget.answers) {
      final s = a['score']?.toString() ?? '';
      if (s.isNotEmpty) counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _countByScore();
    final total = widget.answers.length;
    final scoreLabel = widget.score != null ? '${widget.score!.round()}%' : '—';

    return Card(
      elevation: 0,
      color: Brand.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: widget.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Cabeçalho clicável
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + score + seta
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: widget.color,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.color.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          scoreLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: widget.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barra de distribuição de scores
                  _ScoreDistributionBar(
                    counts: counts,
                    total: total,
                    scoreOrder: _scoreOrder,
                    scoreColors: _scoreColors,
                  ),
                  const SizedBox(height: 10),
                  // Legenda resumida
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: _scoreOrder.reversed
                        .where((s) => (counts[s] ?? 0) > 0)
                        .map((s) {
                          final c = _scoreColors[s] ?? Colors.grey;
                          final n = counts[s] ?? 0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$s ($n)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        })
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          // Respostas detalhadas (expandido)
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.answers.map(
              (a) => _AnalysisAnswerRow(
                answer: a,
                color: widget.color,
                scoreColors: _scoreColors,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Barra de distribuição de scores ──────────────────────────────────────────

class _ScoreDistributionBar extends StatelessWidget {
  const _ScoreDistributionBar({
    required this.counts,
    required this.total,
    required this.scoreOrder,
    required this.scoreColors,
  });

  final Map<String, int> counts;
  final int total;
  final List<String> scoreOrder;
  final Map<String, Color> scoreColors;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: scoreOrder.map((s) {
            final n = counts[s] ?? 0;
            if (n == 0) return const SizedBox.shrink();
            return Expanded(
              flex: n,
              child: Container(color: scoreColors[s] ?? Colors.grey),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Linha de resposta individual ─────────────────────────────────────────────

class _AnalysisAnswerRow extends StatelessWidget {
  const _AnalysisAnswerRow({
    required this.answer,
    required this.color,
    required this.scoreColors,
  });

  final Map<String, dynamic> answer;
  final Color color;
  final Map<String, Color> scoreColors;

  @override
  Widget build(BuildContext context) {
    final code = answer['question_code']?.toString() ?? '—';
    final recommendation = answer['recommendation']?.toString() ?? '—';
    final score = answer['score']?.toString() ?? '—';
    final justification = answer['justification']?.toString() ?? '';
    final dominio = answer['dominio']?.toString() ?? '';
    final scoreColor = scoreColors[score] ?? Colors.black38;
    final pct = scoreTextToPercent(score);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Código
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (dominio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dominio,
                    style: const TextStyle(fontSize: 9, color: Colors.black38),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Recomendação + justificativa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation,
                  style: const TextStyle(fontSize: 12, height: 1.45),
                ),
                if (justification.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Justificativa: $justification',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Score badge + percentual
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  score,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
