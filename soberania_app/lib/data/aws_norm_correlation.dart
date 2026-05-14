import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'aws_norm_correlation.g.dart';

/// Entradas do mapa gerado, da chave mais longa para a mais curta (melhor match primeiro).
final List<MapEntry<String, List<String>>> kAwsNormSortedEntries =
    kAwsServiceNormCorrelation.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

Map<String, List<String>>? _truthNormsByService;
List<MapEntry<String, List<String>>>? _truthNormSortedEntries;
String? awsNormTruthPdfFooterLine;

bool _truthLoadDone = false;
Future<void>? _truthLoadFuture;

/// Carrega [assets/data/aws_norms_truth.json] (opcional de conteúdo, mas o asset existe).
/// Chamado antes do PDF para normas oficiais sobrescreverem o mapa gerado do CSV.
Future<void> ensureAwsNormTruthLoaded() async {
  if (_truthLoadDone) return;
  _truthLoadFuture ??= _loadTruthAsset();
  await _truthLoadFuture;
  _truthLoadDone = true;
}

Future<void> _loadTruthAsset() async {
  _truthNormsByService = null;
  _truthNormSortedEntries = null;
  awsNormTruthPdfFooterLine = null;
  try {
    final raw = await rootBundle.loadString('assets/data/aws_norms_truth.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final serv = j['servicos'];
    if (serv is Map<String, dynamic> && serv.isNotEmpty) {
      final m = <String, List<String>>{};
      for (final e in serv.entries) {
        final key = e.key.trim();
        if (key.isEmpty) continue;
        final norms = _normasListFromTruthValue(e.value);
        if (norms.isNotEmpty) m[key] = norms;
      }
      if (m.isNotEmpty) {
        _truthNormsByService = m;
        _truthNormSortedEntries = m.entries.toList()
          ..sort((a, b) => b.key.length.compareTo(a.key.length));
      }
    }
    final nota = (j['nota_rodape_pdf'] as String?)?.trim();
    if (nota != null && nota.isNotEmpty) {
      awsNormTruthPdfFooterLine = nota;
    } else {
      final rev = (j['revisado_em'] as String?)?.trim() ?? '';
      final who = (j['revisor'] as String?)?.trim() ?? '';
      if (rev.isNotEmpty || who.isNotEmpty) {
        final buf = StringBuffer('Matriz jurídica revisada');
        if (rev.isNotEmpty) buf.write(' em $rev');
        if (who.isNotEmpty) buf.write(' — $who');
        buf.write('.');
        awsNormTruthPdfFooterLine = buf.toString();
      }
    }
  } catch (_) {
    _truthNormsByService = null;
    _truthNormSortedEntries = null;
    awsNormTruthPdfFooterLine = null;
  }
}

List<String> _normasListFromTruthValue(Object? value) {
  if (value is List) {
    return value.map((x) => x.toString().trim()).where((x) => x.isNotEmpty).toList();
  }
  if (value is Map<String, dynamic>) {
    final n = value['normas'];
    if (n is List) {
      return n.map((x) => x.toString().trim()).where((x) => x.isNotEmpty).toList();
    }
  }
  return const [];
}

List<String>? _lookupNormsForToken(
  Map<String, List<String>>? exactMap,
  List<MapEntry<String, List<String>>>? sorted,
  String t,
) {
  if (exactMap == null || sorted == null || exactMap.isEmpty) return null;
  final lower = t.toLowerCase();
  final direct = exactMap[t];
  if (direct != null && direct.isNotEmpty) return direct;

  for (final e in sorted) {
    final k = e.key.toLowerCase();
    if (k.isEmpty) continue;
    if (lower.contains(k)) return e.value;
  }
  if (lower.length >= 4) {
    for (final e in sorted) {
      final k = e.key.toLowerCase();
      if (k.contains(lower)) return e.value;
    }
  }
  return null;
}

/// Normas inferidas: primeiro [assets/data/aws_norms_truth.json] (`servicos`),
/// depois o mapa gerado do CSV do protótipo.
Iterable<String> normsInferredFromAwsServiceToken(String rawToken) sync* {
  final t = rawToken.trim();
  if (t.isEmpty) return;

  final truth = _lookupNormsForToken(_truthNormsByService, _truthNormSortedEntries, t);
  if (truth != null && truth.isNotEmpty) {
    yield* truth;
    return;
  }

  final lower = t.toLowerCase();
  final direct = kAwsServiceNormCorrelation[t];
  if (direct != null) {
    yield* direct;
    return;
  }

  for (final e in kAwsNormSortedEntries) {
    final k = e.key.toLowerCase();
    if (k.isEmpty) continue;
    if (lower.contains(k)) {
      yield* e.value;
      return;
    }
  }

  if (lower.length >= 4) {
    for (final e in kAwsNormSortedEntries) {
      final k = e.key.toLowerCase();
      if (k.contains(lower)) {
        yield* e.value;
        return;
      }
    }
  }
}
