class FAQ {
  final String id;
  final String question;
  final String answer;
  final DateTime createdAt;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.createdAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
} 