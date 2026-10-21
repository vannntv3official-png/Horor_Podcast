import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/story_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final storage = ref.watch(localStorageProvider);
  return FavoritesRepository(supabase, storage);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final FavoritesRepository _repo;
  final Ref _ref;

  FavoritesNotifier(this._repo, this._ref) : super({}) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final user = _ref.read(authProvider).user;
    final ids = await _repo.getFavoriteStoryIds(userId: user?.id);
    state = ids.toSet();
  }

  Future<void> toggleFavorite(String storyId) async {
    final user = _ref.read(authProvider).user;
    final isFav = state.contains(storyId);

    final updated = Set<String>.from(state);
    if (isFav) {
      updated.remove(storyId);
      state = updated;
      await _repo.removeFavorite(storyId, userId: user?.id);
    } else {
      updated.add(storyId);
      state = updated;
      await _repo.addFavorite(storyId, userId: user?.id);
    }
  }
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final repo = ref.watch(favoritesRepositoryProvider);
  return FavoritesNotifier(repo, ref);
});

final favoriteStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  // Watch IDs to trigger rebuild when toggled
  ref.watch(favoritesControllerProvider);
  final repo = ref.watch(favoritesRepositoryProvider);
  final user = ref.watch(authProvider).user;
  return await repo.getFavoriteStories(userId: user?.id);
});
