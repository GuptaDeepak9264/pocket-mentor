import 'package:flutter/foundation.dart';
import '../models/progress_model.dart';
import '../services/api_service.dart';

class ProgressProvider extends ChangeNotifier {
  final ApiService _api;

  ProgressSummary _summary = ProgressSummary.empty();
  List<HeatmapEntry> _heatmap = [];
  List<StudySession> _sessions = [];
  bool _isLoading = false;
  String? _error;

  ProgressProvider({required ApiService api}) : _api = api;

  ProgressSummary get summary => _summary;
  List<HeatmapEntry> get heatmap => _heatmap;
  List<StudySession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getProgressSummary();
      _summary = ProgressSummary.fromJson(data);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHeatmap({int days = 90}) async {
    try {
      final data = await _api.getHeatmap(days: days);
      _heatmap = (data['entries'] as List<dynamic>)
          .map((e) => HeatmapEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSessions({int limit = 20}) async {
    try {
      final data = await _api.getSessions(limit: limit);
      _sessions = (data['sessions'] as List<dynamic>)
          .map((e) => StudySession.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> postSession({
    String? topicId,
    required String mode,
    required int cardsReviewed,
    required int cardsKnown,
    required int cardsUnknown,
    required int durationSeconds,
    required DateTime startedAt,
  }) async {
    try {
      await _api.postSession({
        if (topicId != null) 'topic_id': topicId,
        'mode': mode,
        'cards_reviewed': cardsReviewed,
        'cards_known': cardsKnown,
        'cards_unknown': cardsUnknown,
        'duration_seconds': durationSeconds,
        'started_at': startedAt.toIso8601String(),
        'ended_at': DateTime.now().toIso8601String(),
      });
      await loadSummary();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
