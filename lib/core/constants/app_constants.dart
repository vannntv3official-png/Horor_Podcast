class AppConstants {
  static const String appTitle = 'Khmer Horror Podcast';
  static const String appTagline = 'ស្តាប់រឿងខ្មោច និងរឿងព្រេងខ្មែរគ្រប់ពេលវេលា';

  // Storage Keys
  static const String keyGuestFavorites = 'khp_guest_favorites';
  static const String keyRecentSearches = 'khp_recent_searches';
  static const String keyLastPlayedEpisodeId = 'khp_last_episode_id';
  static const String keyPlaybackSpeed = 'khp_playback_speed';
  static const String keyHasSeenOnboarding = 'khp_has_seen_onboarding';
  static const String keyOfflineDownloads = 'khp_offline_downloads';

  // Audio Playback
  static const List<double> playbackSpeeds = [0.75, 1.0, 1.25, 1.5, 2.0];
  static const List<int> sleepTimerMinutes = [15, 30, 45, 60];

  // Default placeholder images
  static const String defaultCoverUrl =
      'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=800&q=80';
  static const String defaultHeroUrl =
      'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1200&q=80';
}
