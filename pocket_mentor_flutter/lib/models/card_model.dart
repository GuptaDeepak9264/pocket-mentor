enum CardType { learn, revision, interview }
enum CardSource { manual, aiGenerated, upload }
enum SRSResponse { know, dontKnow }

extension CardTypeExtension on CardType {
  String get value {
    switch (this) {
      case CardType.learn: return 'learn';
      case CardType.revision: return 'revision';
      case CardType.interview: return 'interview';
    }
  }

  static CardType fromString(String s) {
    switch (s) {
      case 'revision': return CardType.revision;
      case 'interview': return CardType.interview;
      default: return CardType.learn;
    }
  }
}

extension SRSResponseExtension on SRSResponse {
  String get value => this == SRSResponse.know ? 'know' : 'dont_know';
}

class SRSInfo {
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;
  final DateTime? lastReviewAt;
  final SRSResponse? lastResponse;

  const SRSInfo({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReviewAt,
    this.lastReviewAt,
    this.lastResponse,
  });

  factory SRSInfo.fromJson(Map<String, dynamic> json) {
    return SRSInfo(
      easeFactor: (json['ease_factor'] as num).toDouble(),
      intervalDays: json['interval_days'] as int,
      repetitions: json['repetitions'] as int,
      nextReviewAt: DateTime.parse(json['next_review_at'] as String),
      lastReviewAt: json['last_review_at'] != null
          ? DateTime.parse(json['last_review_at'] as String)
          : null,
      lastResponse: json['last_response'] != null
          ? (json['last_response'] == 'know'
              ? SRSResponse.know
              : SRSResponse.dontKnow)
          : null,
    );
  }

  bool get isDueToday => nextReviewAt.isBefore(DateTime.now());
}

class CardModel {
  final String id;
  final String topicId;
  final String userId;
  final String question;
  final String answer;
  final String? hint;
  final int difficulty;
  final CardType cardType;
  final CardSource source;
  final String? sourceFileId;
  final SRSInfo? srsInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CardModel({
    required this.id,
    required this.topicId,
    required this.userId,
    required this.question,
    required this.answer,
    this.hint,
    required this.difficulty,
    required this.cardType,
    required this.source,
    this.sourceFileId,
    this.srsInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      userId: json['user_id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      hint: json['hint'] as String?,
      difficulty: json['difficulty'] as int? ?? 3,
      cardType: CardTypeExtension.fromString(json['card_type'] as String? ?? 'learn'),
      source: _sourceFromString(json['source'] as String? ?? 'manual'),
      sourceFileId: json['source_file_id'] as String?,
      srsInfo: json['srs_info'] != null
          ? SRSInfo.fromJson(json['srs_info'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static CardSource _sourceFromString(String s) {
    switch (s) {
      case 'ai_generated': return CardSource.aiGenerated;
      case 'upload': return CardSource.upload;
      default: return CardSource.manual;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic_id': topicId,
    'user_id': userId,
    'question': question,
    'answer': answer,
    'hint': hint,
    'difficulty': difficulty,
    'card_type': cardType.value,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  CardModel copyWith({
    String? question,
    String? answer,
    String? hint,
    int? difficulty,
    CardType? cardType,
    SRSInfo? srsInfo,
  }) {
    return CardModel(
      id: id,
      topicId: topicId,
      userId: userId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      hint: hint ?? this.hint,
      difficulty: difficulty ?? this.difficulty,
      cardType: cardType ?? this.cardType,
      source: source,
      sourceFileId: sourceFileId,
      srsInfo: srsInfo ?? this.srsInfo,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
