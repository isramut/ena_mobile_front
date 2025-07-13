// Modèles pour les données du quiz provenant de l'API

class QuizResponse {
  final List<QuizModule> modules;
  final QuizSummary summary;
  final String loadTimestamp;

  QuizResponse({
    required this.modules,
    required this.summary,
    required this.loadTimestamp,
  });

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      modules: (json['modules'] as List)
          .map((module) => QuizModule.fromJson(module))
          .toList(),
      summary: QuizSummary.fromJson(json['summary']),
      loadTimestamp: json['load_timestamp'] ?? '',
    );
  }
}

class QuizModule {
  final String id;
  final String title;
  final String description;
  final String level;
  final int difficulty;
  final int durationMinutes;
  final int orderPosition;
  final bool isActive;
  final String createdAt;
  final QuizMetadata metadata;
  final List<QuizQuestion> questions;

  QuizModule({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.difficulty,
    required this.durationMinutes,
    required this.orderPosition,
    required this.isActive,
    required this.createdAt,
    required this.metadata,
    required this.questions,
  });

  factory QuizModule.fromJson(Map<String, dynamic> json) {
    return QuizModule(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      level: json['level'] ?? '',
      difficulty: json['difficulty'] ?? 1,
      durationMinutes: json['duration_minutes'] ?? 0,
      orderPosition: json['order_position'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      metadata: QuizMetadata.fromJson(json['metadata'] ?? {}),
      questions: (json['questions'] as List? ?? [])
          .map((question) => QuizQuestion.fromJson(question))
          .toList(),
    );
  }
}

class QuizMetadata {
  final int totalQuestions;
  final int totalPoints;
  final double estimatedDuration;

  QuizMetadata({
    required this.totalQuestions,
    required this.totalPoints,
    required this.estimatedDuration,
  });

  factory QuizMetadata.fromJson(Map<String, dynamic> json) {
    return QuizMetadata(
      totalQuestions: json['total_questions'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
      estimatedDuration: (json['estimated_duration'] ?? 0.0).toDouble(),
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctOption;
  final String difficulty;
  final int timeLimitSeconds;
  final String type;
  final int points;
  final String explanation;
  final int orderPosition;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.difficulty,
    required this.timeLimitSeconds,
    required this.type,
    required this.points,
    required this.explanation,
    required this.orderPosition,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctOption: json['correct_option'] ?? 0,
      difficulty: json['difficulty'] ?? '',
      timeLimitSeconds: json['time_limit_seconds'] ?? 60,
      type: json['type'] ?? 'multiple_choice',
      points: json['points'] ?? 1,
      explanation: json['explanation'] ?? '',
      orderPosition: json['order_position'] ?? 0,
    );
  }
}

class QuizSummary {
  final int totalModules;
  final int totalQuestions;
  final int totalPoints;
  final List<String> levelsAvailable;
  final Map<String, dynamic> filtersApplied;

  QuizSummary({
    required this.totalModules,
    required this.totalQuestions,
    required this.totalPoints,
    required this.levelsAvailable,
    required this.filtersApplied,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    return QuizSummary(
      totalModules: json['total_modules'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
      levelsAvailable: List<String>.from(json['levels_available'] ?? []),
      filtersApplied: json['filters_applied'] ?? {},
    );
  }
}

// Modèle pour les réponses de l'utilisateur
class UserQuizAnswer {
  final String questionId;
  final int selectedOption;
  final bool isCorrect;
  final int pointsEarned;
  final DateTime answeredAt;

  UserQuizAnswer({
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.pointsEarned,
    required this.answeredAt,
  });
}

// Modèle pour les résultats du quiz
class QuizResult {
  final String moduleId;
  final String moduleTitle;
  final List<UserQuizAnswer> answers;
  final int totalQuestions;
  final int correctAnswers;
  final int totalPoints;
  final int earnedPoints;
  final Duration totalTime;
  final double percentage;

  QuizResult({
    required this.moduleId,
    required this.moduleTitle,
    required this.answers,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalPoints,
    required this.earnedPoints,
    required this.totalTime,
    required this.percentage,
  });

  double get score => (correctAnswers / totalQuestions) * 100;
  
  String get grade {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 80) return 'Très bien';
    if (percentage >= 70) return 'Bien';
    if (percentage >= 60) return 'Assez bien';
    return 'Insuffisant';
  }
}
