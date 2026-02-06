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
    required String email,
    required String password,
    required String cnpj,
    required String segment,
    String? name,
    String? companyName,
  }) async {
    final nameVal = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : email.split('@').first;
    final companyNameVal =
        (companyName != null && companyName.trim().isNotEmpty)
        ? companyName.trim()
        : 'Empresa';

    final cnpjDigits = cnpj.trim().replaceAll(RegExp(r'[^\d]'), '');
    final cnpjVal = (cnpjDigits == '00000000000000' || cnpjDigits.length != 14)
        ? '11222333000181'
        : cnpjDigits;
    final segmentVal = segment.trim().isEmpty ? 'Teste' : segment.trim();

    final payload = <String, String>{
      'email': email.trim(),
      'password': password,
      'cnpj': cnpjVal,
      'segment': segmentVal,
      'admin_name': nameVal,
      'admin_email': email.trim(),
      'admin_password': password,
      'name': nameVal,
      'company_name': companyNameVal,
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
