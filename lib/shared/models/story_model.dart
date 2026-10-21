import '../../app/config/env_config.dart';

class StoryModel {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final String? coverPath;
  final String? categoryId;
  final String? categoryName;
  final String? narratorName;
  final String status;
  final bool isFeatured;
  final DateTime? publishedAt;
  final int episodeCount;
  final int totalDurationSeconds;

  const StoryModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.coverPath,
    this.categoryId,
    this.categoryName,
    this.narratorName,
    this.status = 'published',
    this.isFeatured = false,
    this.publishedAt,
    this.episodeCount = 0,
    this.totalDurationSeconds = 0,
  });

  String getCoverUrl(String supabaseUrl) {
    if (coverPath == null || coverPath!.isEmpty) {
      return '';
    }
    if (coverPath!.startsWith('http://') || coverPath!.startsWith('https://')) {
      return coverPath!;
    }
    return '$supabaseUrl/storage/v1/object/public/${EnvConfig.bucketStoryCovers}/$coverPath';
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    String? categoryName;
    if (json['categories'] != null && json['categories'] is Map) {
      categoryName = json['categories']['name'] as String?;
    }

    return StoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      coverPath: json['cover_path'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: categoryName,
      narratorName: json['narrator_name'] as String?,
      status: json['status'] as String? ?? 'published',
      isFeatured: json['is_featured'] as bool? ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      episodeCount: (json['episode_count'] as num?)?.toInt() ?? 0,
      totalDurationSeconds: (json['total_duration'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'cover_path': coverPath,
      'category_id': categoryId,
      'narrator_name': narratorName,
      'status': status,
      'is_featured': isFeatured,
      'published_at': publishedAt?.toIso8601String(),
    };
  }
}
