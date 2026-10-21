/// Environment configuration for Khmer Horror Podcast
/// Provides secure compile-time configuration using `String.fromEnvironment`.
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gtnzgqvwobuobzdsrpmd.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd0bnpncXZ3b2J1b2J6ZHNycG1kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI2MDE0MjYsImV4cCI6MjEwODE3NzQyNn0.X2SLfWRqv3lMmJTjf1QPbOx1DM8XV2ECeVIP7pGCD2I',
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
