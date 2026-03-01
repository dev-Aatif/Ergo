import 'dart:convert';

class Question {
  final String id;
  final String subjectId;
  final String text;
  final List<String> options;
  final int correctIndex;

  const Question({
    required this.id,
    required this.subjectId,
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      text: map['text'] as String,
      options: List<String>.from(jsonDecode(map['options'] as String)),
      correctIndex: map['correct_index'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'text': text,
      'options': jsonEncode(options),
      'correct_index': correctIndex,
    };
  }
}
