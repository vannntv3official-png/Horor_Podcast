import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  static Future<LocalStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }

  // Guest Favorites
  List<String> getGuestFavorites() {
    return _prefs.getStringList(AppConstants.keyGuestFavorites) ?? [];
  }

  Future<void> saveGuestFavorites(List<String> storyIds) async {
    await _prefs.setStringList(AppConstants.keyGuestFavorites, storyIds);
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
    await _prefs.remove(AppConstants.keyGuestFavorites);
  }

  // Recent Searches
  List<String> getRecentSearches() {
    return _prefs.getStringList(AppConstants.keyRecentSearches) ?? [];
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
    await _prefs.setStringList(AppConstants.keyRecentSearches, list);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(AppConstants.keyRecentSearches);
  }

  // Playback Speed
  double getPlaybackSpeed() {
    return _prefs.getDouble(AppConstants.keyPlaybackSpeed) ?? 1.0;
  }

  Future<void> savePlaybackSpeed(double speed) async {
    await _prefs.setDouble(AppConstants.keyPlaybackSpeed, speed);
  }

  // Onboarding
  bool hasSeenOnboarding() {
    return _prefs.getBool(AppConstants.keyHasSeenOnboarding) ?? false;
  }

  Future<void> setHasSeenOnboarding(bool seen) async {
    await _prefs.setBool(AppConstants.keyHasSeenOnboarding, seen);
  }

  // Offline Downloads Registry (JSON Map)
  Map<String, dynamic> getDownloadsRegistry() {
    final str = _prefs.getString(AppConstants.keyOfflineDownloads);
    if (str == null || str.isEmpty) return {};
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDownloadsRegistry(Map<String, dynamic> data) async {
    await _prefs.setString(AppConstants.keyOfflineDownloads, jsonEncode(data));
  }
}
