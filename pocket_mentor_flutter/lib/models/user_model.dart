class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool isActive;
  final bool isVerified;
  final UserSettings settings;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.isActive,
    required this.isVerified,
    required this.settings,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      settings: UserSettings.fromJson(
        json['settings'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'is_active': isActive,
    'is_verified': isVerified,
    'settings': settings.toJson(),
    'created_at': createdAt.toIso8601String(),
  };

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    UserSettings? settings,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive,
      isVerified: isVerified,
      settings: settings ?? this.settings,
      createdAt: createdAt,
    );
  }
}

class UserSettings {
  final int dailyGoal;
  final bool notificationEnabled;
  final String notificationTime;
  final String theme;

  const UserSettings({
    this.dailyGoal = 20,
    this.notificationEnabled = true,
    this.notificationTime = '09:00',
    this.theme = 'system',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      dailyGoal: json['daily_goal'] as int? ?? 20,
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      notificationTime: json['notification_time'] as String? ?? '09:00',
      theme: json['theme'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toJson() => {
    'daily_goal': dailyGoal,
    'notification_enabled': notificationEnabled,
    'notification_time': notificationTime,
    'theme': theme,
  };

  UserSettings copyWith({
    int? dailyGoal,
    bool? notificationEnabled,
    String? notificationTime,
    String? theme,
  }) {
    return UserSettings(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      theme: theme ?? this.theme,
    );
  }
}
