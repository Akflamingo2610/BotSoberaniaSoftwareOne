import 'package:flutter/material.dart';

import '../api/rag_api.dart';
import '../ui/brand.dart';

/// Painel lateral do chat (estilo Copilot) - ao lado das questões ou dos resultados.
class ChatPanel extends StatefulWidget {
  /// Contexto da pergunta atual (para explicar questões do assessment).
  final String? questionContext;

  /// Contexto dos resultados (para perguntar sobre scores, compliance, etc).
  /// Quando informado, não faz auto-explicação; o usuário pergunta livremente.
  final String? resultsContext;

  const ChatPanel({super.key, this.questionContext, this.resultsContext});

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

  String? get _effectiveContext =>
      (widget.resultsContext?.trim().isNotEmpty == true)
          ? widget.resultsContext!.trim()
          : widget.questionContext?.trim();

  @override
  void initState() {
    super.initState();
    _checkHealth();
    if (widget.resultsContext == null &&
        widget.questionContext != null &&
        widget.questionContext!.trim().length > 10) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestAutoExplanation());
    }
  }

  @override
  void didUpdateWidget(covariant ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resultsContext != null) return;
    if (oldWidget.questionContext != widget.questionContext) {
      if (widget.questionContext != null &&
          widget.questionContext!.trim().length > 10) {
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
      await for (final chunk in _rag.explainQuestionStream(q)) {
        if (!mounted) return;
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
            'Explique em linguagem simples o que esta pergunta avalia, defina os termos técnicos e por que isso importa para soberania digital.',
            questionContext: q,
          );
          if (resp.answer.trim().isNotEmpty) {
            replyText = resp.answer.trim();
            replySources = resp.sources.isEmpty ? null : resp.sources;
          }
        } catch (_) {}
      }
      if (replyText.isEmpty) {
        _autoExplainRequested = false;
        _messages.add(
          _ChatMessage(
            role: 'bot',
            text: 'Não foi possível gerar a explicação automática. Faça uma pergunta no campo abaixo sobre a questão.',
          ),
        );
      } else {
        _messages.add(
          _ChatMessage(
            role: 'bot',
            text: replyText,
            sources: replySources,
          ),
        );
      }
    } on RagException catch (e) {
      if (!mounted) return;
      _messages.add(_ChatMessage(role: 'bot', text: 'Erro: ${e.message}'));
      _autoExplainRequested = false;
    } catch (e) {
      if (!mounted) return;
      _messages.add(
        _ChatMessage(
          role: 'bot',
          text: 'Não foi possível obter a explicação. Verifique sua conexão ou se o RAG está online.',
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
      )) {
        if (!mounted) return;
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
          final resp = await _rag.ask(text, questionContext: _effectiveContext);
          replyText = resp.answer.trim();
          if (resp.sources.isNotEmpty) sources = resp.sources;
        } catch (_) {
          replyText = '';
        }
      }
      if (replyText.isEmpty) {
        replyText = 'Não foi possível obter resposta. Verifique sua conexão ou tente novamente.';
        sources = null;
      }
      _messages.add(
        _ChatMessage(
          role: 'bot',
          text: replyText,
          sources: sources,
        ),
      );
    } on RagException catch (e) {
      if (!mounted) return;
      _messages.add(_ChatMessage(role: 'bot', text: 'Erro: ${e.message}'));
    } catch (e) {
      if (!mounted) return;
      _messages.add(
        _ChatMessage(
          role: 'bot',
          text: 'Não foi possível conectar ao servidor. Verifique sua conexão ou se o RAG está online.',
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
            color: Colors.black.withOpacity(0.06),
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
              color: Brand.black.withOpacity(0.03),
              border: Border(bottom: BorderSide(color: Brand.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy, color: Brand.black, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bot de Soberania',
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
                      'RAG offline',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          if (_effectiveContext != null && _effectiveContext!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Brand.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Brand.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.resultsContext != null ? 'Resultados:' : 'Pergunta atual:',
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
                            ? 'Pergunte sobre os resultados\nEx: o que significa 45% de Compliance?\nComo podemos melhorar?'
                            : 'Pergunte sobre AWS, soberania digital\nou leis brasileiras',
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
                        if (_streamingText.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: _TypingIndicator(),
                          );
                        }
                        return _ChatBubble(
                          message: _ChatMessage(
                            role: 'bot',
                            text: _streamingText,
                            sources: _streamingSources.isEmpty
                                ? null
                                : _streamingSources,
                          ),
                          isStreaming: true,
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
                      hintText: 'Pergunte sobre AWS, soberania digital ou leis...',
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
  final bool isStreaming;

  const _ChatBubble({required this.message, this.isStreaming = false});

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
              backgroundColor: Brand.black.withOpacity(0.1),
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
                    message.text + (isStreaming ? '▌' : ''),
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
