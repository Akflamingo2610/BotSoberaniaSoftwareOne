import 'package:flutter/material.dart';

import '../api/rag_api.dart';
import '../ui/brand.dart';

/// Tela do chatbot RAG sobre leis (LGPD, Marco Civil, etc.)
/// [questionContext] = texto da pergunta do assessment, quando aberto de lá
class ChatScreen extends StatefulWidget {
  final String? questionContext;

  const ChatScreen({super.key, this.questionContext});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _rag = RagApi();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<_Message> _messages = [];
  bool _loading = false;
  bool _connected = false;
  String _streamingText = '';
  List<RagSource> _streamingSources = [];

  String _conciseInstruction() {
    return 'Responda de forma muito breve (maximo 2 a 3 frases completas), com linguagem direta e conclusao clara. Nao use reticencias.';
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
    if (!(text.endsWith('.') || text.endsWith('!') || text.endsWith('?'))) {
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

  @override
  void initState() {
    super.initState();
    _checkHealth();
    // Explicação automática quando há pergunta do assessment
    if (widget.questionContext != null &&
        widget.questionContext!.trim().length > 10) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _requestAutoExplanation(),
      );
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
    if (q.isEmpty || q.length < 10 || _loading || _messages.isNotEmpty) return;

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
      _messages.add(
        _Message(
          role: 'bot',
          text: _compactBotText(_streamingText),
          sources: _streamingSources.isEmpty ? null : _streamingSources,
        ),
      );
    } on RagException catch (e) {
      if (!mounted) return;
      _messages.add(_Message(role: 'bot', text: 'Erro: ${e.message}'));
    } catch (e) {
      if (!mounted) return;
      _messages.add(
        _Message(
          role: 'bot',
          text:
              'Não foi possível obter a explicação. Verifique se o servidor RAG está rodando.',
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    _controller.clear();
    _messages.add(_Message(role: 'user', text: text));
    setState(() {
      _loading = true;
      _streamingText = '';
      _streamingSources = [];
    });
    _scrollToBottom();

    try {
      await for (final chunk in _rag.askStream(
        '$text\n\n${_conciseInstruction()}',
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
      _messages.add(
        _Message(
          role: 'bot',
          text: _compactBotText(_streamingText),
          sources: _streamingSources.isEmpty ? null : _streamingSources,
        ),
      );
    } on RagException catch (e) {
      if (!mounted) return;
      _messages.add(_Message(role: 'bot', text: 'Erro: ${e.message}'));
    } catch (e) {
      if (!mounted) return;
      _messages.add(
        _Message(
          role: 'bot',
          text:
              'Não foi possível conectar ao servidor RAG. Verifique se o rag_server está rodando (npm start na pasta rag_server).',
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
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: AppBar(
        backgroundColor: Brand.white,
        surfaceTintColor: Brand.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Brand.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Brand.black, size: 24),
            const SizedBox(width: 8),
            Text(
              'SoberanIA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(



                 color: Brand.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_connected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Servidor RAG offline. Inicie com: cd rag_server && npm start',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty && !_loading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 64,
                            color: Brand.black.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          if (widget.questionContext != null &&
                              widget.questionContext!.trim().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Brand.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Brand.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pergunta do assessment:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Brand.black,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.questionContext!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Pergunte como as leis se aplicam\nou peça explicação sobre esta pergunta',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ] else ...[
                            Text(
                              'Pergunte sobre LGPD, Marco Civil,\nECA Digital, BCB e demais leis',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ex: "O que a LGPD diz sobre consentimento?"',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.black38,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_loading && i == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _TypingIndicatorInline(),
                        );
                      }
                      return _ChatBubble(message: _messages[i]);
                    },
                  ),
          ),
          Container(
            color: Brand.white,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: widget.questionContext != null
                            ? 'Ex: Explique esta pergunta e sua relação com a LGPD'
                            : 'Digite sua pergunta sobre as leis...',
                        border: const OutlineInputBorder(),
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Brand.black,
                      foregroundColor: Brand.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String role;
  final String text;
  final List<RagSource>? sources;

  _Message({required this.role, required this.text, this.sources});
}

class _TypingIndicatorInline extends StatelessWidget {
  const _TypingIndicatorInline();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Brand.black.withValues(alpha: 0.1),
          child: Icon(Icons.smart_toy, size: 18, color: Brand.black),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Brand.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Brand.border),
          ),
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _Message message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    // Deixa respostas do bot mais objetivas no front, limitando tamanho.
    String displayText = message.text;
    if (!isUser) {
      // Limita a no máximo 2 parágrafos principais.
      final paragraphs = displayText.split('\n\n');
      if (paragraphs.length > 2) {
        displayText = '${paragraphs.take(2).join('\n\n')}\n\n[...]';
      }
      // E garante um limite de caracteres para evitar textos muito longos.
      const maxChars = 900;
      if (displayText.length > maxChars) {
        displayText = '${displayText.substring(0, maxChars)}...';
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Brand.black.withValues(alpha: 0.1),
              child: Icon(Icons.smart_toy, size: 18, color: Brand.black),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Brand.black : Brand.white,
                borderRadius: BorderRadius.circular(12),
                border: isUser ? null : Border.all(color: Brand.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    displayText,
                    style: TextStyle(
                      color: isUser ? Brand.white : Brand.black,
                      fontSize: 14,
                    ),
                  ),
                  if (message.sources != null &&
                      message.sources!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: message.sources!
                          .map(
                            (s) => Chip(
                              label: Text(
                                s.title,
                                style: const TextStyle(fontSize: 11),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
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
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Brand.black,
              child: Icon(Icons.person, size: 18, color: Brand.white),
            ),
        ],
      ),
    );
  }
}
