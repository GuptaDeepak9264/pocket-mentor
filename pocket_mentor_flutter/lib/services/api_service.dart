import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  late final StorageService _storage;

  ApiService._();

  static Future<ApiService> getInstance() async {
    if (_instance == null) {
      _instance = ApiService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _storage = await StorageService.getInstance();
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            // Retry original request with new token
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${_storage.accessToken}';
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await Dio().post(
        '${AppConstants.baseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      await _storage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      await _storage.clearTokens();
      return false;
    }
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'display_name': displayName,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final response = await _dio.patch('/auth/me', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout(String refreshToken) async {
    await _dio.delete('/auth/logout', data: {'refresh_token': refreshToken});
  }

  // ── Topics ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTopics() async {
    final response = await _dio.get('/topics');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTopic(Map<String, dynamic> data) async {
    final response = await _dio.post('/topics', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTopic(
    String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/topics/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteTopic(String id) async {
    await _dio.delete('/topics/$id');
  }

  // ── Cards ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCards(String topicId,
      {String? cardType}) async {
    final response = await _dio.get(
      '/topics/$topicId/cards',
      queryParameters: cardType != null ? {'card_type': cardType} : null,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createCard(
    String topicId, Map<String, dynamic> data) async {
    final response = await _dio.post('/topics/$topicId/cards', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCard(
    String cardId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/cards/$cardId', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteCard(String cardId) async {
    await _dio.delete('/cards/$cardId');
  }

  Future<Map<String, dynamic>> submitCardResponse(
    String cardId, String result) async {
    final response = await _dio.post(
      '/cards/$cardId/response',
      data: {'result': result},
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Feeds ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getLearnFeed({
    String? topicId, int limit = 20}) async {
    final response = await _dio.get('/feed/learn', queryParameters: {
      if (topicId != null) 'topic_id': topicId,
      'limit': limit,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRevisionFeed({int limit = 50}) async {
    final response = await _dio.get('/feed/revision',
        queryParameters: {'limit': limit});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInterviewFeed({
    String? topicId, int? difficulty, int limit = 20}) async {
    final response = await _dio.get('/feed/interview', queryParameters: {
      if (topicId != null) 'topic_id': topicId,
      if (difficulty != null) 'difficulty': difficulty,
      'limit': limit,
    });
    return response.data as Map<String, dynamic>;
  }

  // ── Uploads ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
    String? topicId,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      if (topicId != null) 'topic_id': topicId,
    });
    final response = await _dio.post('/uploads', data: formData);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUploadStatus(String uploadId) async {
    final response = await _dio.get('/uploads/$uploadId/status');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUploadCards(String uploadId) async {
    final response = await _dio.get('/uploads/$uploadId/cards');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getUploads() async {
    final response = await _dio.get('/uploads');
    final data = response.data as Map<String, dynamic>;
    return data['uploads'] as List<dynamic>;
  }

  Future<void> deleteUpload(String uploadId) async {
    await _dio.delete('/uploads/$uploadId');
  }

  // ── Progress ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProgressSummary() async {
    final response = await _dio.get('/progress/summary');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postSession(
    Map<String, dynamic> data) async {
    final response = await _dio.post('/progress/sessions', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSessions({
    int limit = 20, int offset = 0}) async {
    final response = await _dio.get('/progress/sessions',
        queryParameters: {'limit': limit, 'offset': offset});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHeatmap({int days = 90}) async {
    final response = await _dio.get('/progress/heatmap',
        queryParameters: {'days': days});
    return response.data as Map<String, dynamic>;
  }
}
