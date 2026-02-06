import 'package:flutter/material.dart';

import '../api/xano_api.dart';
import '../models/models.dart' show Question, SavedAnswer, scoreOptions;
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import '../widgets/chat_panel.dart';

class QuestionsScreen extends StatefulWidget {
  final String phase;
  final String phaseLabel;

  const QuestionsScreen({
    super.key,
    required this.phase,
    required this.phaseLabel,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final _api = XanoApi();
  final _storage = AppStorage();

  bool _loading = true;
  String? _error;

  int? _assessmentId;
  String? _authToken;

  List<Question> _questions = [];
  final Map<int, SavedAnswer> _answersByQuestionId = {};

  int _index = 0;
  String? _selectedScore;
  bool _saving = false;

  @override
  void dispose() {
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

      final rawQuestions = await _api.listQuestions(
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

      _authToken = token;
      _assessmentId = assessmentId;
      _questions = questions;
      _answersByQuestionId
        ..clear()
        ..addAll(map);
      _index = startIndex;

      _hydrateControllers();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _hydrateControllers() {
    if (_questions.isEmpty) return;
    final q = _questions[_index];
    final saved = _answersByQuestionId[q.id];
    _selectedScore = saved?.score;
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

  Future<void> _saveAndNext() async {
    final token = _authToken;
    final assessmentId = _assessmentId;
    if (token == null || assessmentId == null) return;
    if (_questions.isEmpty) return;
    final score = _selectedScore;
    if (score == null || score.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma opção antes de salvar')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final q = _questions[_index];
      await _api.saveAnswer(
        authToken: token,
        assessmentId: assessmentId,
        questionId: q.id,
        score: score,
      );

      // Atualiza cache local como "salvo"
      _answersByQuestionId[q.id] = SavedAnswer(
        id: -1,
        questionId: q.id,
        score: score,
      );

      if (!mounted) return;
      if (_index < _questions.length - 1) {
        setState(() => _index++);
        _hydrateControllers();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fase concluída!')));
        Navigator.of(context).pop();
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(context, title: widget.phaseLabel),
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
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _ProgressBar(
                              answered: _questions
                                  .where((q) => _answersByQuestionId.containsKey(q.id))
                                  .length,
                              total: _questions.length,
                              phaseLabel: widget.phaseLabel,
                            ),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 720),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                child: _QuestionCard(
                                  question: _questions[_index],
                                  index: _index,
                                  total: _questions.length,
                                  selectedScore: _selectedScore,
                                  onScoreChanged: (v) =>
                                      setState(() => _selectedScore = v),
                                  saving: _saving,
                                  onSaveNext: _saveAndNext,
                                ),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                      if (showPanel)
                        ChatPanel(
                          questionContext: _buildQuestionContext(_questions[_index]),
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
  final int answered;
  final int total;
  final String phaseLabel;

  const _ProgressBar({
    required this.answered,
    required this.total,
    required this.phaseLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? answered / total : 0.0;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$answered de $total respondidas nesta fase',
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
  final bool saving;
  final VoidCallback onSaveNext;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.total,
    required this.selectedScore,
    required this.onScoreChanged,
    required this.saving,
    required this.onSaveNext,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (question.questionCode?.isNotEmpty == true) {
      parts.add(question.questionCode!);
    }
    parts.add(question.pilar);
    if ((question.associatedAwsService ?? '').trim().isNotEmpty) {
      parts.add(question.associatedAwsService!.trim());
    }
    final title = parts.join(' • ');

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Brand.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Brand.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Brand.border),
                  ),
                  child: Text(
                    '${index + 1}/$total',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
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
            if ((question.guidance ?? '').trim().isNotEmpty)
              _ExpandableText(
                title: 'Guidance',
                text: question.guidance!.trim(),
              ),
            if ((question.howToCheck ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _ExpandableText(
                  title: 'How to check',
                  text: question.howToCheck!.trim(),
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedScore,
              decoration: const InputDecoration(
                labelText: 'Alinhamento',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Selecione o nível de alinhamento'),
              items: scoreOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: onScoreChanged,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.black,
                foregroundColor: Brand.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: saving ? null : onSaveNext,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(saving ? 'Salvando...' : 'Salvar e continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableText extends StatelessWidget {
  final String title;
  final String text;
  const _ExpandableText({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
          ),
        ),
      ],
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
