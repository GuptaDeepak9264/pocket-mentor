import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthProvider({required ApiService api, required StorageService storage})
      : _api = api,
        _storage = storage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // ── Boot check ───────────────────────────────────────────────────────────────

  Future<void> checkAuth() async {
    if (!_storage.isLoggedIn) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final json = await _api.getMe();
      _user = UserModel.fromJson(json);
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      await _storage.clearTokens();
    }
    notifyListeners();
  }

  // ── Register ─────────────────────────────────────────────────────────────────

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final tokenData = await _api.register(
        email: email, password: password, displayName: displayName);
      await _storage.saveTokens(
        accessToken: tokenData['access_token'] as String,
        refreshToken: tokenData['refresh_token'] as String,
      );
      final userJson = await _api.getMe();
      _user = UserModel.fromJson(userJson);
      await _storage.saveUserId(_user!.id);
      await _storage.saveUserEmail(_user!.email);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────────

  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final tokenData = await _api.login(email: email, password: password);
      await _storage.saveTokens(
        accessToken: tokenData['access_token'] as String,
        refreshToken: tokenData['refresh_token'] as String,
      );
      final userJson = await _api.getMe();
      _user = UserModel.fromJson(userJson);
      await _storage.saveUserId(_user!.id);
      await _storage.saveUserEmail(_user!.email);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final rt = _storage.refreshToken;
    if (rt != null) {
      try { await _api.logout(rt); } catch (_) {}
    }
    await _storage.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Update profile ───────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? displayName,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['display_name'] = displayName;
      if (settings != null) data['settings'] = settings;
      final json = await _api.updateMe(data);
      _user = UserModel.fromJson(json);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  String _extractError(dynamic e) {
    try {
      final response = (e as dynamic).response;
      if (response != null) {
        final detail = response.data['detail'];
        if (detail is String) return detail;
      }
    } catch (_) {}
    return e.toString();
  }
}
