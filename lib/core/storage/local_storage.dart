import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../logging/app_logger.dart';

class LocalStorage {
  final SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryFallback = {};

  LocalStorage([this._prefs]);

  static Future<LocalStorage> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return LocalStorage(prefs);
    } catch (e, st) {
      AppLogger.error('Failed to initialize SharedPreferences, retrying...', e, st);
      try {
        final prefs = await SharedPreferences.getInstance();
        return LocalStorage(prefs);
      } catch (_) {
        return LocalStorage(null);
      }
    }
  }

  // Guest Favorites
  List<String> getGuestFavorites() {
    if (_prefs != null) {
      return _prefs.getStringList(AppConstants.keyGuestFavorites) ?? [];
    }
    return (_memoryFallback[AppConstants.keyGuestFavorites] as List<dynamic>?)
            ?.cast<String>() ??
        [];
  }

  Future<void> saveGuestFavorites(List<String> storyIds) async {
    if (_prefs != null) {
      await _prefs.setStringList(AppConstants.keyGuestFavorites, storyIds);
    } else {
      _memoryFallback[AppConstants.keyGuestFavorites] = storyIds;
    }
  }

  Future<void> addGuestFavorite(String storyId) async {
    final list = getGuestFavorites();
    if (!list.contains(storyId)) {
      list.add(storyId);
      await saveGuestFavorites(list);
    }
  }

  Future<void> removeGuestFavorite(String storyId) async {
    final list = getGuestFavorites();
    list.remove(storyId);
    await saveGuestFavorites(list);
  }

  Future<void> clearGuestFavorites() async {
    if (_prefs != null) {
      await _prefs.remove(AppConstants.keyGuestFavorites);
    } else {
      _memoryFallback.remove(AppConstants.keyGuestFavorites);
    }
  }

  // Recent Searches
  List<String> getRecentSearches() {
    if (_prefs != null) {
      return _prefs.getStringList(AppConstants.keyRecentSearches) ?? [];
    }
    return (_memoryFallback[AppConstants.keyRecentSearches] as List<dynamic>?)
            ?.cast<String>() ??
        [];
  }

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final list = getRecentSearches();
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }
    if (_prefs != null) {
      await _prefs.setStringList(AppConstants.keyRecentSearches, list);
    } else {
      _memoryFallback[AppConstants.keyRecentSearches] = list;
    }
  }

  Future<void> clearRecentSearches() async {
    if (_prefs != null) {
      await _prefs.remove(AppConstants.keyRecentSearches);
    } else {
      _memoryFallback.remove(AppConstants.keyRecentSearches);
    }
  }

  // Playback Speed
  double getPlaybackSpeed() {
    if (_prefs != null) {
      return _prefs.getDouble(AppConstants.keyPlaybackSpeed) ?? 1.0;
    }
    return (_memoryFallback[AppConstants.keyPlaybackSpeed] as double?) ?? 1.0;
  }

  Future<void> savePlaybackSpeed(double speed) async {
    if (_prefs != null) {
      await _prefs.setDouble(AppConstants.keyPlaybackSpeed, speed);
    } else {
      _memoryFallback[AppConstants.keyPlaybackSpeed] = speed;
    }
  }

  // Onboarding
  bool hasSeenOnboarding() {
    if (_prefs != null) {
      final val = _prefs.getBool(AppConstants.keyHasSeenOnboarding);
      if (val != null) return val;
    }
    return (_memoryFallback[AppConstants.keyHasSeenOnboarding] as bool?) ?? false;
  }

  Future<void> setHasSeenOnboarding(bool seen) async {
    _memoryFallback[AppConstants.keyHasSeenOnboarding] = seen;
    if (_prefs != null) {
      await _prefs.setBool(AppConstants.keyHasSeenOnboarding, seen);
    }
  }

  // Offline Downloads Registry (JSON Map)
  Map<String, dynamic> getDownloadsRegistry() {
    final str = _prefs != null
        ? _prefs.getString(AppConstants.keyOfflineDownloads)
        : (_memoryFallback[AppConstants.keyOfflineDownloads] as String?);
    if (str == null || str.isEmpty) return {};
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDownloadsRegistry(Map<String, dynamic> data) async {
    final str = jsonEncode(data);
    if (_prefs != null) {
      await _prefs.setString(AppConstants.keyOfflineDownloads, str);
    } else {
      _memoryFallback[AppConstants.keyOfflineDownloads] = str;
    }
  }
}
