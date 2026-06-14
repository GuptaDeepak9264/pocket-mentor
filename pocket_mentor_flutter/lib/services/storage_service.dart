import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // ── Auth tokens ─────────────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs!.setString(AppConstants.accessTokenKey, accessToken);
    await _prefs!.setString(AppConstants.refreshTokenKey, refreshToken);
  }

  String? get accessToken => _prefs!.getString(AppConstants.accessTokenKey);
  String? get refreshToken => _prefs!.getString(AppConstants.refreshTokenKey);

  Future<void> clearTokens() async {
    await _prefs!.remove(AppConstants.accessTokenKey);
    await _prefs!.remove(AppConstants.refreshTokenKey);
  }

  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  // ── User info ────────────────────────────────────────────────────────────────

  Future<void> saveUserId(String id) async =>
      _prefs!.setString(AppConstants.userIdKey, id);

  String? get userId => _prefs!.getString(AppConstants.userIdKey);

  Future<void> saveUserEmail(String email) async =>
      _prefs!.setString(AppConstants.userEmailKey, email);

  String? get userEmail => _prefs!.getString(AppConstants.userEmailKey);

  // ── Sync ─────────────────────────────────────────────────────────────────────

  Future<void> saveLastSync(DateTime dt) async =>
      _prefs!.setString(AppConstants.lastSyncKey, dt.toIso8601String());

  DateTime? get lastSync {
    final s = _prefs!.getString(AppConstants.lastSyncKey);
    return s != null ? DateTime.parse(s) : null;
  }

  // ── Settings ─────────────────────────────────────────────────────────────────

  Future<void> saveDailyGoal(int goal) async =>
      _prefs!.setInt(AppConstants.dailyGoalKey, goal);

  int get dailyGoal => _prefs!.getInt(AppConstants.dailyGoalKey) ?? 20;

  // ── Clear all ────────────────────────────────────────────────────────────────

  Future<void> clearAll() async => _prefs!.clear();
}
