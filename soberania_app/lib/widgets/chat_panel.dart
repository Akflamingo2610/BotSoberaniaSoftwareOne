import 'package:flutter/material.dart';

import '../api/rag_api.dart';
import '../l10n/locale_scope.dart';
import '../ui/brand.dart';

/// Painel lateral do chat (estilo Copilot) - ao lado das questões ou dos resultados.
class ChatPanel extends StatefulWidget {
  /// Contexto da pergunta atual (para explicar questões do assessment).
  final String? questionContext;

  /// Contexto dos resultados (para perguntar sobre scores, compliance, etc).
  /// Quando informado, não faz auto-explicação; o usuário pergunta livremente.
  final String? resultsContext;

  /// Mensagem de boas-vindas exibida ao carregar (ex: tela de introdução).
  final String? welcomeMessage;

  /// Lista de itens de explicação em lote (para blocos de perguntas):
  /// cada item deve conter: { "id": int, "questionContext": String }.
  final List<Map<String, dynamic>>? blockExplainItems;

  /// Pergunta rápida disparada por cliques na UI (ex.: termos glossário).
  final String? quickQuestion;

  /// Nonce para forçar reenvio da mesma pergunta rápida.
  final int quickQuestionNonce;

  const ChatPanel({
    super.key,
    this.questionContext,
    this.resultsContext,
    this.welcomeMessage,
    this.blockExplainItems,
    this.quickQuestion,
    this.quickQuestionNonce = 0,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _rag = RagApi();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _loading = false;
  bool _connected = false;
  String _streamingText = '';
  List<RagSource> _streamingSources = [];

  bool _autoExplainRequested = false;
  bool _batchExplainRequested = false;
  int _lastQuickQuestionNonce = 0;

  String? get _effectiveContext =>
      (widget.resultsContext?.trim().isNotEmpty == true)
          ? widget.resultsContext!.trim()
          : widget.questionContext?.trim();

  String _ui(String key) {
    switch (_languageCode) {
      case 'en':
        switch (key) {
          case 'auto_explain_failed':
            return 'Automatic explanation could not be generated. Ask a question below about this prompt.';
          case 'auto_explain_fetch_failed':
            return 'Could not get the explanation. Check your connection or whether the RAG is online.';
          case 'batch_explain_failed':
            return 'Automatic explanations for this block could not be generated. Ask questions below about the prompts.';
          case 'batch_fetch_failed':
            return 'Could not fetch the automatic explanations. Check your connection or whether the RAG is online.';
          case 'no_response':
            return 'Could not get a response. Check your connection or try again.';
          case 'server_connect_failed':
            return 'Could not connect to the server. Check your connection or whether the RAG is online.';
          case 'error_prefix':
            return 'Error';
          case 'rag_offline':
            return 'RAG offline';
          case 'results_context':
            return 'Results:';
          case 'question_context':
            return 'Current prompt:';
          case 'empty_results':
            return 'Ask about the results\nEx: what does 45% Compliance mean?\nHow can we improve?';
          case 'empty_general':
            return 'Ask about AWS, digital sovereignty\nor local regulations';
          case 'input_hint':
            return 'Type your question. I am here to help.';
          default:
            return key;
        }
      case 'es':
        switch (key) {
          case 'auto_explain_failed':
            return 'No fue posible generar la explicación automática. Haga una pregunta abajo sobre esta cuestión.';
          case 'auto_explain_fetch_failed':
            return 'No fue posible obtener la explicación. Verifique su conexión o si el RAG está en línea.';
          case 'batch_explain_failed':
            return 'No fue posible generar las explicaciones automáticas de este bloque. Haga preguntas abajo sobre las cuestiones.';
          case 'batch_fetch_failed':
            return 'No fue posible obtener las explicaciones automáticas. Verifique su conexión o si el RAG está en línea.';
          case 'no_response':
            return 'No fue posible obtener una respuesta. Verifique su conexión o inténtelo de nuevo.';
          case 'server_connect_failed':
            return 'No fue posible conectarse al servidor. Verifique su conexión o si el RAG está en línea.';
          case 'error_prefix':
            return 'Error';
          case 'rag_offline':
            return 'RAG sin conexión';
          case 'results_context':
            return 'Resultados:';
          case 'question_context':
            return 'Pregunta actual:';
          case 'empty_results':
            return 'Pregunte sobre los resultados\nEj.: ¿qué significa 45% de Compliance?\n¿Cómo podemos mejorar?';
          case 'empty_general':
            return 'Pregunte sobre AWS, soberanía digital\no leyes';
          case 'input_hint':
            return 'Escriba su duda. Estoy aquí para ayudar.';
          default:
            return key;
        }
      default:
        switch (key) {
          case 'auto_explain_failed':
            return 'Não foi possível gerar a explicação automática. Faça uma pergunta no campo abaixo sobre a questão.';
          case 'auto_explain_fetch_failed':
            return 'Não foi possível obter a explicação. Verifique sua conexão ou se o RAG está online.';
          case 'batch_explain_failed':
            return 'Não foi possível gerar as explicações automáticas para este bloco. Faça perguntas no campo abaixo sobre as questões.';
          case 'batch_fetch_failed':
            return 'Não foi possível obter as explicações automáticas. Verifique sua conexão ou se o RAG está online.';
          case 'no_response':
            return 'Não foi possível obter resposta. Verifique sua conexão ou tente novamente.';
          case 'server_connect_failed':
            return 'Não foi possível conectar ao servidor. Verifique sua conexão ou se o RAG está online.';
          case 'error_prefix':
            return 'Erro';
          case 'rag_offline':
            return 'RAG offline';
          case 'results_context':
            return 'Resultados:';
          case 'question_context':
            return 'Pergunta atual:';
          case 'empty_results':
            return 'Pergunte sobre os resultados\nEx: o que significa 45% de Compliance?\nComo podemos melhorar?';
          case 'empty_general':
            return 'Pergunte sobre AWS, soberania digital\nou leis brasileiras';
          case 'input_hint':
            return 'Digite sua dúvida. Estou aqui para ajudar.';
          default:
            return key;
        }
    }
  }

  String _explainFallbackPrompt() {
    switch (_languageCode) {
      case 'en':
        return 'Explain in simple language what this prompt evaluates, define key technical terms, and why this matters for digital sovereignty. Keep the response very concise (2 to 3 complete sentences), with a clear conclusion and no ellipses.';
      case 'es':
        return 'Explique en lenguaje simple qué evalúa esta pregunta, defina los términos técnicos clave y por qué esto importa para la soberanía digital. Mantenga la respuesta muy concisa (2 a 3 frases completas), con cierre claro y sin puntos suspensivos.';
      default:
        return 'Explique em linguagem simples o que esta pergunta avalia, defina os termos técnicos principais e por que isso importa para soberania digital. Mantenha a resposta muito concisa (2 a 3 frases completas), com fechamento claro e sem reticências.';
    }
  }

  String _conciseInstruction() {
    switch (_languageCode) {
      case 'en':
        return 'Answer very briefly (max 2-3 complete sentences), with direct language and a clear ending. Do not use ellipses.';
      case 'es':
        return 'Responda de forma muy breve (máximo 2-3 frases completas), con lenguaje directo y cierre claro. No use puntos suspensivos.';
      default:
        return 'Responda de forma muito breve (máximo 2-3 frases completas), com linguagem direta e fechamento claro. Não use reticências.';
    }
  }

  String _compactBotText(String raw, {int maxChars = 420}) {
    var text = raw.trim();
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    if (paragraphs.isNotEmpty) {
      text = paragraphs.first.trim();
    }
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text.replaceAll('...', '.').replaceAll('…', '.').trim();

    if (text.length > maxChars) {
      final clipped = text.substring(0, maxChars).trim();
      final sentenceEnd = _lastSentenceBoundary(clipped);
      if (sentenceEnd >= (maxChars * 0.45).floor()) {
        text = clipped.substring(0, sentenceEnd + 1).trim();
      } else {
        final lastSpace = clipped.lastIndexOf(' ');
        text = (lastSpace > 0 ? clipped.substring(0, lastSpace) : clipped).trim();
      }
    }

    text = text.replaceFirst(RegExp(r'[,:;]\s*$'), '').trim();
    if (!_hasTerminalPunctuation(text)) {
      text = '$text.';
    }
    return text;
  }

  int _lastSentenceBoundary(String text) {
    for (var i = text.length - 1; i >= 0; i--) {
      final c = text[i];
      if (c == '.' || c == '!' || c == '?') return i;
    }
    return -1;
  }

  bool _hasTerminalPunctuation(String text) {
    return text.endsWith('.') || text.endsWith('!') || text.endsWith('?');
  }

  String get _languageCode {
    final scope = LocaleScope.of(context);
    final code = scope?.locale.languageCode.toLowerCase() ?? 'pt';
    if (code.startsWith('pt')) return 'pt';
    if (code.startsWith('en')) return 'en';
    if (code.startsWith('es')) return 'es';
    return 'pt';
  }

  @override
  void initState() {
    super.initState();
    _checkHealth();
    _lastQuickQuestionNonce = widget.quickQuestionNonce;
    if (widget.welcomeMessage != null && widget.welcomeMessage!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _messages.add(_ChatMessage(role: 'bot', text: widget.welcomeMessage!.trim()));
        });
      });
    } else if (widget.resultsContext == null &&
        widget.blockExplainItems != null &&
        widget.blockExplainItems!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestBatchExplanations());
    } else if (widget.resultsContext == null &&
        widget.questionContext != null &&
        widget.questionContext!.trim().length > 10) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestAutoExplanation());
    }
    if (widget.quickQuestion != null &&
        widget.quickQuestion!.trim().isNotEmpty &&
        widget.quickQuestionNonce > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendQuickQuestion());
    }
  }

  @override
  void didUpdateWidget(covariant ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Perguntas rápidas via clique devem funcionar também no modo de resultados.
    if (widget.quickQuestionNonce != _lastQuickQuestionNonce) {
      _lastQuickQuestionNonce = widget.quickQuestionNonce;
      _sendQuickQuestion();
    }

    if (widget.resultsContext != null) return;

    // Atualização do bloco de explicações
    if (oldWidget.blockExplainItems != widget.blockExplainItems &&
        widget.blockExplainItems != null &&
        widget.blockExplainItems!.isNotEmpty) {
      _batchExplainRequested = false;
      setState(() => _messages.clear());
      _requestBatchExplanations();
      return;
    }

    // Atualização da pergunta única (modo antigo)
    if (oldWidget.questionContext != widget.questionContext) {
      if (widget.questionContext != null &&
          widget.questionContext!.trim().length > 10 &&
          (widget.blockExplainItems == null ||
              widget.blockExplainItems!.isEmpty)) {
        _autoExplainRequested = false;
        setState(() => _messages.clear());
        _requestAutoExplanation();
      } else {
        setState(() {});
      }
    }

  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    final ok = await _rag.health();
    if (mounted) setState(() => _connected = ok);
  }

  Future<void> _requestAutoExplanation() async {
    final q = widget.questionContext?.trim() ?? '';
    if (q.isEmpty || q.length < 10 || _loading || _autoExplainRequested) return;

    _autoExplainRequested = true;
    setState(() {
      _loading = true;
      _streamingText = '';
      _streamingSources = [];
    });
    _scrollToBottom();

    try {
      await for (final chunk in _rag.explainQuestionStream(
        q,
        languageCode: _languageCode,
      )) {
        if (!mounted) return;
        if (!_connected) {
          setState(() => _connected = true);
        }
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          setState(() => _streamingText += chunk.text!);
          _scrollToBottom();
        }
        if (chunk.done && chunk.sources.isNotEmpty) {
          setState(() => _streamingSources = chunk.sources);
        }
      }
      if (!mounted) return;
      String replyText = _streamingText.trim();
      List<RagSource>? replySources = _streamingSources.isEmpty ? null : _streamingSources;
      if (replyText.isEmpty) {
        // Fallback: streaming veio vazio — tentar endpoint /ask (não-streaming)
        try {
          final resp = await _rag.ask(
            '${_explainFallbackPrompt()} ${_conciseInstruction()}',
            questionContext: q,
            languageCode: _languageCode,
          );
          if (resp.answer.trim().isNotEmpty) {
            replyText = _compactBotText(resp.answer);
            replySources = resp.sources.isEmpty ? null : resp.sources;
          }
        } catch (_) {}
      }
      if (replyText.isEmpty) {
        _autoExplainRequested = false;
        _messages.add(
          _ChatMessage(
            role: 'bot',
            text: _ui('auto_explain_failed'),
          ),
        );
      } else {
        _messages.add(
          _ChatMessage(
            role: 'bot',
            text: _compactBotText(replyText),
            sources: replySources,
          ),
        );
      }
    } on RagException catch (e) {
      if (!mounted) return;
      setState(() => _connected = false);
      _messages.add(_ChatMessage(role: 'bot', text: '${_ui('error_prefix')}: ${e.message}'));
      _autoExplainRequested = false;
    } catch (e) {
      if (!mounted) return;
      setState(() => _connected = false);
      _messages.add(
        _ChatMessage(
          role: 'bot',
            text: _ui('auto_explain_fetch_failed'),
        ),
      );
      _autoExplainRequested = false;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _streamingText = '';
          _streamingSources = [];
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _requestBatchExplanations() async {
    final items = widget.blockExplainItems ?? const [];
    if (items.isEmpty || _loading || _batchExplainRequested) return;

    _batchExplainRequested = true;
    setState(() {
      _loading = true;
      _streamingText = '';
      _streamingSources = [];
      _messages.clear();
    });
    _scrollToBottom();

    try {
      final explanations =
          await _rag.explainBatch(items, languageCode: _languageCode);
      if (!mounted) return;
      if (!_connected) {
        setState(() => _connected = true);
      }

      if (explanations.isEmpty) {
        _messages.add(
          _ChatMessage(
            role: 'bot',
                text: _ui('batch_explain_failed'),
          ),
        );
      } else {
        for (final e in explanations) {
          _messages.add(
            _ChatMessage(
              role: 'bot',
              text: _compactBotText(e.text, maxChars: 320),
            ),
          );
        }
      }
    } on RagException catch (e) {
      if (!mounted) return;
      setState(() => _connected = false);
      _messages.add(_ChatMessage(role: 'bot', text: '${_ui('error_prefix')}: ${e.message}'));
      _batchExplainRequested = false;
    } catch (e) {
      if (!mounted) return;
      setState(() => _connected = false);
      _messages.add(
        _ChatMessage(
          role: 'bot',
            text: _ui('batch_fetch_failed'),
        ),
      );
      _batchExplainRequested = false;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _streamingText = '';
          _streamingSources = [];
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    _controller.clear();
    _messages.add(_ChatMessage(role: 'user', text: text));
    setState(() {
      _loading = true;
      _streamingText = '';
      _streamingSources = [];
    });
    _scrollToBottom();

    try {
      await for (final chunk in _rag.askStream(
        text,
        questionContext: _effectiveContext,
        languageCode: _languageCode,
      )) {
        if (!mounted) return;
        if (!_connected) {
          setState(() => _connected = true);
        }
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          setState(() => _streamingText += chunk.text!);
          _scrollToBottom();
        }
        if (chunk.done && chunk.sources.isNotEmpty) {
          setState(() => _streamingSources = chunk.sources);
        }
      }
      if (!mounted) return;
      String replyText = _streamingText.trim();
      List<RagSource>? sources = _streamingSources.isEmpty ? null : _streamingSources;

      if (replyText.isEmpty) {
        try {
          final resp = await _rag.ask(
            '$text\n\n${_conciseInstruction()}',
            questionContext: _effectiveContext,
            languageCode: _languageCode,
          );
          replyText = _compactBotText(resp.answer);
          if (resp.sources.isNotEmpty) sources = resp.sources;
        } catch (_) {
          replyText = '';
        }
      }
      if (replyText.isEmpty) {
        replyText = _ui('no_response');
        sources = null;
      }
      _messages.add(
        _ChatMessage(
          role: 'bot',
          text: _compactBotText(replyText),
          sources: sources,
        ),
      );
    } on RagException catch (e) {
      if (!mounted) return;
      setState(() => _connected = false);
      _messages.add(_ChatMessage(role: 'bot', text: '${_ui('error_prefix')}: ${e.message}'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _connected = false);
      _messages.add(
        _ChatMessage(
          role: 'bot',
          text: _ui('server_connect_failed'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _streamingText = '';
          _streamingSources = [];
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendQuickQuestion() async {
    final text = widget.quickQuestion?.trim() ?? '';
    if (text.isEmpty || _loading) return;

    _messages.add(_ChatMessage(role: 'user', text: text));
    setState(() {
      _loading = true;
      _streamingText = '';
      _streamingSources = [];
    });
    _scrollToBottom();

    try {
      await for (final chunk in _rag.askStream(
        '$text\n\n${_conciseInstruction()}',
        questionContext: _effectiveContext,
        languageCode: _languageCode,
      )) {
        if (!mounted) return;
        if (!_connected) {
          setState(() => _connected = true);
        }
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          setState(() => _streamingText += chunk.text!);
          _scrollToBottom();
        }
        if (chunk.done && chunk.sources.isNotEmpty) {
          setState(() => _streamingSources = chunk.sources);
        }
      }
      if (!mounted) return;
      String replyText = _streamingText.trim();
      List<RagSource>? sources = _streamingSources.isEmpty ? null : _streamingSources;

      if (replyText.isEmpty) {
        try {
          final resp = await _rag.ask(
            '$text\n\n${_conciseInstruction()}',
            questionContext: _effectiveContext,
            languageCode: _languageCode,
          );
          replyText = _compactBotText(resp.answer);
          if (resp.sources.isNotEmpty) sources = resp.sources;
        } catch (_) {
          replyText = '';
        }
      }
      if (replyText.isEmpty) {
        replyText = _ui('no_response');
        sources = null;
      }
      _messages.add(
        _ChatMessage(
          role: 'bot',
          text: _compactBotText(replyText),
          sources: sources,
        ),
      );
    } on RagException catch (e) {
      if (!mounted) return;
      setState(() => _connected = false);
      _messages.add(_ChatMessage(role: 'bot', text: '${_ui('error_prefix')}: ${e.message}'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _connected = false);
      _messages.add(
        _ChatMessage(
          role: 'bot',
          text: _ui('server_connect_failed'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _streamingText = '';
          _streamingSources = [];
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: Brand.white,
        border: Border(left: BorderSide(color: Brand.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Brand.black.withValues(alpha: 0.03),
              border: Border(bottom: BorderSide(color: Brand.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy, color: Brand.black, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SoberanIA',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Brand.black,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (!_connected)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ui('rag_offline'),
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          if (_effectiveContext != null &&
              _effectiveContext!.isNotEmpty &&
              widget.resultsContext == null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Brand.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Brand.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.resultsContext != null
                        ? _ui('results_context')
                        : _ui('question_context'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Brand.black,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _truncate(_effectiveContext!, 120),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty && !_loading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.resultsContext != null
                            ? _ui('empty_results')
                            : _ui('empty_general'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_loading && i == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: _TypingIndicator(),
                        );
                      }
                      return _ChatBubble(message: _messages[i]);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Brand.white,
              border: Border(top: BorderSide(color: Brand.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _ui('input_hint'),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    maxLines: 2,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _loading ? null : _send,
                  icon: _loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Brand.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Brand.black,
                    foregroundColor: Brand.white,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen)}...';
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final List<RagSource>? sources;

  _ChatMessage({required this.role, required this.text, this.sources});
}

/// Indicador animado de "digitando..." (três pontos pulsantes).
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Brand.black.withValues(alpha: 0.1),
          child: Icon(Icons.smart_toy, size: 14, color: Brand.black),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Brand.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Brand.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = (_controller.value + i * 0.25) % 1.0;
                  final scale = 0.5 + 0.5 * (1 + (t * 2 - 1).clamp(-1.0, 1.0));
                  return Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Brand.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 12,
              backgroundColor: Brand.black.withValues(alpha: 0.1),
              child: Icon(Icons.smart_toy, size: 14, color: Brand.black),
            ),
          if (!isUser) const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUser ? Brand.black : Brand.surface,
                borderRadius: BorderRadius.circular(10),
                border: isUser ? null : Border.all(color: Brand.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Brand.white : Brand.black,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
          if (isUser)
            CircleAvatar(
              radius: 12,
              backgroundColor: Brand.black,
              child: Icon(Icons.person, size: 14, color: Brand.white),
            ),
        ],
      ),
    );
  }
}
