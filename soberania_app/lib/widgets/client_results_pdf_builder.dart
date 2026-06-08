import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// PDF do cliente: folha 1 = resultados; folha 2 = cronograma Gantt.
class ClientResultsPdfBuilder {
  ClientResultsPdfBuilder({
    required this.userName,
    required this.dateStr,
    required this.pilarOrder,
    required this.pilarLabels,
    required this.pilarScores,
    required this.domainEntries,
    required this.technicalEntries,
    required this.roadmapImage,
    required this.roadmapTitle,
    required this.languageCode,
  });

  final String userName;
  final String dateStr;
  final List<String> pilarOrder;
  final Map<String, String> pilarLabels;
  final Map<String, int> pilarScores;
  final List<MapEntry<String, int>> domainEntries;
  final List<MapEntry<String, int>> technicalEntries;
  final pw.MemoryImage? roadmapImage;
  final String roadmapTitle;
  final String languageCode;

  bool get _hasRoadmap => roadmapImage != null;
  int get totalPages => _hasRoadmap ? 2 : 1;

  PdfColor _pilarColor(String pilar) {
    switch (pilar.trim().toLowerCase()) {
      case 'compliance':
        return const PdfColor(0.98, 0.40, 0.38);
      case 'continuity':
        return const PdfColor(0.29, 0.49, 0.70);
      case 'control':
        return const PdfColor(0.53, 0.39, 0.84);
      default:
        return const PdfColor(0.29, 0.49, 0.70);
    }
  }

  PdfColor _bandColor(int pct) {
    if (pct >= 75) return const PdfColor(0.18, 0.62, 0.36);
    if (pct >= 50) return const PdfColor(0.29, 0.49, 0.70);
    return const PdfColor(0.95, 0.56, 0.17);
  }

  String _pageLabel(int page) {
    if (languageCode == 'en') return 'Page $page of $totalPages';
    if (languageCode == 'es') return 'Página $page de $totalPages';
    return 'Página $page de $totalPages';
  }

  String _reportFooterLine() {
    if (languageCode == 'en') {
      return userName.isNotEmpty
          ? 'Digital Sovereignty Assessment Report | $userName'
          : 'Digital Sovereignty Assessment Report';
    }
    if (languageCode == 'es') {
      return userName.isNotEmpty
          ? 'Informe de Assessment de Soberanía Digital | $userName'
          : 'Informe de Assessment de Soberanía Digital';
    }
    return userName.isNotEmpty
        ? 'Soberania Digital Assessment Report | $userName'
        : 'Soberania Digital Assessment Report';
  }

