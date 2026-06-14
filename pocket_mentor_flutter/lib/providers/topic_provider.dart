import 'package:flutter/foundation.dart';
import '../models/topic_model.dart';
import '../services/api_service.dart';

class TopicProvider extends ChangeNotifier {
  final ApiService _api;

  List<TopicModel> _topics = [];
  bool _isLoading = false;
  String? _error;

  TopicProvider({required ApiService api}) : _api = api;

  List<TopicModel> get topics => List.unmodifiable(_topics);
  bool get isLoading => _isLoading;
  String? get error => _error;

  TopicModel? getById(String id) {
    try {
      return _topics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadTopics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getTopics();
      _topics = (data['topics'] as List<dynamic>)
          .map((e) => TopicModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<TopicModel?> createTopic({
    required String title,
    String? description,
    String colorTag = '#6366F1',
    String icon = 'book',
  }) async {
    try {
      final data = await _api.createTopic({
        'title': title,
        if (description != null) 'description': description,
        'color_tag': colorTag,
        'icon': icon,
      });
      final topic = TopicModel.fromJson(data);
      _topics.insert(0, topic);
      notifyListeners();
      return topic;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTopic(String id, Map<String, dynamic> updates) async {
    try {
      final data = await _api.updateTopic(id, updates);
      final updated = TopicModel.fromJson(data);
      final idx = _topics.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _topics[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTopic(String id) async {
    try {
      await _api.deleteTopic(id);
      _topics.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void incrementCardCount(String topicId) {
    final idx = _topics.indexWhere((t) => t.id == topicId);
    if (idx != -1) {
      _topics[idx] = _topics[idx].copyWith(
        cardCount: _topics[idx].cardCount + 1,
      );
      notifyListeners();
    }
  }

  void decrementCardCount(String topicId) {
    final idx = _topics.indexWhere((t) => t.id == topicId);
    if (idx != -1) {
      final newCount = (_topics[idx].cardCount - 1).clamp(0, 9999);
      _topics[idx] = _topics[idx].copyWith(cardCount: newCount);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
