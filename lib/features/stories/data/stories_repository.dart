import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/logging/app_logger.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/episode_model.dart';
import '../../../shared/models/story_model.dart';

class StoriesRepository {
  final SupabaseClient _supabase;

  StoriesRepository(this._supabase);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await _supabase
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (res as List).map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e, st) {
      throw ErrorHandler.handle(e, st);
    }
  }

  Future<StoryModel?> getFeaturedStory() async {
    try {
      final res = await _supabase
          .from('stories')
          .select('*, categories(name)')
          .eq('status', 'published')
          .eq('is_featured', true)
          .order('published_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        return StoryModel.fromJson(res);
      }
      return null;
    } catch (e) {
      AppLogger.warning('Failed loading featured story: $e');
      return null;
    }
  }

  Future<List<StoryModel>> getStories({
    String? categorySlug,
    String? searchQuery,
    String sortBy = 'newest', // 'newest', 'popular', 'title'
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      dynamic query = _supabase
          .from('stories')
          .select('*, categories(name, slug)')
          .eq('status', 'published');

      if (categorySlug != null && categorySlug.isNotEmpty) {
        // filter by category slug
        query = query.eq('categories.slug', categorySlug);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('title.ilike.%$q%,description.ilike.%$q%,narrator_name.ilike.%$q%');
      }

      if (sortBy == 'popular') {
        query = query.order('is_featured', ascending: false).order('created_at', ascending: false);
      } else if (sortBy == 'title') {
        query = query.order('title', ascending: true);
      } else {
        query = query.order('published_at', ascending: false);
      }

      final res = await query.range(offset, offset + limit - 1);
      return (res as List).map((json) => StoryModel.fromJson(json)).toList();
    } catch (e, st) {
      throw ErrorHandler.handle(e, st);
    }
  }

  Future<StoryModel?> getStoryById(String id) async {
    try {
      final res = await _supabase
          .from('stories')
          .select('*, categories(name)')
          .eq('id', id)
          .eq('status', 'published')
          .maybeSingle();

      if (res != null) {
        return StoryModel.fromJson(res);
      }
      return null;
    } catch (e, st) {
      throw ErrorHandler.handle(e, st);
    }
  }

  Future<List<EpisodeModel>> getEpisodes(String storyId) async {
    try {
      final res = await _supabase
          .from('episodes')
          .select('*, stories(title, cover_path)')
          .eq('story_id', storyId)
          .eq('status', 'published')
          .order('episode_number', ascending: true);

      return (res as List).map((json) => EpisodeModel.fromJson(json)).toList();
    } catch (e, st) {
      throw ErrorHandler.handle(e, st);
    }
  }
}
