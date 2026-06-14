import 'package:flutter/material.dart';

class TopicModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String colorTag;
  final String icon;
  final bool isPublic;
  final int cardCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TopicModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.colorTag,
    required this.icon,
    required this.isPublic,
    required this.cardCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      colorTag: json['color_tag'] as String? ?? '#6366F1',
      icon: json['icon'] as String? ?? 'book',
      isPublic: json['is_public'] as bool? ?? false,
      cardCount: json['card_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'color_tag': colorTag,
    'icon': icon,
    'is_public': isPublic,
    'card_count': cardCount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Color get color {
    try {
      final hex = colorTag.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  IconData get iconData {
    const iconMap = {
      'book': Icons.menu_book_rounded,
      'code': Icons.code_rounded,
      'science': Icons.science_rounded,
      'math': Icons.calculate_rounded,
      'language': Icons.translate_rounded,
      'history': Icons.history_edu_rounded,
      'art': Icons.palette_rounded,
      'music': Icons.music_note_rounded,
      'business': Icons.business_rounded,
      'health': Icons.health_and_safety_rounded,
      'briefcase': Icons.work_rounded,
      'star': Icons.star_rounded,
      'brain': Icons.psychology_rounded,
      'flask': Icons.biotech_rounded,
    };
    return iconMap[icon] ?? Icons.menu_book_rounded;
  }

  TopicModel copyWith({
    String? title,
    String? description,
    String? colorTag,
    String? icon,
    bool? isPublic,
    int? cardCount,
  }) {
    return TopicModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      colorTag: colorTag ?? this.colorTag,
      icon: icon ?? this.icon,
      isPublic: isPublic ?? this.isPublic,
      cardCount: cardCount ?? this.cardCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
