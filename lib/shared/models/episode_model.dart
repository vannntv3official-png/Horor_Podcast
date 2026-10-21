import '../../app/config/env_config.dart';

class EpisodeModel {
  final String id;
  final String storyId;
  final String title;
  final String? description;
  final int episodeNumber;
  final String audioPath;
  final String? audioMimeType;
  final int? audioSizeBytes;
  final int durationSeconds;
  final String status;
  final bool allowDownload;
  final DateTime? publishedAt;

  // Optional contextual fields
  final String? storyTitle;
  final String? storyCoverPath;

  const EpisodeModel({
    required this.id,
    required this.storyId,
    required this.title,
    this.description,
    required this.episodeNumber,
    required this.audioPath,
    this.audioMimeType = 'audio/mpeg',
    this.audioSizeBytes,
    this.durationSeconds = 0,
    this.status = 'published',
    this.allowDownload = true,
    this.publishedAt,
    this.storyTitle,
    this.storyCoverPath,
  });

  String getAudioUrl(String supabaseUrl) {
    if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
      return audioPath;
    }
    // Remove bucket prefix if already included in audioPath
    final cleanPath = audioPath.startsWith('podcast-audio/')
        ? audioPath.replaceFirst('podcast-audio/', '')
        : audioPath;
    return '$supabaseUrl/storage/v1/object/public/${EnvConfig.bucketPodcastAudio}/$cleanPath';
  }

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    String? storyTitle;
    String? storyCoverPath;
    if (json['stories'] != null && json['stories'] is Map) {
      storyTitle = json['stories']['title'] as String?;
      storyCoverPath = json['stories']['cover_path'] as String?;
    }

    return EpisodeModel(
      id: json['id'] as String,
      storyId: json['story_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      episodeNumber: (json['episode_number'] as num?)?.toInt() ?? 1,
      audioPath: json['audio_path'] as String,
      audioMimeType: json['audio_mime_type'] as String? ?? 'audio/mpeg',
      audioSizeBytes: (json['audio_size_bytes'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'published',
      allowDownload: json['allow_download'] as bool? ?? true,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      storyTitle: storyTitle,
      storyCoverPath: storyCoverPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'story_id': storyId,
      'title': title,
      'description': description,
      'episode_number': episodeNumber,
      'audio_path': audioPath,
      'audio_mime_type': audioMimeType,
      'audio_size_bytes': audioSizeBytes,
      'duration_seconds': durationSeconds,
      'status': status,
      'allow_download': allowDownload,
      'published_at': publishedAt?.toIso8601String(),
    };
  }
}
