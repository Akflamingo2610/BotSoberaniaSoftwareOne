import 'dart:async';

import 'package:flutter/material.dart';

import '../api/xano_api.dart';
import '../l10n/app_localizations.dart';
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
  bool _gridView = false;
  int _singleQuestionOffset = 0;
  bool _saveQueued = false;

  String get _langCode {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('en')) return 'en';
    if (code.startsWith('es')) return 'es';
    return 'pt';
  }

  String _guidanceLabel() {
    switch (_langCode) {
      case 'en':
        return 'Guidance';
      case 'es':
        return 'Guia';
      default:
        return 'Orientacao';
    }
  }

  String _howToCheckLabel() {
    switch (_langCode) {
      case 'en':
        return 'How to check';
      case 'es':
        return 'Como verificar';
      default:
        return 'Como verificar';
    }
  }

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
      _singleQuestionOffset = 0;

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
      q.localizedRecommendation(_langCode),
      if ((q.guidance ?? '').trim().isNotEmpty)
        '${_guidanceLabel()}: ${q.guidance!.trim()}',
      if ((q.howToCheck ?? '').trim().isNotEmpty)
        '${_howToCheckLabel()}: ${q.howToCheck!.trim()}',
    ].join('\n\n');
  }

  /// Envia ao servidor todas as respostas ainda pendentes neste pilar (parcial).
  /// [silent]: sem SnackBar de sucesso ou de "nada para salvar" (uso no salvamento automático).
  Future<void> _saveProgress({bool silent = false}) async {
    final token = _authToken;
    final assessmentId = _assessmentId;
    if (token == null || assessmentId == null) return;
    if (_questions.isEmpty) return;

    final answersPayload = <Map<String, dynamic>>[];
    final pendingIds = <int>[];
    for (final q in _questions) {
      final pending = _pendingAnswersByQuestionId[q.id];
      if (pending == null) continue;
      final normalized = normalizeScore(pending);
      if (normalized.isEmpty) continue;
      pendingIds.add(q.id);
      answersPayload.add({
        'question_id': q.id,
        'score': scoreToApiValue(normalized),
        'justification': '',
        'evidence': '',
      });
    }

    if (answersPayload.isEmpty) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_questionUiText('nothing_to_save'))),
        );
      }
      return;
    }

    if (_saving) {
      _saveQueued = true;
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.saveAnswersBulk(
        authToken: token,
        assessmentId: assessmentId,
        answers: answersPayload,
      );

      for (final id in pendingIds) {
        final normalized = normalizeScore(_pendingAnswersByQuestionId[id]!);
        _pendingAnswersByQuestionId.remove(id);
        _answersByQuestionId[id] = SavedAnswer(
          id: -1,
          questionId: id,
          score: normalized,
        );
      }

      if (!mounted) return;
      await _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_questionUiText('save_progress_ok'))),
        );
      }
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_saveErrorText(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
      if (mounted && _saveQueued) {
        _saveQueued = false;
        unawaited(_saveProgress(silent: true));
      }
    }
  }

  void _onScoreChangedForQuestion(Question q, String? v) {
    setState(() {
      if (v == null || v.isEmpty) {
        _pendingAnswersByQuestionId.remove(q.id);
        _answersByQuestionId.remove(q.id);
      } else {
        _pendingAnswersByQuestionId[q.id] = v;
      }
    });
    if (v != null && v.isNotEmpty) {
      unawaited(_saveProgress(silent: true));
    }
  }

  /// Volta para a tela de pilares (salva posição e faz pop).
  Future<void> _goBackToPillars() async {
    await _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Quantas perguntas já têm resposta (salva no servidor ou seleção pendente).
  int get _effectiveAnsweredCount {
    var n = 0;
    for (final q in _questions) {
      if (_answersByQuestionId.containsKey(q.id)) {
        n++;
        continue;
      }
      final p = _pendingAnswersByQuestionId[q.id];
      if (p != null && normalizeScore(p).isNotEmpty) n++;
    }
    return n;
  }

  /// Verifica se todas as questões DESTE pilar foram respondidas (não das outras abas).
  bool get _allAnsweredInPhase =>
      _questions.isNotEmpty && _effectiveAnsweredCount >= _questions.length;

  void _goToPreviousBlock() {
    if (_blockStartIndex <= 0) return;
    final newStart = (_blockStartIndex - _blockSize).clamp(0, _questions.length - 1);
    setState(() {
      _blockStartIndex = newStart;
      _singleQuestionOffset = 0;
      _selectedQuestion = null;
    });
    _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
  }

  void _goToNextBlock() {
    final nextStart = _blockStartIndex + _blockSize;
    if (nextStart >= _questions.length) return;
    setState(() {
      _blockStartIndex = nextStart;
      _singleQuestionOffset = 0;
      _selectedQuestion = null;
    });
    _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
  }

  void _goToPreviousQuestion() {
    if (_singleQuestionOffset > 0) {
      setState(() => _singleQuestionOffset -= 1);
    } else if (_blockStartIndex > 0) {
      final newStart = (_blockStartIndex - _blockSize).clamp(0, _questions.length - 1);
      setState(() {
        _blockStartIndex = newStart;
        _singleQuestionOffset = _currentBlockQuestions.length - 1;
      });
      _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
    }
  }

  void _goToNextQuestion() {
    final maxOffset = _currentBlockQuestions.length - 1;
    if (_singleQuestionOffset < maxOffset) {
      setState(() => _singleQuestionOffset += 1);
    } else {
      final nextStart = _blockStartIndex + _blockSize;
      if (nextStart < _questions.length) {
        setState(() {
          _blockStartIndex = nextStart;
          _singleQuestionOffset = 0;
        });
        _storage.setLastQuestionIndex(widget.phase, _blockStartIndex);
      }
    }
  }

  String _questionUiText(String key) {
    switch (_langCode) {
      case 'en':
        switch (key) {
          case 'nothing_to_save':
            return 'Nothing to save right now.';
          case 'save_progress_ok':
            return 'Answers saved. You can continue later.';
          case 'answer_all_block':
            return 'Answer all questions in this block before continuing.';
          case 'all_answered_session':
            return 'All questions in this section have been answered. You can still change your answers.';
          case 'chat_welcome':
            return 'Any questions about the prompt? Click "Learn more" on the question and I will help you answer it.';
          case 'criteria_button':
            return 'ALIGNMENT CRITERIA';
          case 'no_questions':
            return 'No questions were found for this phase.';
          default:
            return key;
        }
      case 'es':
        switch (key) {
          case 'nothing_to_save':
            return 'No hay nada que guardar ahora.';
          case 'save_progress_ok':
            return 'Respuestas guardadas. Puede continuar más tarde.';
          case 'answer_all_block':
            return 'Responda todas las preguntas de este bloque antes de continuar.';
          case 'all_answered_session':
            return 'Todas las preguntas de esta sección fueron respondidas. Puede cambiar sus respuestas si lo desea.';
          case 'chat_welcome':
            return '¿Alguna duda sobre la pregunta? Haga clic en "Saber más" en la pregunta y le ayudaré a responder.';
          case 'criteria_button':
            return 'CRITERIOS DE ALINEAMIENTO';
          case 'no_questions':
            return 'No se encontraron preguntas para esta fase.';
          default:
            return key;
        }
      default:
        switch (key) {
          case 'nothing_to_save':
            return 'Nada para salvar no momento.';
          case 'save_progress_ok':
            return 'Respostas salvas. Você pode continuar mais tarde.';
          case 'answer_all_block':
            return 'Responda todas as perguntas deste bloco antes de continuar.';
          case 'all_answered_session':
            return 'Todas as questões dessa sessão foram respondidas. Você pode alterar suas respostas se desejar.';
          case 'chat_welcome':
            return 'Alguma dúvida sobre a pergunta? Clique em "Saiba mais" na questão e eu te ajudo a responder.';
          case 'criteria_button':
            return 'CRITERIOS DE ALINHAMENTO';
          case 'no_questions':
            return 'Nenhuma pergunta encontrada para essa fase.';
          default:
            return key;
        }
    }
  }

  String _saveErrorText(Object error) {
    switch (_langCode) {
      case 'en':
        return 'Error while saving: $error';
      case 'es':
        return 'Error al guardar: $error';
      default:
        return 'Erro ao salvar: $error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              tooltip: l10n.t('back_to_pillars'),
            ),
            IconButton(
              icon: const Icon(Icons.home_rounded),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AssessmentIntroScreen()),
                  (_) => false,
                );
              },
              tooltip: l10n.t('go_to_intro'),
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
            ? Center(
                child: Text(_questionUiText('no_questions')),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ProgressBar(
                                  phaseValue: widget.phase,
                                  currentIndex: _gridView
                                      ? _blockStartIndex
                                      : _blockStartIndex + _singleQuestionOffset,
                                  answered: _effectiveAnsweredCount,
                                  total: _questions.length,
                                  phaseLabel: widget.phaseLabel,
                                  allAnswered: _allAnsweredInPhase,
                                  onPreviousBlock:
                                      _blockStartIndex > 0 ? _goToPreviousBlock : null,
                                  onNextBlock:
                                      _blockStartIndex + _blockSize < _questions.length
                                          ? _goToNextBlock
                                          : null,
                                  gridView: _gridView,
                                  onToggleView: (value) {
                                    setState(() {
                                      _gridView = value;
                                      if (!_gridView) {
                                        _singleQuestionOffset = 0;
                                      }
                                    });
                                  },
                                ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: _showCriteria ? 0 : 40,
                                      ),
                                      child: _gridView
                                          ? SingleChildScrollView(
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
                                                final globalIndex = _questions.indexOf(q);

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
                                                      onScoreChanged: (v) =>
                                                          _onScoreChangedForQuestion(q, v),
                                                      onSaibaMais: () {
                                                        setState(() {
                                                          _selectedQuestion = q;
                                                        });
                                                      },
                                                      saving: _saving,
                                                      onPrevious: null,
                                                      onNext: null,
                                                      hideCodeAndPilar: widget.byPilar,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          )
                                        : Builder(
                                            builder: (context) {
                                              final blockQuestions = _currentBlockQuestions;
                                              final safeOffset = _singleQuestionOffset.clamp(
                                                0,
                                                blockQuestions.isEmpty
                                                    ? 0
                                                    : blockQuestions.length - 1,
                                              );
                                              final q = blockQuestions[safeOffset];
                                              final saved = _answersByQuestionId[q.id];
                                              final pending =
                                                  _pendingAnswersByQuestionId[q.id];
                                              final rawScore = pending ?? saved?.score;
                                              final selectedScore = rawScore != null
                                                  ? normalizeScore(rawScore)
                                                  : null;
                                              final globalIndex = _questions.indexOf(q);

                                              return SingleChildScrollView(
                                                padding: const EdgeInsets.all(16),
                                                child: Center(
                                                  child: ConstrainedBox(
                                                    constraints: const BoxConstraints(
                                                      maxWidth: 900,
                                                    ),
                                                    child: _QuestionCard(
                                                      question: q,
                                                      index: globalIndex,
                                                      total: _questions.length,
                                                      selectedScore: selectedScore,
                                                      onScoreChanged: (v) =>
                                                          _onScoreChangedForQuestion(q, v),
                                                      onSaibaMais: () {
                                                        setState(() {
                                                          _selectedQuestion = q;
                                                        });
                                                      },
                                                      saving: _saving,
                                                      onPrevious: (globalIndex > 0)
                                                          ? _goToPreviousQuestion
                                                          : null,
                                                      onNext: (globalIndex < _questions.length - 1)
                                                          ? _goToNextQuestion
                                                          : null,
                                                      hideCodeAndPilar: widget.byPilar,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                          ),
                          if (showPanel)
                            ChatPanel(
                              questionContext: _selectedQuestion == null
                                  ? null
                                  : _buildQuestionContext(_selectedQuestion!),
                              welcomeMessage: _questionUiText('chat_welcome'),
                            ),
                        ],
                      ),
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
                                        _questionUiText('criteria_button'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
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
  /// Valor do pilar vindo do Xano / [PhasesScreen], ex.: `Compliance`, `Continuity`, `Control`.
  final String phaseValue;
  final int currentIndex;
  final int answered;
  final int total;
  final String phaseLabel;
  final bool allAnswered;
  final VoidCallback? onPreviousBlock;
  final VoidCallback? onNextBlock;
  final bool gridView;
  final ValueChanged<bool>? onToggleView;

  const _ProgressBar({
    required this.phaseValue,
    required this.currentIndex,
    required this.answered,
    required this.total,
    required this.phaseLabel,
    this.allAnswered = false,
    this.onPreviousBlock,
    this.onNextBlock,
    this.gridView = false,
    this.onToggleView,
  });

  String _lang(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase();

  String _txt(BuildContext context, String key) {
    switch (_lang(context)) {
      case 'en':
        switch (key) {
          case 'allAnswered':
            return 'All questions in this section have been answered.';
          case 'question':
            return 'Question';
          case 'answered':
            return 'answered';
          case 'of':
            return 'of';
          case 'previous':
            return 'Previous';
          case 'next':
            return 'Next';
          default:
            return key;
        }
      case 'es':
        switch (key) {
          case 'allAnswered':
            return 'Todas las preguntas de esta sección fueron respondidas.';
          case 'question':
            return 'Pregunta';
          case 'answered':
            return 'respondidas';
          case 'of':
            return 'de';
          case 'previous':
            return 'Anterior';
          case 'next':
            return 'Siguiente';
          default:
            return key;
        }
      default:
        switch (key) {
          case 'allAnswered':
            return 'Todas as questões desta sessão foram respondidas.';
          case 'question':
            return 'Questão';
          case 'answered':
            return 'respondidas';
          case 'of':
            return 'de';
          case 'previous':
            return 'Anterior';
          case 'next':
            return 'Próxima';
          default:
            return key;
        }
    }
  }

  static const Color _pillarDarkBg = Color(0xFF1C1D1F);

  @override
  Widget build(BuildContext context) {
    // Barra e % só refletem quantas perguntas foram respondidas (não a posição de navegação).
    final progress = total > 0 ? answered / total : 0.0;
    final isPillarDark = phaseValue == 'Compliance' ||
        phaseValue == 'Continuity' ||
        phaseValue == 'Control';
    final bg = isPillarDark ? _pillarDarkBg : Brand.white;
    final fg = isPillarDark ? Colors.white : Brand.black;
    final fgMuted = isPillarDark ? Colors.white70 : Brand.black.withOpacity(0.7);
    final fgBody = isPillarDark ? Colors.white.withOpacity(0.85) : Brand.black.withOpacity(0.8);
    final progressTrack = isPillarDark ? Colors.white24 : Brand.border;
    final progressFill = isPillarDark ? Colors.white : Brand.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            phaseLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fgMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (allAnswered)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _txt(context, 'allAnswered'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: fgBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  allAnswered
                      ? '${_txt(context, 'question')} ${currentIndex + 1} ${_txt(context, 'of')} $total'
                      : '$answered ${_txt(context, 'of')} $total ${_txt(context, 'answered')}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              if (onToggleView != null)
                ToggleButtons(
                  isSelected: [gridView, !gridView],
                  borderRadius: BorderRadius.circular(999),
                  constraints: const BoxConstraints(minHeight: 32, minWidth: 40),
                  color: isPillarDark ? Colors.white54 : null,
                  selectedColor: isPillarDark ? Brand.black : null,
                  fillColor: isPillarDark ? Colors.white : null,
                  borderColor: isPillarDark ? Colors.white24 : null,
                  selectedBorderColor: isPillarDark ? Colors.white : null,
                  onPressed: (index) {
                    onToggleView!.call(index == 0);
                  },
                  children: const [
                    Icon(Icons.view_stream_rounded, size: 18),
                    Icon(Icons.crop_square_rounded, size: 18),
                  ],
                ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
              ),
            ],
          ),
          if (gridView && (onPreviousBlock != null || onNextBlock != null)) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onPreviousBlock != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isPillarDark ? Colors.white : Brand.black,
                        side: BorderSide(
                          color: isPillarDark ? Colors.white38 : Brand.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onPreviousBlock,
                      icon: Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: isPillarDark ? Colors.white : Brand.black,
                      ),
                      label: Text(_txt(context, 'previous')),
                    ),
                  ),
                if (onNextBlock != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isPillarDark ? Colors.white : Brand.black,
                      side: BorderSide(
                        color: isPillarDark ? Colors.white38 : Brand.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onNextBlock,
                    icon: Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: isPillarDark ? Colors.white : Brand.black,
                    ),
                    label: Text(_txt(context, 'next')),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: progressTrack,
              valueColor: AlwaysStoppedAnimation<Color>(progressFill),
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
    this.onPrevious,
    this.onNext,
    this.hideCodeAndPilar = false,
  });

  String _lang(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase();

  String _txt(BuildContext context, String key) {
    switch (_lang(context)) {
      case 'en':
        switch (key) {
          case 'alignment':
            return 'Alignment';
          case 'learnMore':
            return 'Learn more';
          case 'previous':
            return 'Previous';
          case 'next':
            return 'Next';
          case 'clearSelection':
            return 'Clear selection';
          default:
            return key;
        }
      case 'es':
        switch (key) {
          case 'alignment':
            return 'Alineamiento';
          case 'learnMore':
            return 'Saber más';
          case 'previous':
            return 'Anterior';
          case 'next':
            return 'Siguiente';
          case 'clearSelection':
            return 'Desmarcar';
          default:
            return key;
        }
      default:
        switch (key) {
          case 'alignment':
            return 'Alinhamento';
          case 'learnMore':
            return 'Saiba mais';
          case 'previous':
            return 'Anterior';
          case 'next':
            return 'Próxima';
          case 'clearSelection':
            return 'Desmarcar';
          default:
            return key;
        }
    }
  }

  String _scoreLabel(BuildContext context, String option) {
    switch (_lang(context)) {
      case 'en':
        switch (option) {
          case 'Totalmente alinhado':
            return 'Fully aligned';
          case 'Bem alinhado':
            return 'Well aligned';
          case 'Parcialmente alinhado':
            return 'Partially aligned';
          case 'Pouco alinhado':
            return 'Slightly aligned';
          case 'Não alinhado':
            return 'Not aligned';
          case 'Desconhecido':
            return 'Unknown';
        }
      case 'es':
        switch (option) {
          case 'Totalmente alinhado':
            return 'Totalmente alineado';
          case 'Bem alinhado':
            return 'Bien alineado';
          case 'Parcialmente alinhado':
            return 'Parcialmente alineado';
          case 'Pouco alinhado':
            return 'Poco alineado';
          case 'Não alinhado':
            return 'No alineado';
          case 'Desconhecido':
            return 'Desconocido';
        }
      default:
        return option;
    }
    return option;
  }

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
              question.localizedRecommendation(_lang(context)),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _txt(context, 'alignment'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Brand.black.withOpacity(0.9),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ListTileTheme(
              // O RadioListTile usa largura intrínseca ~kMinInteractiveDimension (48) no leading;
              // com minLeadingWidth 40 o ícone do “Desmarcar” ficava deslocado.
              data: ListTileTheme.of(context).copyWith(
                minLeadingWidth: kMinInteractiveDimension,
                horizontalTitleGap: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...scoreOptions.take(5).map((option) {
                    return RadioListTile<String>(
                      value: option,
                      groupValue: selectedScore,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _scoreLabel(context, option),
                        style: const TextStyle(fontSize: 13),
                      ),
                      activeColor: Brand.black,
                      onChanged: onScoreChanged,
                    );
                  }),
                  if (selectedScore != null) ...[
                    const SizedBox(height: 4),
                    // Desloca ícone + texto um pouco à esquerda para coincidir com o círculo do Radio.
                    Transform.translate(
                      offset: const Offset(-8, 0),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        enabled: !saving,
                        leading: SizedBox(
                          width: kMinInteractiveDimension,
                          height: kMinInteractiveDimension,
                          child: Center(
                            child: Icon(
                              Icons.clear,
                              size: 18,
                              color: Brand.black.withValues(
                                alpha: saving ? 0.35 : 0.75,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          _txt(context, 'clearSelection'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Brand.black.withValues(
                              alpha: saving ? 0.35 : 0.85,
                            ),
                          ),
                        ),
                        onTap: saving ? null : () => onScoreChanged(null),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onSaibaMais != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onSaibaMais,
                  icon: const Icon(Icons.lightbulb_outline, size: 18, color: Brand.black),
                  label: Text(_txt(context, 'learnMore')),
                  style: TextButton.styleFrom(
                    foregroundColor: Brand.black,
                  ),
                ),
              ),
            ],
            if (onPrevious != null || onNext != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: onPrevious != null
                          ? OutlinedButton.icon(
                              onPressed: onPrevious,
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: Text(_txt(context, 'previous')),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: onNext != null
                          ? OutlinedButton.icon(
                              onPressed: onNext,
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: Text(_txt(context, 'next')),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
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

  String _lang(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase();

  String _txt(BuildContext context, String key) {
    switch (_lang(context)) {
      case 'en':
        return key == 'title' ? 'Error loading' : 'Try again';
      case 'es':
        return key == 'title' ? 'Error al cargar' : 'Intentar de nuevo';
      default:
        return key == 'title' ? 'Erro ao carregar' : 'Tentar novamente';
    }
  }

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
                    _txt(context, 'title'),
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
                    child: Text(_txt(context, 'retry')),
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
