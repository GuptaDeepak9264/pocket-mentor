class AppConstants {
  // API
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator localhost
  static const String baseUrl = 'https://pocket-mentor.onrender.com/api/v1';
  static const int connectTimeoutMs = 60000;
  static const int receiveTimeoutMs = 60000;

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String lastSyncKey = 'last_sync_at';
  static const String dailyGoalKey = 'daily_goal';

  // Pagination
  static const int learnFeedLimit = 20;
  static const int revisionFeedLimit = 50;
  static const int interviewFeedLimit = 20;
  static const int sessionPageSize = 20;

  // Card flip animation
  static const int cardFlipDurationMs = 400;

  // Sync interval
  static const int syncIntervalMinutes = 15;

  // Default settings
  static const int defaultDailyGoal = 20;
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String learn = '/learn';
  static const String revision = '/revision';
  static const String interview = '/interview';
  static const String notes = '/notes';
  static const String profile = '/profile';
  static const String topicDetail = '/topic';
  static const String cardEditor = '/card-editor';
  static const String sessionSummary = '/session-summary';
}
