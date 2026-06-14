import 'package:flutter/foundation.dart';
import '../models/feed_model.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';

enum FeedStatus { idle, loading, loaded, empty, error }

class SessionStats {
  final int cardsReviewed;
  final int cardsKnown;
  final int cardsUnknown;
  final DateTime startedAt;

  SessionStats({
    this.cardsReviewed = 0,
    this.cardsKnown = 0,
    this.cardsUnknown = 0,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  SessionStats addResult(SRSResponse response) {
    return SessionStats(
      cardsReviewed: cardsReviewed + 1,
      cardsKnown: cardsKnown + (response == SRSResponse.know ? 1 : 0),
      cardsUnknown: cardsUnknown + (response == SRSResponse.dontKnow ? 1 : 0),
      startedAt: startedAt,
    );
  }

  double get accuracy =>
      cardsReviewed == 0 ? 0 : cardsKnown / cardsReviewed * 100;

  int get durationSeconds =>
      DateTime.now().difference(startedAt).inSeconds;
}

class LearnFeedProvider extends ChangeNotifier {
  final ApiService _api;

  List<FeedCard> _cards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  FeedStatus _status = FeedStatus.idle;
  String? _error;
  SessionStats _session = SessionStats();
  String? _topicFilter;

  LearnFeedProvider({required ApiService api}) : _api = api;

  List<FeedCard> get cards => _cards;
  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;
  FeedStatus get status => _status;
  String? get error => _error;
  SessionStats get session => _session;
  String? get topicFilter => _topicFilter;

  FeedCard? get currentCard =>
      _cards.isEmpty || _currentIndex >= _cards.length
          ? null
          : _cards[_currentIndex];

  int get remaining => (_cards.length - _currentIndex).clamp(0, _cards.length);
  bool get isDone => _cards.isNotEmpty && _currentIndex >= _cards.length;
  double get progress =>
      _cards.isEmpty ? 0 : (_currentIndex / _cards.length).clamp(0.0, 1.0);

  Future<void> loadFeed({String? topicId}) async {
    _topicFilter = topicId;
    _status = FeedStatus.loading;
    _currentIndex = 0;
    _isFlipped = false;
    _session = SessionStats();
    notifyListeners();
    try {
      final data = await _api.getLearnFeed(topicId: topicId);
      _cards = (data['cards'] as List<dynamic>)
          .map((e) => FeedCard.fromJson(e as Map<String, dynamic>))
          .toList();
      _status = _cards.isEmpty ? FeedStatus.empty : FeedStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = FeedStatus.error;
    }
    notifyListeners();
  }

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  Future<void> submitResponse(SRSResponse response) async {
    final card = currentCard;
    if (card == null) return;
    _session = _session.addResult(response);
    try {
      await _api.submitCardResponse(card.id, response.value);
    } catch (_) {}
    _currentIndex++;
    _isFlipped = false;
    notifyListeners();
  }

  void resetSession() {
    _currentIndex = 0;
    _isFlipped = false;
    _session = SessionStats();
    notifyListeners();
  }
}

class RevisionFeedProvider extends ChangeNotifier {
  final ApiService _api;

  List<FeedCard> _cards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  FeedStatus _status = FeedStatus.idle;
  String? _error;
  SessionStats _session = SessionStats();
  int _dueToday = 0;
  int _overdue = 0;

  RevisionFeedProvider({required ApiService api}) : _api = api;

  List<FeedCard> get cards => _cards;
  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;
  FeedStatus get status => _status;
  String? get error => _error;
  SessionStats get session => _session;
  int get dueToday => _dueToday;
  int get overdue => _overdue;

  FeedCard? get currentCard =>
      _cards.isEmpty || _currentIndex >= _cards.length
          ? null
          : _cards[_currentIndex];

  bool get isDone => _cards.isNotEmpty && _currentIndex >= _cards.length;
  double get progress =>
      _cards.isEmpty ? 0 : (_currentIndex / _cards.length).clamp(0.0, 1.0);

  Future<void> loadFeed() async {
    _status = FeedStatus.loading;
    _currentIndex = 0;
    _isFlipped = false;
    _session = SessionStats();
    notifyListeners();
    try {
      final data = await _api.getRevisionFeed();
      _cards = (data['cards'] as List<dynamic>)
          .map((e) => FeedCard.fromJson(e as Map<String, dynamic>))
          .toList();
      _dueToday = data['due_today'] as int? ?? 0;
      _overdue = data['overdue'] as int? ?? 0;
      _status = _cards.isEmpty ? FeedStatus.empty : FeedStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = FeedStatus.error;
    }
    notifyListeners();
  }

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  Future<void> submitResponse(SRSResponse response) async {
    final card = currentCard;
    if (card == null) return;
    _session = _session.addResult(response);
    try {
      await _api.submitCardResponse(card.id, response.value);
    } catch (_) {}
    _currentIndex++;
    _isFlipped = false;
    notifyListeners();
  }
}

class InterviewFeedProvider extends ChangeNotifier {
  final ApiService _api;

  List<FeedCard> _cards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  FeedStatus _status = FeedStatus.idle;
  String? _error;
  SessionStats _session = SessionStats();
  String? _topicFilter;
  int? _difficultyFilter;

  InterviewFeedProvider({required ApiService api}) : _api = api;

  List<FeedCard> get cards => _cards;
  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;
  FeedStatus get status => _status;
  String? get error => _error;
  SessionStats get session => _session;
  String? get topicFilter => _topicFilter;
  int? get difficultyFilter => _difficultyFilter;

  FeedCard? get currentCard =>
      _cards.isEmpty || _currentIndex >= _cards.length
          ? null
          : _cards[_currentIndex];

  bool get isDone => _cards.isNotEmpty && _currentIndex >= _cards.length;
  double get progress =>
      _cards.isEmpty ? 0 : (_currentIndex / _cards.length).clamp(0.0, 1.0);

  Future<void> loadFeed({String? topicId, int? difficulty}) async {
    _topicFilter = topicId;
    _difficultyFilter = difficulty;
    _status = FeedStatus.loading;
    _currentIndex = 0;
    _isFlipped = false;
    _session = SessionStats();
    notifyListeners();
    try {
      final data = await _api.getInterviewFeed(
        topicId: topicId, difficulty: difficulty);
      _cards = (data['cards'] as List<dynamic>)
          .map((e) => FeedCard.fromJson(e as Map<String, dynamic>))
          .toList();
      _status = _cards.isEmpty ? FeedStatus.empty : FeedStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = FeedStatus.error;
    }
    notifyListeners();
  }

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  Future<void> submitResponse(SRSResponse response) async {
    final card = currentCard;
    if (card == null) return;
    _session = _session.addResult(response);
    try {
      await _api.submitCardResponse(card.id, response.value);
    } catch (_) {}
    _currentIndex++;
    _isFlipped = false;
    notifyListeners();
  }
}