  pw.Widget _footer(int page) {
    return pw.Container(
      height: 24,
      color: const PdfColor(0.06, 0.06, 0.08),
      padding: const pw.EdgeInsets.symmetric(horizontal: 28),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _reportFooterLine(),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            _pageLabel(page),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  ({String sovereigntyTitle, String sovereigntyBody, String threeCsTitle})
  _conceptCopy() {
    if (languageCode == 'en') {
      return (
        sovereigntyTitle: 'What is Digital Sovereignty?',
        sovereigntyBody:
            'A structured assessment of control, compliance, resilience and independence '
            'in your digital operation — with objective, measurable criteria to identify gaps '
            'and define evolution priorities.',
        threeCsTitle: 'The 3 Cs framework',
      );
    }
    if (languageCode == 'es') {
      return (
        sovereigntyTitle: '¿Qué es la Soberanía Digital?',
        sovereigntyBody:
            'Evaluación estructurada del nivel de control, conformidad, resiliencia e '
            'independencia de su operación digital, con criterios objetivos y medibles para '
            'identificar brechas y prioridades de evolución.',
        threeCsTitle: 'Los 3 Cs del framework',
      );
    }
    return (
      sovereigntyTitle: 'O que é Soberania Digital?',
      sovereigntyBody:
          'Avaliação estruturada do nível de controle, conformidade, resiliência e '
          'independência da operação digital, com critérios objetivos e mensuráveis para '
          'identificar lacunas e prioridades de evolução.',
      threeCsTitle: 'Os 3 Cs da metodologia',
    );
  }

  String _cDescription(String pilar) {
    switch (pilar.trim().toLowerCase()) {
      case 'compliance':
        if (languageCode == 'en') {
          return 'Compliance with laws, standards and security requirements.';
        }
        if (languageCode == 'es') {
          return 'Conformidad con leyes, normas y estándares de seguridad.';
        }
        return 'Conformidade com leis, normas e padrões de segurança.';
      case 'control':
        if (languageCode == 'en') {
          return 'Control over infrastructure, access and critical data.';
        }
        if (languageCode == 'es') {
          return 'Control sobre infraestructura, accesos y datos críticos.';
        }
        return 'Controle sobre infraestrutura, acessos e dados críticos.';
      case 'continuity':
        if (languageCode == 'en') {
          return 'Ability to respond and recover from failures and crises.';
        }
        if (languageCode == 'es') {
          return 'Capacidad de responder y recuperarse ante fallas y crisis.';
        }
        return 'Capacidade de responder e recuperar diante de falhas e crises.';
      default:
        return '';
    }
  }

  pw.Widget _cPillarColumn(String pilarKey) {
    final c = _pilarColor(pilarKey);
    final label = pilarLabels[pilarKey] ?? pilarKey;
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 6),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: const PdfColor(0.88, 0.88, 0.90), width: 0.5),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              height: 4,
              decoration: pw.BoxDecoration(
                color: c,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(4),
                  topRight: pw.Radius.circular(4),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(7, 5, 7, 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    label,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: c,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    _cDescription(pilarKey),
                    maxLines: 3,
                    style: const pw.TextStyle(
                      fontSize: 7.2,
                      height: 1.3,
                      color: PdfColors.grey700,
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

  pw.Widget _buildConceptSection() {
    final copy = _conceptCopy();
    return pw.Container(
      height: 148,
      color: PdfColors.white,
      padding: const pw.EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.96, 0.97, 0.99),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: const PdfColor(0.82, 0.86, 0.92),
                  width: 0.6,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    copy.sovereigntyTitle,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Expanded(
                    child: pw.Text(
                      copy.sovereigntyBody,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        height: 1.35,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            flex: 7,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  copy.threeCsTitle,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: pilarOrder.map(_cPillarColumn).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _horizontalBarChart(String label, int pct) {
    final clamped = pct.clamp(0, 100);
    final c = _bandColor(clamped);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  label,
                  maxLines: 2,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                '$clamped%',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: c,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            height: 9,
            decoration: pw.BoxDecoration(
              color: const PdfColor(0.90, 0.90, 0.92),
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 2,
              verticalRadius: 2,
              child: pw.Row(
                children: [
                  if (clamped > 0)
                    pw.Expanded(
                      flex: clamped,
                      child: pw.Container(color: c),
                    ),
                  if (clamped < 100)
                    pw.Expanded(
                      flex: (100 - clamped).clamp(1, 100),
                      child: pw.SizedBox(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Page _buildPage1() {
    final clientLine = userName.isNotEmpty
        ? 'Cliente: $userName'
        : 'Relatório de Resultados';
    final domainTitle = languageCode == 'en'
        ? 'Score by Domain'
        : languageCode == 'es'
        ? 'Score por Dominio'
        : 'Score por Domínio';
    final technicalTitle = languageCode == 'en'
        ? 'Score by Technical Pillar'
        : languageCode == 'es'
        ? 'Score por Pilar Técnico'
        : 'Score por Pilar Técnico';
    final noTechnicalData = languageCode == 'en'
        ? 'No technical pillar data'
        : languageCode == 'es'
        ? 'Sin datos de pilar técnico'
        : 'Sem dados de pilar técnico';

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) {
        return pw.SizedBox(
          width: PdfPageFormat.a4.width,
          height: PdfPageFormat.a4.height,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                height: 72,
                color: const PdfColor(0.06, 0.06, 0.08),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
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
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          clientLine,
                          style: const pw.TextStyle(
                            fontSize: 10,
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
              _buildConceptSection(),
              pw.Container(
                height: 95,
                color: const PdfColor(0.95, 0.95, 0.97),
                padding: const pw.EdgeInsets.fromLTRB(18, 10, 18, 10),
                child: pw.Row(
                  children: pilarOrder.map((p) {
                    final score = (pilarScores[p] ?? 0).round();
                    final c = _pilarColor(p);
                    final label = pilarLabels[p] ?? p;
                    return pw.Expanded(
                      child: pw.Container(
                        margin: const pw.EdgeInsets.symmetric(horizontal: 5),
                        color: PdfColors.white,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.Container(width: 5, color: c),
                            pw.Expanded(
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.fromLTRB(
                                  10,
                                  6,
                                  10,
                                  6,
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  mainAxisAlignment: pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(
                                      label,
                                      style: pw.TextStyle(
                                        fontSize: 9.5,
                                        color: c,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.SizedBox(height: 2),
                                    pw.Text(
                                      '$score%',
                                      style: pw.TextStyle(
                                        fontSize: 24,
                                        fontWeight: pw.FontWeight.bold,
                                        color: c,
                                      ),
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
              pw.Container(
                height: 195,
                color: PdfColors.white,
                padding: const pw.EdgeInsets.fromLTRB(40, 10, 40, 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(
                      languageCode == 'en'
                          ? 'Score by Pillar'
                          : 'Score por Pilar',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Expanded(
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: pilarOrder.map((p) {
                          final score = pilarScores[p] ?? 0;
                          final c = _pilarColor(p);
                          final label = pilarLabels[p] ?? p;
                          final barH = 120.0 * (score / 100);
                          return pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                color: PdfColors.black,
                                child: pw.Text(
                                  '$score%',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Container(
                                width: 64,
                                height: barH.clamp(4, 120),
                                color: c,
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                label,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: c,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    pw.Container(height: 1, color: PdfColors.grey400),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  color: const PdfColor(0.97, 0.97, 0.98),
                  padding: const pw.EdgeInsets.fromLTRB(24, 10, 24, 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              domainTitle,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            ...domainEntries.map(
                              (e) => _horizontalBarChart(e.key, e.value),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              technicalTitle,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            if (technicalEntries.isEmpty)
                              pw.Text(
                                noTechnicalData,
                                style: const pw.TextStyle(
                                  fontSize: 8.5,
                                  color: PdfColors.grey600,
                                ),
                              )
                            else
                              ...technicalEntries.map(
                                (e) => _horizontalBarChart(e.key, e.value),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _footer(1),
            ],
          ),
        );
      },
    );
  }

  pw.Page _buildPage2Roadmap() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) {
        return pw.SizedBox(
          width: PdfPageFormat.a4.width,
          height: PdfPageFormat.a4.height,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                height: 44,
                color: const PdfColor(0.06, 0.06, 0.08),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 8,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      roadmapTitle,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      _pageLabel(2),
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Align(
                  alignment: pw.Alignment.topCenter,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(6, 2, 6, 0),
                    child: pw.Image(
                      roadmapImage!,
                      fit: pw.BoxFit.fitWidth,
                      width: PdfPageFormat.a4.width - 12,
                    ),
                  ),
                ),
              ),
              _footer(2),
            ],
          ),
        );
      },
    );
  }

  void addPages(pw.Document doc) {
    doc.addPage(_buildPage1());
    if (_hasRoadmap) {
      doc.addPage(_buildPage2Roadmap());
    }
  }
}
