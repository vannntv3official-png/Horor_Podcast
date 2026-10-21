import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/story_model.dart';

class FavoritesRepository {
  final SupabaseClient _supabase;
  final LocalStorage _localStorage;

  FavoritesRepository(this._supabase, this._localStorage);

  Future<List<String>> getFavoriteStoryIds({String? userId}) async {
    if (userId == null) {
      return _localStorage.getGuestFavorites();
    }
    try {
      final res = await _supabase
          .from('favorites')
          .select('story_id')
          .eq('user_id', userId);
      return (res as List).map((row) => row['story_id'] as String).toList();
    } catch (e) {
      AppLogger.warning('Failed to fetch remote favorites: $e');
      return _localStorage.getGuestFavorites();
    }
  }

  Future<List<StoryModel>> getFavoriteStories({String? userId}) async {
    final storyIds = await getFavoriteStoryIds(userId: userId);
    if (storyIds.isEmpty) return [];

    try {
      final res = await _supabase
          .from('stories')
          .select('*, categories(name)')
          .inFilter('id', storyIds)
          .eq('status', 'published');

      return (res as List).map((json) => StoryModel.fromJson(json)).toList();
    } catch (e) {
      AppLogger.warning('Failed to fetch favorite story models: $e');
      return [];
    }
  }

  Future<void> addFavorite(String storyId, {String? userId}) async {
    if (userId == null) {
      await _localStorage.addGuestFavorite(storyId);
    } else {
      try {
        await _supabase.from('favorites').upsert({
          'user_id': userId,
          'story_id': storyId,
        }, onConflict: 'user_id,story_id');
      } catch (e) {
        AppLogger.warning('Failed adding remote favorite: $e');
        await _localStorage.addGuestFavorite(storyId);
      }
    }
  }

  Future<void> removeFavorite(String storyId, {String? userId}) async {
    if (userId == null) {
      await _localStorage.removeGuestFavorite(storyId);
    } else {
      try {
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('story_id', storyId);
      } catch (e) {
        AppLogger.warning('Failed deleting remote favorite: $e');
      }
    }
  }
}
