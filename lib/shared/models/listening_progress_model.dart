class ListeningProgressModel {
  final String userId;
  final String episodeId;
  final int positionSeconds;
  final bool completed;
  final DateTime lastPlayedAt;

  // Joined fields for continue listening UI
  final String? episodeTitle;
  final String? storyTitle;
  final String? storyId;
  final String? coverPath;
  final int? durationSeconds;
  final String? audioPath;

  const ListeningProgressModel({
    required this.userId,
    required this.episodeId,
    required this.positionSeconds,
    required this.completed,
    required this.lastPlayedAt,
    this.episodeTitle,
    this.storyTitle,
    this.storyId,
    this.coverPath,
    this.durationSeconds,
    this.audioPath,
  });

  factory ListeningProgressModel.fromJson(Map<String, dynamic> json) {
    String? epTitle;
    String? stTitle;
    String? stId;
    String? cvPath;
    int? durSec;
    String? audPath;

    if (json['episodes'] != null && json['episodes'] is Map) {
      final ep = json['episodes'] as Map<String, dynamic>;
      epTitle = ep['title'] as String?;
      durSec = (ep['duration_seconds'] as num?)?.toInt();
      stId = ep['story_id'] as String?;
      audPath = ep['audio_path'] as String?;
      if (ep['stories'] != null && ep['stories'] is Map) {
        final st = ep['stories'] as Map<String, dynamic>;
        stTitle = st['title'] as String?;
        cvPath = st['cover_path'] as String?;
      }
    }

    return ListeningProgressModel(
      userId: json['user_id'] as String,
      episodeId: json['episode_id'] as String,
      positionSeconds: (json['position_seconds'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      lastPlayedAt: DateTime.tryParse(json['last_played_at'] as String? ?? '') ?? DateTime.now(),
      episodeTitle: epTitle,
      storyTitle: stTitle,
      storyId: stId,
      coverPath: cvPath,
      durationSeconds: durSec,
      audioPath: audPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'episode_id': episodeId,
      'position_seconds': positionSeconds,
      'completed': completed,
      'last_played_at': lastPlayedAt.toIso8601String(),
    };
  }
}
