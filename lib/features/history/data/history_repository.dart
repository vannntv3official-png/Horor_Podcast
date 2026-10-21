import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/logging/app_logger.dart';
import '../../../shared/models/listening_progress_model.dart';

class HistoryRepository {
  final SupabaseClient _supabase;

  HistoryRepository(this._supabase);

  Future<List<ListeningProgressModel>> getListeningHistory(String userId) async {
    try {
      final res = await _supabase
          .from('listening_progress')
          .select('''
            *,
            episodes(
              id, title, duration_seconds, audio_path, story_id,
              stories(id, title, cover_path)
            )
          ''')
          .eq('user_id', userId)
          .order('last_played_at', ascending: false)
          .limit(30);

      return (res as List).map((row) => ListeningProgressModel.fromJson(row)).toList();
    } catch (e, st) {
      AppLogger.error('Failed to load listening history', e, st);
      return [];
    }
  }

  Future<void> clearHistory(String userId) async {
    try {
      await _supabase.from('listening_progress').delete().eq('user_id', userId);
    } catch (e) {
      AppLogger.warning('Failed to clear listening history: $e');
    }
  }
}
