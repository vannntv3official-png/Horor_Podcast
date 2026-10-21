import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_shimmer.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/story_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../audio_player/presentation/mini_player.dart';
import '../../audio_player/presentation/player_controller.dart';
import '../../history/presentation/history_screen.dart';
import '../../stories/data/stories_repository.dart';
import 'widgets/category_pills.dart';
import 'widgets/continue_listening_section.dart';
import 'widgets/featured_story_card.dart';
import 'widgets/story_card_horizontal.dart';

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return StoriesRepository(supabase);
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(storiesRepositoryProvider);
  return await repo.getCategories();
});

final featuredStoryProvider = FutureProvider<StoryModel?>((ref) async {
  final repo = ref.watch(storiesRepositoryProvider);
  return await repo.getFeaturedStory();
});

final trendingStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  final repo = ref.watch(storiesRepositoryProvider);
  return await repo.getStories(sortBy: 'popular', limit: 8);
});

final recentStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  final repo = ref.watch(storiesRepositoryProvider);
  return await repo.getStories(sortBy: 'newest', limit: 8);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategorySlug;

  Future<void> _refresh() async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(featuredStoryProvider);
    ref.invalidate(trendingStoriesProvider);
    ref.invalidate(recentStoriesProvider);
    ref.invalidate(listeningHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final featuredAsync = ref.watch(featuredStoryProvider);
    final trendingAsync = ref.watch(trendingStoriesProvider);
    final recentAsync = ref.watch(recentStoriesProvider);
    final historyAsync = ref.watch(listeningHistoryProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.accent,
            child: CustomScrollView(
              slivers: [
                // Top App Bar with Greeting & Search Icon
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  backgroundColor: AppColors.background.withOpacity(0.85),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  title: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.headphones_rounded, color: AppColors.primary, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                          Text(
                            authState.isAuthenticated
                                ? 'សួស្តី, ${authState.profile?.displayName ?? "អ្នកស្តាប់"}'
                                : 'សូមស្វាគមន៍មកកាន់ពិភពរឿងខ្មោច',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 26),
                      onPressed: () => context.push('/explore'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border_rounded, color: AppColors.primary, size: 24),
                      onPressed: () => context.push('/favorites'),
                    ),
                  ],
                ),

                // Featured Story Banner
                SliverToBoxAdapter(
                  child: featuredAsync.when(
                    data: (featured) {
                      if (featured == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        child: FeaturedStoryCard(
                          story: featured,
                          onTap: () => context.push('/story/${featured.id}'),
                          onPlay: () async {
                            final episodes = await ref
                                .read(storiesRepositoryProvider)
                                .getEpisodes(featured.id);
                            if (episodes.isNotEmpty) {
                              ref.read(playerControllerProvider.notifier).playEpisode(
                                    episode: episodes.first,
                                    story: featured,
                                    playlist: episodes,
                                  );
                            } else if (context.mounted) {
                              context.push('/story/${featured.id}');
                            }
                          },
                        ),
                      );
                    },
                    loading: () => Container(
                      height: 240,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const AppLoadingShimmer(width: double.infinity, height: 240, borderRadius: 28),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // Continue Listening Section
                SliverToBoxAdapter(
                  child: historyAsync.when(
                    data: (history) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ContinueListeningSection(items: history),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // Category Pills
                SliverToBoxAdapter(
                  child: categoriesAsync.when(
                    data: (categories) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: CategoryPills(
                        categories: categories,
                        selectedSlug: _selectedCategorySlug,
                        onSelect: (slug) {
                          setState(() => _selectedCategorySlug = slug);
                          if (slug != null) {
                            context.push('/explore?category=$slug');
                          }
                        },
                      ),
                    ),
                    loading: () => const SizedBox(height: 42),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // Trending Stories Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'រឿងពេញនិយម (Trending)',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/explore?sort=popular'),
                          child: const Text('មើលទាំងអស់'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Trending Stories Horizontal List
                SliverToBoxAdapter(
                  child: trendingAsync.when(
                    data: (stories) {
                      if (stories.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('មិនទាន់មានរឿងពេញនិយមទេ')),
                        );
                      }
                      return SizedBox(
                        height: 270,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: stories.length,
                          itemBuilder: (context, index) {
                            final story = stories[index];
                            return StoryCardHorizontal(
                              story: story,
                              onTap: () => context.push('/story/${story.id}'),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => SizedBox(
                      height: 270,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 4,
                        itemBuilder: (_, __) => AppLoadingShimmer.storyCardPlaceholder(),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: AppErrorState(
                        message: 'មិនអាចទាញយករឿងពេញនិយមបានទេ។',
                        onRetry: () => ref.refresh(trendingStoriesProvider),
                      ),
                    ),
                  ),
                ),

                // New Episodes Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'រឿងទើបចេញថ្មី (Recently Added)',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/explore?sort=newest'),
                          child: const Text('មើលទាំងអស់'),
                        ),
                      ],
                    ),
                  ),
                ),

                // New Episodes Horizontal List
                SliverToBoxAdapter(
                  child: recentAsync.when(
                    data: (stories) {
                      if (stories.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        height: 270,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: stories.length,
                          itemBuilder: (context, index) {
                            final story = stories[index];
                            return StoryCardHorizontal(
                              story: story,
                              onTap: () => context.push('/story/${story.id}'),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => SizedBox(
                      height: 270,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 4,
                        itemBuilder: (_, __) => AppLoadingShimmer.storyCardPlaceholder(),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // Extra padding for mini-player
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),

          // Docked MiniPlayer
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}
