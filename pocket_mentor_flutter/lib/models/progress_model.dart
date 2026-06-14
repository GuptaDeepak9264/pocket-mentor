class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int totalCardsReviewed;
  final int totalSessions;

  const StreakModel({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
    required this.totalCardsReviewed,
    required this.totalSessions,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.parse(json['last_active_date'] as String)
          : null,
      totalCardsReviewed: json['total_cards_reviewed'] as int? ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
    );
  }

  factory StreakModel.empty() => const StreakModel(
    currentStreak: 0,
    longestStreak: 0,
    totalCardsReviewed: 0,
    totalSessions: 0,
  );
}

class TopicProgress {
  final String topicId;
  final String topicTitle;
  final String topicColor;
  final int totalCards;
  final int cardsKnown;
  final int cardsDueToday;
  final double masteryPercent;

  const TopicProgress({
    required this.topicId,
    required this.topicTitle,
    required this.topicColor,
    required this.totalCards,
    required this.cardsKnown,
    required this.cardsDueToday,
    required this.masteryPercent,
  });

  factory TopicProgress.fromJson(Map<String, dynamic> json) {
    return TopicProgress(
      topicId: json['topic_id'] as String,
      topicTitle: json['topic_title'] as String,
      topicColor: json['topic_color'] as String? ?? '#6366F1',
      totalCards: json['total_cards'] as int? ?? 0,
      cardsKnown: json['cards_known'] as int? ?? 0,
      cardsDueToday: json['cards_due_today'] as int? ?? 0,
      masteryPercent: (json['mastery_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProgressSummary {
  final StreakModel streak;
  final int todayCardsReviewed;
  final int todayGoal;
  final bool todayGoalMet;
  final int sessionsThisWeek;
  final int totalCardsInLibrary;
  final int cardsDueToday;
  final List<TopicProgress> topicProgress;

  const ProgressSummary({
    required this.streak,
    required this.todayCardsReviewed,
    required this.todayGoal,
    required this.todayGoalMet,
    required this.sessionsThisWeek,
    required this.totalCardsInLibrary,
    required this.cardsDueToday,
    required this.topicProgress,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      streak: StreakModel.fromJson(json['streak'] as Map<String, dynamic>),
      todayCardsReviewed: json['today_cards_reviewed'] as int? ?? 0,
      todayGoal: json['today_goal'] as int? ?? 20,
      todayGoalMet: json['today_goal_met'] as bool? ?? false,
      sessionsThisWeek: json['sessions_this_week'] as int? ?? 0,
      totalCardsInLibrary: json['total_cards_in_library'] as int? ?? 0,
      cardsDueToday: json['cards_due_today'] as int? ?? 0,
      topicProgress: (json['topic_progress'] as List<dynamic>? ?? [])
          .map((e) => TopicProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory ProgressSummary.empty() => ProgressSummary(
    streak: StreakModel.empty(),
    todayCardsReviewed: 0,
    todayGoal: 20,
    todayGoalMet: false,
    sessionsThisWeek: 0,
    totalCardsInLibrary: 0,
    cardsDueToday: 0,
    topicProgress: [],
  );

  double get todayProgress =>
      todayGoal == 0 ? 0 : (todayCardsReviewed / todayGoal).clamp(0.0, 1.0);
}

class HeatmapEntry {
  final DateTime date;
  final int cardsReviewed;
  final int sessions;

  const HeatmapEntry({
    required this.date,
    required this.cardsReviewed,
    required this.sessions,
  });

  factory HeatmapEntry.fromJson(Map<String, dynamic> json) {
    return HeatmapEntry(
      date: DateTime.parse(json['date'] as String),
      cardsReviewed: json['cards_reviewed'] as int? ?? 0,
      sessions: json['sessions'] as int? ?? 0,
    );
  }
}

class StudySession {
  final String id;
  final String userId;
  final String? topicId;
  final String mode;
  final int cardsReviewed;
  final int cardsKnown;
  final int cardsUnknown;
  final int durationSeconds;
  final double accuracyPercent;
  final DateTime startedAt;
  final DateTime? endedAt;

  const StudySession({
    required this.id,
    required this.userId,
    this.topicId,
    required this.mode,
    required this.cardsReviewed,
    required this.cardsKnown,
    required this.cardsUnknown,
    required this.durationSeconds,
    required this.accuracyPercent,
    required this.startedAt,
    this.endedAt,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      topicId: json['topic_id'] as String?,
      mode: json['mode'] as String,
      cardsReviewed: json['cards_reviewed'] as int? ?? 0,
      cardsKnown: json['cards_known'] as int? ?? 0,
      cardsUnknown: json['cards_unknown'] as int? ?? 0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      accuracyPercent: (json['accuracy_percent'] as num?)?.toDouble() ?? 0.0,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }
}
