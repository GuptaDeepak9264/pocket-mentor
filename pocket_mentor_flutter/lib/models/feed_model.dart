import 'package:flutter/material.dart';
import 'card_model.dart';

class FeedCard {
  final String id;
  final String topicId;
  final String topicTitle;
  final String topicColor;
  final String question;
  final String answer;
  final String? hint;
  final int difficulty;
  final CardType cardType;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;

  const FeedCard({
    required this.id,
    required this.topicId,
    required this.topicTitle,
    required this.topicColor,
    required this.question,
    required this.answer,
    this.hint,
    required this.difficulty,
    required this.cardType,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReviewAt,
  });

  factory FeedCard.fromJson(Map<String, dynamic> json) {
    return FeedCard(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      topicTitle: json['topic_title'] as String,
      topicColor: json['topic_color'] as String? ?? '#6366F1',
      question: json['question'] as String,
      answer: json['answer'] as String,
      hint: json['hint'] as String?,
      difficulty: json['difficulty'] as int? ?? 3,
      cardType: CardTypeExtension.fromString(json['card_type'] as String? ?? 'learn'),
      intervalDays: json['interval_days'] as int? ?? 1,
      repetitions: json['repetitions'] as int? ?? 0,
      nextReviewAt: DateTime.parse(json['next_review_at'] as String),
    );
  }

  bool get isNew => repetitions == 0;
  bool get isDue => nextReviewAt.isBefore(DateTime.now());

  Color get color {
    try {
      final hex = topicColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }
}
