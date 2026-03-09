import 'dart:async';

import 'package:flutter/material.dart';

import '../api/xano_api.dart';
import '../models/models.dart' show Question, SavedAnswer, scoreOptions, normalizeScore, scoreToApiValue;
import '../storage/app_storage.dart';
import '../storage/position_persistence.dart';
import '../ui/brand.dart';
import '../widgets/chat_panel.dart';
import '../widgets/criteria_panel.dart';
import 'assessment_intro_screen.dart';

class QuestionsScreen extends StatefulWidget {
  final String phase;
  final String phaseLabel;
  final bool byPilar;

  const QuestionsScreen({
    super.key,
    required this.phase,
    required this.phaseLabel,
    this.byPilar = false,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> with WidgetsBindingObserver {
  final _api = XanoApi();
  final _storage = AppStorage();

  bool _loading = true;
  String? _error;

  int? _assessmentId;
  String? _authToken;

  List<Question> _questions = [];
  final Map<int, SavedAnswer> _answersByQuestionId = {};
  final Map<int, String> _pendingAnswersByQuestionId = {}; // respostas locais ainda não salvas

  static const int _blockSize = 9;
  int _blockStartIndex = 0; // índice da primeira pergunta do bloco atual
  bool _saving = false;
  Timer? _persistTimer;
  bool _showCriteria = false;
  Question? _selectedQuestion;

  void _persistPosition() {
    if (_questions.isNotEmpty &&
        _blockStartIndex >= 0 &&
        _blockStartIndex < _questions.length) {
      _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    registerBeforeUnload(_persistPosition); // Web: salva ao fechar aba
    _load();
    _persistTimer = Timer.periodic(const Duration(seconds: 2), (_) => _persistPosition());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persistPosition();
    }
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    _persistTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    _persistPosition();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _storage.getAuthToken();
      final assessmentId = await _storage.getAssessmentId();
      if (token == null) throw StateError('Sem authToken salvo. Faça login.');
      if (assessmentId == null) {
        throw StateError('Sem assessmentId. Rode /assessment/resume.');
      }

      final rawQuestions = widget.byPilar
          ? await _api.listQuestionsByPilar(
              authToken: token,
              pilar: widget.phase,
            )
          : await _api.listQuestions(
              authToken: token,
              phase: widget.phase,
            );
      final questions = rawQuestions
          .whereType<Map>()
          .map((e) => Question.fromJson(e.cast<String, dynamic>()))
          .toList();

      // Busca respostas já salvas (para preencher e continuar).
      Map<String, dynamic> progress;
      try {
        progress = await _api.getProgress(
          authToken: token,
          assessmentId: assessmentId,
        );
      } catch (_) {
        progress = {};
      }

      final answers = <SavedAnswer>[];
      final rawAnswers = progress['answers'];
      if (rawAnswers is List) {
        for (final a in rawAnswers) {
          if (a is Map) {
            answers.add(SavedAnswer.fromJson(a.cast<String, dynamic>()));
          }
        }
      }
      final map = <int, SavedAnswer>{for (final a in answers) a.questionId: a};

      // Primeira pergunta da fase que não tem answer.
      var startIndex = 0;
      for (var i = 0; i < questions.length; i++) {
        if (!map.containsKey(questions[i].id)) {
          startIndex = i;
          break;
        }
      }

      // Restaura posição salva se existir (mesmo questão já respondida).
      final savedIndex = await _storage.getLastQuestionIndex(widget.phase);
      if (savedIndex != null && savedIndex >= 0 && savedIndex < questions.length) {
        _blockStartIndex = (savedIndex ~/ _blockSize) * _blockSize;
      } else {
        _blockStartIndex = (startIndex ~/ _blockSize) * _blockSize;
      }

      _authToken = token;
      _assessmentId = assessmentId;
      _questions = questions;
      _answersByQuestionId
        ..clear()
        ..addAll(map);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Question> get _currentBlockQuestions {
    if (_questions.isEmpty) return const [];
    final start = _blockStartIndex.clamp(0, _questions.length);
    final end = (start + _blockSize).clamp(0, _questions.length);
    return _questions.sublist(start, end);
  }

  String _buildQuestionContext(Question q) {
    return [
      q.recommendation,
      if ((q.guidance ?? '').trim().isNotEmpty)
        'Guidance: ${q.guidance!.trim()}',
      if ((q.howToCheck ?? '').trim().isNotEmpty)
        'How to check: ${q.howToCheck!.trim()}',
    ].join('\n\n');
  }

  Future<void> _saveCurrentBlock() async {
    final token = _authToken;
    final assessmentId = _assessmentId;
    if (token == null || assessmentId == null) return;
    final blockQuestions = _currentBlockQuestions;
    if (blockQuestions.isEmpty) return;

    // Monta payload das 9 perguntas; exige que todas tenham score selecionado
    final answersPayload = <Map<String, dynamic>>[];
    final missing = <String>[];
    for (final q in blockQuestions) {
      final saved = _answersByQuestionId[q.id];
      final pending = _pendingAnswersByQuestionId[q.id];
      final rawScore = pending ?? saved?.score;
      final normalized = rawScore != null ? normalizeScore(rawScore) : null;
      if (normalized == null || normalized.isEmpty) {
        missing.add(q.recommendation);
        continue;
      }
      answersPayload.add({
        'question_id': q.id,
        'score': scoreToApiValue(normalized),
        'justification': '',
        'evidence': '',
      });
    }

    if (missing.isNotEmpty || answersPayload.length != blockQuestions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Responda todas as perguntas deste bloco antes de continuar.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.saveAnswersBulk(
        authToken: token,
        assessmentId: assessmentId,
        answers: answersPayload,
      );

      // Atualiza cache local como "salvo" e remove pendentes deste bloco
      for (final q in blockQuestions) {
        final normalized = normalizeScore(
          _pendingAnswersByQuestionId[q.id] ?? _answersByQuestionId[q.id]?.score,
        );
        _pendingAnswersByQuestionId.remove(q.id);
        _answersByQuestionId[q.id] = SavedAnswer(
          id: -1,
          questionId: q.id,
          score: normalized,
        );
      }

      if (!mounted) return;
      final nextStart = _blockStartIndex + _blockSize;
      if (nextStart < _questions.length) {
        setState(() => _blockStartIndex = nextStart);
        await _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
      } else {
        await _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Todas as questões dessa sessão foram respondidas. Você pode alterar suas respostas se desejar.',
            ),
          ),
        );
        setState(() {}); // atualiza UI
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Volta para a tela de pilares (salva posição e faz pop).
  Future<void> _goBackToPillars() async {
    await _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Verifica se todas as questões DESTE pilar foram respondidas (não das outras abas).
  bool get _allAnsweredInPhase =>
      _questions.isNotEmpty &&
      _questions.every((q) => _answersByQuestionId.containsKey(q.id));

  void _goToPreviousBlock() {
    if (_blockStartIndex <= 0) return;
    final newStart = (_blockStartIndex - _blockSize).clamp(0, _questions.length - 1);
    setState(() {
      _blockStartIndex = newStart;
      _selectedQuestion = null;
    });
    _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
  }

  void _goToNextBlock() {
    final nextStart = _blockStartIndex + _blockSize;
    if (nextStart >= _questions.length) return;
    setState(() {
      _blockStartIndex = nextStart;
      _selectedQuestion = null;
    });
    _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(
        context,
        title: widget.phaseLabel,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBackToPillars,
              tooltip: 'Voltar para pilares',
            ),
            IconButton(
              icon: const Icon(Icons.home_rounded),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AssessmentIntroScreen()),
                  (_) => false,
                );
              },
              tooltip: 'Ir para introdução',
            ),
          ],
        ),
        leadingWidth: 96,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(error: _error!, onRetry: _load)
            : _questions.isEmpty
            ? const Center(
                child: Text('Nenhuma pergunta encontrada para essa fase.'),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final showPanel = constraints.maxWidth > 800;
                  return Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showCriteria)
                            CriteriaPanel(
                              onClose: () => setState(() => _showCriteria = false),
                            ),
                          Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: _showCriteria ? 0 : 40),
                        child: Column(
                          children: [
                            _ProgressBar(
                              currentIndex: _blockStartIndex,
                              answered: _questions
                                  .where((q) => _answersByQuestionId.containsKey(q.id))
                                  .length,
                              total: _questions.length,
                              phaseLabel: widget.phaseLabel,
                              allAnswered: _allAnsweredInPhase,
                              onPreviousBlock:
                                  _blockStartIndex > 0 ? _goToPreviousBlock : null,
                              onNextBlock: _blockStartIndex + _blockSize < _questions.length
                                  ? _goToNextBlock
                                  : null,
                              onSaveBlock: _saveCurrentBlock,
                              saving: _saving,
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: _currentBlockQuestions.map((q) {
                                    final saved = _answersByQuestionId[q.id];
                                    final pending =
                                        _pendingAnswersByQuestionId[q.id];
                                    final rawScore = pending ?? saved?.score;
                                    final selectedScore = rawScore != null
                                        ? normalizeScore(rawScore)
                                        : null;
                                    final globalIndex =
                                        _questions.indexOf(q);

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 900,
                                        ),
                                        child: _QuestionCard(
                                          question: q,
                                          index: globalIndex,
                                          total: _questions.length,
                                          selectedScore: selectedScore,
                                          onScoreChanged: (v) {
                                            setState(() {
                                              if (v == null || v.isEmpty) {
                                                _pendingAnswersByQuestionId
                                                    .remove(q.id);
                                              } else {
                                                _pendingAnswersByQuestionId[q.id] =
                                                    v;
                                              }
                                            });
                                          },
                                          onSaibaMais: () {
                                            setState(() {
                                              _selectedQuestion = q;
                                            });
                                          },
                                          saving: _saving,
                                          onSaveNext: _saveCurrentBlock,
                                          onPrevious: null,
                                          onNext: null,
                                          hideCodeAndPilar: widget.byPilar,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                        ),
                          if (showPanel)
                            ChatPanel(
                              questionContext: _selectedQuestion == null
                                  ? null
                                  : _buildQuestionContext(_selectedQuestion!),
                              welcomeMessage:
                                  'Alguma dúvida sobre a pergunta? Clique em "Saiba mais" na questão e eu te ajudo a responder.',
                            ),
                        ],
                      ),
                      // Botão vertical colado na borda esquerda
                      if (!_showCriteria)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => setState(() => _showCriteria = true),
                              child: Container(
                                width: 40,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: Brand.black,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(2, 0),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.rule,
                                      color: Brand.white,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 12),
                                    RotatedBox(
                                      quarterTurns: 3,
                                      child: Text(
                                        'CRITÉRIOS DE ALINHAMENTO',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Brand.white,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int currentIndex;
  final int answered;
  final int total;
  final String phaseLabel;
  final bool allAnswered;
  final VoidCallback? onPreviousBlock;
  final VoidCallback? onNextBlock;
  final VoidCallback? onSaveBlock;
  final bool saving;

  const _ProgressBar({
    required this.currentIndex,
    required this.answered,
    required this.total,
    required this.phaseLabel,
    this.allAnswered = false,
    this.onPreviousBlock,
    this.onNextBlock,
    this.onSaveBlock,
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) {
    // Barra responsiva à questão atual: progresso = (índice atual + 1) / total
    final progress = total > 0 ? (currentIndex + 1) / total : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Brand.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            phaseLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Brand.black.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (allAnswered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Todas as questões dessa sessão foram respondidas. Você pode alterar suas respostas.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Brand.black.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                allAnswered
                    ? 'Questão ${currentIndex + 1} de $total'
                    : '$answered de $total respondidas',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Brand.black,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Brand.black,
                ),
              ),
            ],
          ),
          if (onPreviousBlock != null || onNextBlock != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onPreviousBlock != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Brand.black,
                        side: const BorderSide(color: Brand.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onPreviousBlock,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Anterior'),
                    ),
                  ),
                if (onNextBlock != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Brand.black,
                      side: const BorderSide(color: Brand.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onNextBlock,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Próxima'),
                  ),
              ],
            ),
            if (onSaveBlock != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 260,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Brand.black,
                      foregroundColor: Brand.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: saving ? null : onSaveBlock,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(saving ? 'Salvando...' : 'Salvar e continuar'),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Brand.border,
              valueColor: const AlwaysStoppedAnimation<Color>(Brand.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final int index;
  final int total;
  final String? selectedScore;
  final ValueChanged<String?> onScoreChanged;
  final VoidCallback? onSaibaMais;
  final bool saving;
  final VoidCallback onSaveNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool hideCodeAndPilar;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.total,
    required this.selectedScore,
    required this.onScoreChanged,
    this.onSaibaMais,
    required this.saving,
    required this.onSaveNext,
    this.onPrevious,
    this.onNext,
    this.hideCodeAndPilar = false,
  });

  Widget _buildBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Brand.border),
      ),
      child: Text('${index + 1}/$total', style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hideCodeAndPilar) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        if (question.questionCode?.isNotEmpty == true)
                          question.questionCode!,
                        question.pilar,
                      ].join(' • '),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Brand.black,
                      ),
                    ),
                  ),
                  _buildBadge(context),
                ],
              ),
              const SizedBox(height: 10),
            ] else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_buildBadge(context)],
              ),
            const SizedBox(height: 10),
            Text(
              question.recommendation,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Alinhamento',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Brand.black.withOpacity(0.9),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: scoreOptions.take(5).map((option) {
                return RadioListTile<String>(
                  value: option,
                  groupValue: selectedScore,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    option,
                    style: const TextStyle(fontSize: 13),
                  ),
                  activeColor: Brand.black,
                  onChanged: onScoreChanged,
                );
              }).toList(),
            ),
            if (onSaibaMais != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onSaibaMais,
                  icon: const Icon(Icons.lightbulb_outline, size: 18, color: Brand.black),
                  label: const Text('Saiba mais'),
                  style: TextButton.styleFrom(
                    foregroundColor: Brand.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 0,
            color: Brand.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Brand.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Erro ao carregar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(error),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Brand.black,
                      foregroundColor: Brand.white,
                    ),
                    onPressed: onRetry,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
