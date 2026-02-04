class Question {
  final int id;
  final String phase;
  final String pilar;
  final String recommendation;
  final String? guidance;
  final String? howToCheck;
  final int orderIndex;
  final String? questionCode;

  Question({
    required this.id,
    required this.phase,
    required this.pilar,
    required this.recommendation,
    required this.orderIndex,
    this.guidance,
    this.howToCheck,
    this.questionCode,
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
    );
  }
}

class SavedAnswer {
  final int id;
  final int questionId;
  final String? justification;
  final String? evidence;

  SavedAnswer({
    required this.id,
    required this.questionId,
    this.justification,
    this.evidence,
  });

  factory SavedAnswer.fromJson(Map<String, dynamic> json) {
    return SavedAnswer(
      id: (json['id'] as num).toInt(),
      questionId: (json['question'] as num).toInt(),
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
