import 'dart:convert';

class QuizAttempt {
  final String id;
  final String categoryId;
  final DateTime date;
  final int score;
  final int totalQuestions;
  final int timeTakenSeconds;
  final List<String> missedQuestionIds;

  const QuizAttempt({
    required this.id,
    required this.categoryId,
    required this.date,
    required this.score,
    required this.totalQuestions,
    required this.timeTakenSeconds,
    required this.missedQuestionIds,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      score: map['score'] as int,
      totalQuestions: map['total_questions'] as int,
      timeTakenSeconds: map['time_taken'] as int,
      missedQuestionIds:
          List<String>.from(jsonDecode(map['missed_question_ids'] as String)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'date': date.millisecondsSinceEpoch,
      'score': score,
      'total_questions': totalQuestions,
      'time_taken': timeTakenSeconds,
      'missed_question_ids': jsonEncode(missedQuestionIds),
    };
  }
}
