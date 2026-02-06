class Question {
  final int id;
  final String phase;
  final String pilar;
  final String recommendation;
  final String? guidance;
  final String? howToCheck;
  final int orderIndex;
  final String? questionCode;
  final String? associatedAwsService;

  Question({
    required this.id,
    required this.phase,
    required this.pilar,
    required this.recommendation,
    required this.orderIndex,
    this.guidance,
    this.howToCheck,
    this.questionCode,
    this.associatedAwsService,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: (json['id'] as num).toInt(),
      phase: (json['phase'] ?? '').toString(),
      pilar: (json['pilar'] ?? '').toString(),
      recommendation: (json['recommendation'] ?? '').toString(),
      guidance: json['guidance']?.toString(),
      howToCheck: json['how_to_check']?.toString(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      questionCode: json['question_code']?.toString(),
      associatedAwsService: json['aws_service']?.toString(),
    );
  }
}

/// Opções do enum score (devem bater com o Xano)
const scoreOptions = [
  '100% Alinhado',
  '75% Alinhado',
  '50% Alinhado',
  '25% Alinhado',
  '0% Alinhado',
  'Desconhecido',
];

/// Converte o texto do score em valor percentual (0-100).
int scoreTextToPercent(String? score) {
  if (score == null || score.isEmpty) return 0;
  if (score.contains('100%')) return 100;
  if (score.contains('75%')) return 75;
  if (score.contains('50%')) return 50;
  if (score.contains('25%')) return 25;
  if (score.contains('0%')) return 0;
  return 0; // Desconhecido
}

class SavedAnswer {
  final int id;
  final int questionId;
  final String? score;
  final String? justification;
  final String? evidence;

  SavedAnswer({
    required this.id,
    required this.questionId,
    this.score,
    this.justification,
    this.evidence,
  });

  factory SavedAnswer.fromJson(Map<String, dynamic> json) {
    return SavedAnswer(
      id: (json['id'] as num).toInt(),
      questionId: (json['question'] as num).toInt(),
      score: json['score']?.toString(),
      justification: json['justification']?.toString(),
      evidence: json['evidence']?.toString(),
    );
  }
}

class PhaseOption {
  final String value; // ex: QUICK_WINS ou Quick_Wins (depende do teu Xano)
  final String label;
  final String subtitle;

  const PhaseOption(this.value, this.label, this.subtitle);
}
