class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String grammarType;
  final String level;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.grammarType,
    required this.level,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correct_answer'],
      grammarType: json['grammar_type'],
      level: json['level'], // This must be present
    );
  }
}
