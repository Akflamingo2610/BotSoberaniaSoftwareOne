import 'package:flutter/material.dart';

import '../api/rag_api.dart';
import '../ui/brand.dart';

/// Painel lateral do chat (estilo Copilot) - sempre visível ao lado das questões.
class ChatPanel extends StatefulWidget {
  final String? questionContext;

  const ChatPanel({super.key, this.questionContext});

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

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  @override
  void didUpdateWidget(covariant ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionContext != widget.questionContext) {
      setState(() {});
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
        questionContext: widget.questionContext,
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
          final resp = await _rag.ask(text, questionContext: widget.questionContext);
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
                Icon(Icons.gavel, color: Brand.black, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consultar Leis',
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
          if (widget.questionContext != null &&
              widget.questionContext!.trim().isNotEmpty)
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
                    'Pergunta atual:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Brand.black,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _truncate(widget.questionContext!, 120),
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
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Pergunte sobre as leis\nou peça ajuda nesta pergunta',
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
                      hintText: 'Pergunte sobre as leis...',
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
          child: Icon(Icons.gavel, size: 14, color: Brand.black),
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
              child: Icon(Icons.gavel, size: 14, color: Brand.black),
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
                  if (message.sources != null &&
                      message.sources!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: message.sources!
                          .map(
                            (s) => Chip(
                              label: Text(s.title, style: const TextStyle(fontSize: 10)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
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
