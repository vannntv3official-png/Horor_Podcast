enum DownloadStatus { pending, downloading, completed, paused, failed }

class DownloadItemModel {
  final String episodeId;
  final String storyId;
  final String storyTitle;
  final String episodeTitle;
  final int episodeNumber;
  final String localFilePath;
  final int fileSizeBytes;
  final int durationSeconds;
  final String? coverPath;
  final DownloadStatus status;
  final double progress;
  final DateTime downloadedAt;
  final String? error;

  const DownloadItemModel({
    required this.episodeId,
    required this.storyId,
    required this.storyTitle,
    required this.episodeTitle,
    required this.episodeNumber,
    required this.localFilePath,
    required this.fileSizeBytes,
    required this.durationSeconds,
    this.coverPath,
    this.status = DownloadStatus.completed,
    this.progress = 1.0,
    required this.downloadedAt,
    this.error,
  });

  DownloadItemModel copyWith({
    DownloadStatus? status,
    double? progress,
    String? localFilePath,
    int? fileSizeBytes,
    String? error,
  }) {
    return DownloadItemModel(
      episodeId: episodeId,
      storyId: storyId,
      storyTitle: storyTitle,
      episodeTitle: episodeTitle,
      episodeNumber: episodeNumber,
      localFilePath: localFilePath ?? this.localFilePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      durationSeconds: durationSeconds,
      coverPath: coverPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedAt: downloadedAt,
      error: error ?? this.error,
    );
  }

  factory DownloadItemModel.fromJson(Map<String, dynamic> json) {
    return DownloadItemModel(
      episodeId: json['episodeId'] as String,
      storyId: json['storyId'] as String,
      storyTitle: json['storyTitle'] as String,
      episodeTitle: json['episodeTitle'] as String,
      episodeNumber: (json['episodeNumber'] as num?)?.toInt() ?? 1,
      localFilePath: json['localFilePath'] as String,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      coverPath: json['coverPath'] as String?,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.completed,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 1.0,
      downloadedAt: DateTime.tryParse(json['downloadedAt'] as String? ?? '') ?? DateTime.now(),
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'episodeId': episodeId,
      'storyId': storyId,
      'storyTitle': storyTitle,
      'episodeTitle': episodeTitle,
      'episodeNumber': episodeNumber,
      'localFilePath': localFilePath,
      'fileSizeBytes': fileSizeBytes,
      'durationSeconds': durationSeconds,
      'coverPath': coverPath,
      'status': status.name,
      'progress': progress,
      'downloadedAt': downloadedAt.toIso8601String(),
      'error': error,
    };
  }
}
