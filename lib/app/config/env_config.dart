/// Environment configuration for Khmer Horror Podcast
/// Provides secure compile-time configuration using `String.fromEnvironment`.
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://demo-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'public-anon-key-placeholder',
  );

  static const String appName = 'Khmer Horror Podcast';
  static const String appVersion = '1.0.0';
  static const String defaultLanguage = 'km';

  // Storage buckets
  static const String bucketStoryCovers = 'story-covers';
  static const String bucketPodcastAudio = 'podcast-audio';
  static const String bucketUserAvatars = 'user-avatars';

  // Limits
  static const int maxDownloadSizeBytes = 104857600; // 100MB
  static const int progressDebounceSeconds = 10;
}
