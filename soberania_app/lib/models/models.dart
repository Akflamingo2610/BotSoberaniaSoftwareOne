class Question {
  final int id;
  final String phase;
  final String pilar;
  final String? dominio;
  final String recommendation;
  final String? recommendationEn;
  final String? recommendationEs;
  final String? guidance;
  final String? howToCheck;
  final int orderIndex;
  final String? questionCode;
  final String? associatedAwsService;

  Question({
    required this.id,
    required this.phase,
    required this.pilar,
    this.dominio,
    required this.recommendation,
    this.recommendationEn,
    this.recommendationEs,
    required this.orderIndex,
    this.guidance,
    this.howToCheck,
    this.questionCode,
    this.associatedAwsService,
  });

  String localizedRecommendation(String langCode) {
    if (langCode == 'en' && (recommendationEn ?? '').isNotEmpty) {
      return recommendationEn!;
    }
    if (langCode == 'es' && (recommendationEs ?? '').isNotEmpty) {
      return recommendationEs!;
    }
    return recommendation;
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: (json['id'] as num).toInt(),
      phase: (json['phase'] ?? '').toString(),
      pilar: (json['pilar'] ?? '').toString(),
      dominio: json['dominio']?.toString(),
      recommendation: (json['recommendation'] ?? '').toString(),
      recommendationEn: json['recommendation_en']?.toString(),
      recommendationEs: json['recommendation_es']?.toString(),
      guidance: json['guidance']?.toString(),
      howToCheck: json['how_to_check']?.toString(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      questionCode: json['question_code']?.toString(),
      associatedAwsService: json['aws_service']?.toString(),
    );
  }
}

/// Opções exibidas nas bolinhas (radio) – apenas o rótulo
const scoreOptions = [
  'Totalmente alinhado',
  'Bem alinhado',
  'Parcialmente alinhado',
  'Pouco alinhado',
  'Não alinhado',
  'Desconhecido',
];

/// Converte o texto do score em valor percentual (0-100).
int scoreTextToPercent(String? score) {
  if (score == null || score.isEmpty) return 0;
  final s = score.trim().toLowerCase();
  if (s.contains('totalmente alinhado') || s.contains('100%')) return 100;
  if (s.contains('bem alinhado') || s.contains('75%')) return 75;
  if (s.contains('parcialmente alinhado') || s.contains('50%')) return 50;
  if (s.contains('pouco alinhado') || s.contains('25%')) return 25;
  if (s.contains('não alinhado') || s.contains('nao alinhado') || s.contains('0%')) return 0;
  return 0;
}

/// Valores aceitos pela API/Xano (enum da coluna score)
const apiScoreValues = [
  '100% Alinhado',
  '75% Alinhado',
  '50% Alinhado',
  '25% Alinhado',
  '0% Alinhado',
  'Desconhecido',
];

/// Converte o valor exibido (radio) para o valor aceito pela API
String scoreToApiValue(String? displayScore) {
  if (displayScore == null || displayScore.isEmpty) return apiScoreValues.last;
  final s = displayScore.trim().toLowerCase();
  if (s.contains('totalmente alinhado') || s.contains('100%')) return apiScoreValues[0];
  if (s.contains('bem alinhado') || s.contains('75%')) return apiScoreValues[1];
  if (s.contains('parcialmente alinhado') || s.contains('50%')) return apiScoreValues[2];
  if (s.contains('pouco alinhado') || s.contains('25%')) return apiScoreValues[3];
  if (s.contains('não alinhado') || s.contains('nao alinhado') || s.contains('0%')) return apiScoreValues[4];
  if (s.contains('desconhecido')) return apiScoreValues[5];
  return apiScoreValues.last;
}

/// Normaliza o score (antigo ou API) para o texto exibido nas opções
String normalizeScore(String? score) {
  if (score == null || score.isEmpty) return scoreOptions[5]; // Desconhecido
  final s = score.trim();
  if (scoreOptions.contains(s)) return s;
  final lower = s.toLowerCase();
  if (lower.contains('totalmente') || s.contains('100%')) return scoreOptions[0];
  if (lower.contains('bem alinhado') || s.contains('75%')) return scoreOptions[1];
  if (lower.contains('parcialmente') || s.contains('50%')) return scoreOptions[2];
  if (lower.contains('pouco alinhado') || s.contains('25%')) return scoreOptions[3];
  if (lower.contains('não alinhado') || lower.contains('nao alinhado') || s.contains('0%')) return scoreOptions[4];
  if (lower.contains('desconhecido')) return scoreOptions[5];
  return scoreOptions[5];
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
