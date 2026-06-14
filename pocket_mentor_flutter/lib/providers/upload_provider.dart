import 'package:flutter/foundation.dart';
import '../models/upload_model.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';

enum UploadStatus { idle, uploading, polling, done, failed }

class UploadProvider extends ChangeNotifier {
  final ApiService _api;

  List<UploadModel> _uploads = [];
  UploadStatus _uploadStatus = UploadStatus.idle;
  List<CardModel> _generatedCards = [];
  String? _activeUploadId;
  double _uploadProgress = 0;
  String? _error;

  UploadProvider({required ApiService api}) : _api = api;

  List<UploadModel> get uploads => List.unmodifiable(_uploads);
  UploadStatus get uploadStatus => _uploadStatus;
  List<CardModel> get generatedCards => List.unmodifiable(_generatedCards);
  String? get activeUploadId => _activeUploadId;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  bool get isUploading => _uploadStatus == UploadStatus.uploading;
  bool get isPolling => _uploadStatus == UploadStatus.polling;

  Future<void> loadUploads() async {
    try {
      final list = await _api.getUploads();
      _uploads = list
          .map((e) => UploadModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> uploadFile({
    required String filePath,
    required String fileName,
    String? topicId,
  }) async {
    _uploadStatus = UploadStatus.uploading;
    _uploadProgress = 0;
    _error = null;
    _generatedCards = [];
    notifyListeners();

    try {
      final data = await _api.uploadFile(
        filePath: filePath,
        fileName: fileName,
        topicId: topicId,
      );
      final upload = UploadModel.fromJson(data);
      _uploads.insert(0, upload);
      _activeUploadId = upload.id;
      _uploadStatus = UploadStatus.polling;
      notifyListeners();

      // Poll for completion
      await _pollUntilDone(upload.id);
      return true;
    } catch (e) {
      _error = e.toString();
      _uploadStatus = UploadStatus.failed;
      notifyListeners();
      return false;
    }
  }

  Future<void> _pollUntilDone(String uploadId) async {
    const maxAttempts = 30;
    var attempts = 0;

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 2));
      attempts++;

      try {
        final statusData = await _api.getUploadStatus(uploadId);
        final status = statusData['parse_status'] as String;

        // Update in list
        final idx = _uploads.indexWhere((u) => u.id == uploadId);
        if (idx != -1) {
          _uploads[idx] = UploadModel.fromJson({
            ..._uploads[idx].toJson(),
            ...statusData,
          });
        }

        if (status == 'done') {
          await _fetchGeneratedCards(uploadId);
          _uploadStatus = UploadStatus.done;
          notifyListeners();
          return;
        } else if (status == 'failed') {
          _error = statusData['error_message'] as String? ?? 'Processing failed';
          _uploadStatus = UploadStatus.failed;
          notifyListeners();
          return;
        }

        // Still processing — update progress visually
        _uploadProgress = (attempts / maxAttempts).clamp(0.0, 0.9);
        notifyListeners();
      } catch (_) {}
    }

    _error = 'Processing timed out. Please try again.';
    _uploadStatus = UploadStatus.failed;
    notifyListeners();
  }

  Future<void> _fetchGeneratedCards(String uploadId) async {
    try {
      final data = await _api.getUploadCards(uploadId);
      _generatedCards = (data['cards'] as List<dynamic>)
          .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _uploadProgress = 1.0;
    } catch (_) {}
  }

  Future<void> deleteUpload(String uploadId) async {
    try {
      await _api.deleteUpload(uploadId);
      _uploads.removeWhere((u) => u.id == uploadId);
      if (_activeUploadId == uploadId) {
        _activeUploadId = null;
        _uploadStatus = UploadStatus.idle;
        _generatedCards = [];
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void resetUploadState() {
    _uploadStatus = UploadStatus.idle;
    _uploadProgress = 0;
    _error = null;
    _generatedCards = [];
    _activeUploadId = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

extension _UploadModelJson on UploadModel {
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'topic_id': topicId,
    'original_filename': originalFilename,
    'file_type': fileType,
    'file_size_bytes': fileSizeBytes,
    'parse_status': parseStatus.name,
    'cards_generated': cardsGenerated,
    'error_message': errorMessage,
    'uploaded_at': uploadedAt.toIso8601String(),
    'processed_at': processedAt?.toIso8601String(),
  };
}
