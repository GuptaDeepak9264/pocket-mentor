import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension StringExtensions on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
}

extension DateTimeExtensions on DateTime {
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(this);
  }

  String get shortDate => DateFormat('MMM d').format(this);
  String get fullDate => DateFormat('MMMM d, y').format(this);
  String get timeOnly => DateFormat('h:mm a').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isOverdue => isBefore(DateTime.now());
}

extension IntExtensions on int {
  String get secondsToReadable {
    if (this < 60) return '${this}s';
    if (this < 3600) return '${(this / 60).floor()}m ${this % 60}s';
    final h = (this / 3600).floor();
    final m = ((this % 3600) / 60).floor();
    return '${h}h ${m}m';
  }

  String get daysToInterval {
    if (this == 0) return 'new';
    if (this == 1) return 'tomorrow';
    if (this < 7) return '${this}d';
    if (this < 30) return '${(this / 7).floor()}w';
    if (this < 365) return '${(this / 30).floor()}mo';
    return '${(this / 365).floor()}y';
  }
}

extension DoubleExtensions on double {
  String get percentString => '${(this).toStringAsFixed(0)}%';
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : null,
      ),
    );
  }
}
