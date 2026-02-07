import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Cache simples para reduzir requisições ao Xano (limite 10 req/20s no plano gratuito).
class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

class ApiException implements Exception {
  final int statusCode;
  final dynamic body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException(statusCode: $statusCode, body: $body)';
}

class XanoApi {
  final http.Client _client;
  XanoApi({http.Client? client}) : _client = client ?? http.Client();

  // Cache em memória (TTL: questões 60s, progresso 25s).
  static final Map<String, _CacheEntry> _cache = {};
  static const _questionsTtlSeconds = 60;
  static const _progressTtlSeconds = 25;

  void _clearProgressCache() {
    _cache.removeWhere((k, _) => k.startsWith('p_'));
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = xanoBaseUrl.trim();
    if (base.isEmpty || base.contains('SEU_XANO_AQUI')) {
      throw StateError('Defina o xanoBaseUrl em lib/config.dart');
    }
    final normalizedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$normalizedBase$normalizedPath',
    ).replace(queryParameters: query);
  }

  Map<String, String> _headers({String? authToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      _uri('/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _tryJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (body as Map).cast<String, dynamic>();
    }
    throw ApiException(res.statusCode, body);
  }

  /// Cadastro de nova empresa/usuário. Endpoint: POST /signup_company
  Future<Map<String, dynamic>> signupCompany({
    required String name,
    required String lastName,
    required String email,
    required String phone,
    required String companyName,
    String? role,
    required String password,
  }) async {
    final phoneDigits = phone.replaceAll(RegExp(r'[^\d]'), '');
    final emailTrim = email.trim();

    final payload = <String, dynamic>{
      'admin_name': name.trim(),
      'admin_email': emailTrim,
      'admin_password': password,
      'name': name.trim(),
      'last_name': lastName.trim(),
      'email': emailTrim,
      'phone': phoneDigits,
      'company_name': companyName.trim(),
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      'password': password,
      'cnpj': '00000000000191',
      'segment': 'Geral',
    };
    final res = await _client.post(
      _uri('/signup_company'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final body = _tryJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (body as Map).cast<String, dynamic>();
    }
    throw ApiException(res.statusCode, body);
  }

  Future<Map<String, dynamic>> resumeAssessment({
    required String authToken,
  }) async {
    final res = await _client.post(
      _uri('/assessment/resume'),
      headers: _headers(authToken: authToken),
      body: jsonEncode({}),
    );
    final body = _tryJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (body as Map).cast<String, dynamic>();
    }
    throw ApiException(res.statusCode, body);
  }

  static const _allPhases = ['Quick_Wins', 'Foundational', 'Efficient', 'Optimized'];

  Future<List<dynamic>> listQuestions({
    required String authToken,
    required String phase,
  }) async {
    final key = 'q_$phase';
    final cached = _cache[key];
    if (cached != null && cached.isValid) return cached.value as List<dynamic>;

    final res = await _client.get(
      _uri('/questions', {'phase': phase}),
      headers: _headers(authToken: authToken),
    );
    final body = _tryJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is List) {
        _cache[key] = _CacheEntry(
          body,
          DateTime.now().add(const Duration(seconds: _questionsTtlSeconds)),
        );
        return body;
      }
      throw ApiException(res.statusCode, body);
    }
    throw ApiException(res.statusCode, body);
  }

  /// Busca questões filtradas por pilar (Compliance, Continuity, Control).
  Future<List<dynamic>> listQuestionsByPilar({
    required String authToken,
    required String pilar,
  }) async {
    final key = 'q_pilar_$pilar';
    final cached = _cache[key];
    if (cached != null && cached.isValid) return cached.value as List<dynamic>;

    final all = <Map<String, dynamic>>[];
    for (final phase in _allPhases) {
      final raw = await listQuestions(authToken: authToken, phase: phase);
      for (final e in raw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          final qPilar = (m['pilar'] ?? '').toString();
          if (qPilar.toLowerCase() == pilar.toLowerCase()) all.add(m);
        }
      }
    }
    all.sort((a, b) => ((a['order_index'] ?? 0) as num).toInt().compareTo(((b['order_index'] ?? 0) as num).toInt()));
    _cache[key] = _CacheEntry(
      all,
      DateTime.now().add(const Duration(seconds: _questionsTtlSeconds)),
    );
    return all;
  }

  Future<Map<String, dynamic>> getProgress({
    required String authToken,
    required int assessmentId,
  }) async {
    final key = 'p_$assessmentId';
    final cached = _cache[key];
    if (cached != null && cached.isValid) return cached.value as Map<String, dynamic>;

    final res = await _client.get(
      _uri('/progress/assessment', {'assessment_id': assessmentId.toString()}),
      headers: _headers(authToken: authToken),
    );
    final body = _tryJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = (body as Map).cast<String, dynamic>();
      _cache[key] = _CacheEntry(
        data,
        DateTime.now().add(const Duration(seconds: _progressTtlSeconds)),
      );
      return data;
    }
    throw ApiException(res.statusCode, body);
  }

  Future<void> saveAnswer({
    required String authToken,
    required int assessmentId,
    required int questionId,
    required String score,
  }) async {
    final res = await _client.post(
      _uri('/assessment/save'),
      headers: _headers(authToken: authToken),
      body: jsonEncode({
        'assessment_id': assessmentId,
        'answers': [
          {
            'question_id': questionId,
            'score': score,
            'justification': '',
            'evidence': '',
          },
        ],
      }),
    );
    final body = _tryJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      _clearProgressCache(); // invalida cache de progresso após salvar
      return;
    }
    throw ApiException(res.statusCode, body);
  }

  dynamic _tryJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }
}
