enum ParseStatus { pending, processing, done, failed }

class UploadModel {
  final String id;
  final String userId;
  final String? topicId;
  final String originalFilename;
  final String fileType;
  final int? fileSizeBytes;
  final ParseStatus parseStatus;
  final int cardsGenerated;
  final String? errorMessage;
  final DateTime uploadedAt;
  final DateTime? processedAt;

  const UploadModel({
    required this.id,
    required this.userId,
    this.topicId,
    required this.originalFilename,
    required this.fileType,
    this.fileSizeBytes,
    required this.parseStatus,
    required this.cardsGenerated,
    this.errorMessage,
    required this.uploadedAt,
    this.processedAt,
  });

  factory UploadModel.fromJson(Map<String, dynamic> json) {
    return UploadModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      topicId: json['topic_id'] as String?,
      originalFilename: json['original_filename'] as String,
      fileType: json['file_type'] as String,
      fileSizeBytes: json['file_size_bytes'] as int?,
      parseStatus: _parseStatusFromString(json['parse_status'] as String? ?? 'pending'),
      cardsGenerated: json['cards_generated'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }

  static ParseStatus _parseStatusFromString(String s) {
    switch (s) {
      case 'processing': return ParseStatus.processing;
      case 'done': return ParseStatus.done;
      case 'failed': return ParseStatus.failed;
      default: return ParseStatus.pending;
    }
  }

  bool get isProcessing =>
      parseStatus == ParseStatus.pending || parseStatus == ParseStatus.processing;

  bool get isDone => parseStatus == ParseStatus.done;
  bool get isFailed => parseStatus == ParseStatus.failed;

  String get statusLabel {
    switch (parseStatus) {
      case ParseStatus.pending: return 'Pending';
      case ParseStatus.processing: return 'Processing…';
      case ParseStatus.done: return '$cardsGenerated cards generated';
      case ParseStatus.failed: return 'Failed';
    }
  }

  String get fileSizeLabel {
    if (fileSizeBytes == null) return '';
    final kb = fileSizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}
