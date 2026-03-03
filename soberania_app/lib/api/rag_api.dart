import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class RagApi {
  final String baseUrl;
  RagApi({String? baseUrl}) : baseUrl = (baseUrl ?? ragBaseUrl).trim();

  Future<RagResponse> ask(
    String query, {
    String? questionContext,
    String? languageCode,
  }) async {
    final uri = Uri.parse('$baseUrl/ask');
    final body = <String, dynamic>{'query': query};
    if (questionContext != null && questionContext.trim().isNotEmpty) {
      body['questionContext'] = questionContext.trim();
    }
    if (languageCode != null && languageCode.trim().isNotEmpty) {
      body['language'] = languageCode.trim();
    }
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return RagResponse(
        answer: (json['answer'] ?? '').toString(),
        sources:
            (json['sources'] as List<dynamic>?)
                ?.map((e) => RagSource.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    }

    String msg = 'Erro ${res.statusCode}';
    try {
      final err = jsonDecode(res.body);
      if (err is Map && err['error'] != null) {
        msg = err['error'].toString();
      }
    } catch (_) {}
    throw RagException(msg);
  }

  /// Resposta em streaming: texto aparece em tempo real (menor latência percebida)
  Stream<RagStreamChunk> askStream(
    String query, {
    String? questionContext,
    String? languageCode,
  }) async* {
    final uri = Uri.parse('$baseUrl/ask/stream');
    final body = <String, dynamic>{'query': query};
    if (questionContext != null && questionContext.trim().isNotEmpty) {
      body['questionContext'] = questionContext.trim();
    }
    if (languageCode != null && languageCode.trim().isNotEmpty) {
      body['language'] = languageCode.trim();
    }
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode >= 400) {
        final body = await response.stream.bytesToString();
        String msg = 'Erro ${response.statusCode}';
        try {
          final err = jsonDecode(body);
          if (err is Map && err['error'] != null) msg = err['error'].toString();
        } catch (_) {}
        throw RagException(msg);
      }

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final obj = jsonDecode(line) as Map<String, dynamic>;
            final t = obj['t']?.toString();
            if (t != null && t.isNotEmpty) {
              yield RagStreamChunk(text: t);
            }
            if (obj['done'] == true) {
              final src = obj['sources'] as List<dynamic>?;
              final sources =
                  src
                      ?.map(
                        (e) => RagSource.fromJson(e as Map<String, dynamic>),
                      )
                      .toList() ??
                  [];
              yield RagStreamChunk(sources: sources, done: true);
            }
          } catch (_) {}
        }
      }
      if (buffer.trim().isNotEmpty) {
        try {
          final obj = jsonDecode(buffer) as Map<String, dynamic>;
          final t = obj['t']?.toString();
          if (t != null && t.isNotEmpty) yield RagStreamChunk(text: t);
          if (obj['done'] == true) {
            final src = obj['sources'] as List<dynamic>?;
            yield RagStreamChunk(
              sources:
                  src
                      ?.map(
                        (e) => RagSource.fromJson(e as Map<String, dynamic>),
                      )
                      .toList() ??
                  [],
              done: true,
            );
          }
        } catch (_) {}
      }
    } finally {
      client.close();
    }
  }

  Future<bool> health() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Explicação automática da pergunta do assessment (resposta proativa)
  Stream<RagStreamChunk> explainQuestionStream(
    String questionContext, {
    String? languageCode,
  }) async* {
    final uri = Uri.parse('$baseUrl/ask/explain-question/stream');
    final body = <String, dynamic>{'questionContext': questionContext.trim()};
    if (languageCode != null && languageCode.trim().isNotEmpty) {
      body['language'] = languageCode.trim();
    }

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode >= 400) {
        final body = await response.stream.bytesToString();
        String msg = 'Erro ${response.statusCode}';
        try {
          final err = jsonDecode(body);
          if (err is Map && err['error'] != null) msg = err['error'].toString();
        } catch (_) {}
        throw RagException(msg);
      }

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final obj = jsonDecode(line) as Map<String, dynamic>;
            final t = obj['t']?.toString();
            if (t != null && t.isNotEmpty) {
              yield RagStreamChunk(text: t);
            }
            if (obj['done'] == true) {
              final src = obj['sources'] as List<dynamic>?;
              final sources =
                  src
                      ?.map(
                        (e) => RagSource.fromJson(e as Map<String, dynamic>),
                      )
                      .toList() ??
                  [];
              yield RagStreamChunk(sources: sources, done: true);
            }
          } catch (_) {}
        }
      }
      if (buffer.trim().isNotEmpty) {
        try {
          final obj = jsonDecode(buffer) as Map<String, dynamic>;
          final t = obj['t']?.toString();
          if (t != null && t.isNotEmpty) yield RagStreamChunk(text: t);
          if (obj['done'] == true) {
            final src = obj['sources'] as List<dynamic>?;
            yield RagStreamChunk(
              sources:
                  src
                      ?.map(
                        (e) => RagSource.fromJson(e as Map<String, dynamic>),
                      )
                      .toList() ??
                  [],
              done: true,
            );
          }
        } catch (_) {}
      }
    } finally {
      client.close();
    }
  }
  Future<List<RagExplanation>> explainBatch(
    List<Map<String, dynamic>> questions, {
    String? languageCode,
  }) async {
    if (questions.isEmpty) return const [];
    final uri = Uri.parse('$baseUrl/ask/explain-batch');
    final body = <String, dynamic>{'questions': questions};
    if (languageCode != null && languageCode.trim().isNotEmpty) {
      body['language'] = languageCode.trim();
    }
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map>()
          .map((e) => RagExplanation.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    String msg = 'Erro ${res.statusCode}';
    try {
      final err = jsonDecode(res.body);
      if (err is Map && err['error'] != null) {
        msg = err['error'].toString();
      }
    } catch (_) {}
    throw RagException(msg);
  }
}

class RagResponse {
  final String answer;
  final List<RagSource> sources;

  RagResponse({required this.answer, required this.sources});
}

class RagStreamChunk {
  final String? text;
  final List<RagSource> sources;
  final bool done;

  RagStreamChunk({this.text, this.sources = const [], this.done = false});
}

class RagExplanation {
  final int id;
  final String text;

  RagExplanation({required this.id, required this.text});

  factory RagExplanation.fromJson(Map<String, dynamic> json) {
    return RagExplanation(
      id: (json['id'] as num).toInt(),
      text: (json['text'] ?? '').toString(),
    );
  }
}

class RagSource {
  final String title;
  final String file;

  RagSource({required this.title, required this.file});

  factory RagSource.fromJson(Map<String, dynamic> json) {
    return RagSource(
      title: (json['title'] ?? '').toString(),
      file: (json['file'] ?? '').toString(),
    );
  }
}

class RagException implements Exception {
  final String message;
  RagException(this.message);
  @override
  String toString() => message;
}
