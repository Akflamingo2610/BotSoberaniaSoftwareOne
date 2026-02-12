class Question {
  final int id;
  final String phase;
  final String pilar;
  final String? dominio;
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
    this.dominio,
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
      dominio: json['dominio']?.toString(),
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
  '100% ALINHADO - Cobertura em Toda a Organização',
  '75% ALINHADO - Cobertura Parcial – Avançado',
  '50% ALINHADO - Cobertura Parcial – Intermediário',
  '25% ALINHADO - Cobertura Parcial – Inicial',
  '0% ALINHADO - Sem Cobertura',
  'Desconhecido',
];

/// Converte o texto do score em valor percentual (0-100).
int scoreTextToPercent(String? score) {
  if (score == null || score.isEmpty) return 0;
  final s = score.toUpperCase();
  if (s.contains('100%')) return 100;
  if (s.contains('75%')) return 75;
  if (s.contains('50%')) return 50;
  if (s.contains('25%')) return 25;
  if (s.contains('0%')) return 0;
  return 0; // Desconhecido
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

/// Converte o valor exibido no dropdown para o valor aceito pela API
String scoreToApiValue(String? displayScore) {
  if (displayScore == null || displayScore.isEmpty) return apiScoreValues.last;
  final s = displayScore.trim();
  if (s.contains('100%')) return apiScoreValues[0];
  if (s.contains('75%')) return apiScoreValues[1];
  if (s.contains('50%')) return apiScoreValues[2];
  if (s.contains('25%')) return apiScoreValues[3];
  if (s.contains('0%')) return apiScoreValues[4];
  if (s.toLowerCase().contains('desconhecido')) return apiScoreValues[5];
  return apiScoreValues.last;
}

/// Normaliza o score antigo para o novo formato
String normalizeScore(String? score) {
  if (score == null || score.isEmpty) return scoreOptions.last;
  final s = score.trim();
  
  // Se já está no novo formato, retorna
  if (scoreOptions.contains(s)) return s;
  
  // Converte formato antigo para novo
  if (s.contains('100%')) return scoreOptions[0];
  if (s.contains('75%')) return scoreOptions[1];
  if (s.contains('50%')) return scoreOptions[2];
  if (s.contains('25%')) return scoreOptions[3];
  if (s.contains('0%')) return scoreOptions[4];
  if (s.toLowerCase().contains('desconhecido')) return scoreOptions[5];
  
  return scoreOptions.last; // Desconhecido como fallback
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
