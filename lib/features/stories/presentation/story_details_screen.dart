import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/env_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_shimmer.dart';
import '../../../shared/models/episode_model.dart';
import '../../../shared/models/story_model.dart';
import '../../audio_player/presentation/mini_player.dart';
import '../../audio_player/presentation/player_controller.dart';
import '../../episodes/presentation/widgets/episode_list_tile.dart';
import '../../favorites/presentation/favorites_controller.dart';
import '../../home/presentation/home_screen.dart';

final storyDetailsProvider = FutureProvider.family<StoryModel?, String>((ref, id) async {
  final repo = ref.watch(storiesRepositoryProvider);
  return await repo.getStoryById(id);
});

final storyEpisodesProvider = FutureProvider.family<List<EpisodeModel>, String>((ref, storyId) async {
  final repo = ref.watch(storiesRepositoryProvider);
  return await repo.getEpisodes(storyId);
});

class StoryDetailsScreen extends ConsumerWidget {
  final String storyId;

  const StoryDetailsScreen({super.key, required this.storyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyDetailsProvider(storyId));
    final episodesAsync = ref.watch(storyEpisodesProvider(storyId));

    final isFav = ref.watch(favoritesControllerProvider).contains(storyId);

    return Scaffold(
      body: Stack(
        children: [
          storyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
            error: (err, _) => Center(
              child: AppErrorState(
                message: 'មិនអាចទាញយកព័ត៌មានរឿងនេះបានទេ។',
                onRetry: () {
                  ref.invalidate(storyDetailsProvider(storyId));
                  ref.invalidate(storyEpisodesProvider(storyId));
                },
              ),
            ),
            data: (story) {
              if (story == null) {
                return const AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'រកមិនឃើញរឿងនេះទេ',
                  message: 'រឿងនេះអាចត្រូវបានលុប ឬផ្លាស់ប្តូរទីតាំង។',
                );
              }

              final coverUrl = story.getCoverUrl(EnvConfig.supabaseUrl);
              final displayUrl = coverUrl.isNotEmpty ? coverUrl : AppConstants.defaultCoverUrl;

              return CustomScrollView(
                slivers: [
                  // Sliver App Bar with dynamic atmospheric cover
                  SliverAppBar(
                    expandedHeight: 330,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: 'ស្តាប់រឿង "${story.title}" លើកម្មវិធី Khmer Horror Podcast: https://khmerhorrorpodcast.com/story/${story.id}',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('បានចម្លងតំណភ្ជាប់រឿងទៅកាន់ Clipboard រួចរាល់!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? Colors.redAccent : Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: () {
                          ref.read(favoritesControllerProvider.notifier).toggleFavorite(story.id);
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: displayUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.primaryLight),
                            errorWidget: (_, __, ___) => Container(color: AppColors.primaryLight),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                  Theme.of(context).scaffoldBackgroundColor,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Story Metadata & Description
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (story.categoryName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                story.categoryName!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            story.title,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (story.narratorName != null) ...[
                                const Icon(Icons.mic_none_rounded, size: 16, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  'និទាន: ${story.narratorName}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (story.publishedAt != null) ...[
                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  Formatters.formatDate(story.publishedAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (story.description != null && story.description!.isNotEmpty) ...[
                            Text(
                              story.description!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.6,
                                  ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Action Buttons
                          episodesAsync.when(
                            data: (episodes) {
                              if (episodes.isEmpty) return const SizedBox.shrink();
                              return Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        ref.read(playerControllerProvider.notifier).playEpisode(
                                              episode: episodes.first,
                                              story: story,
                                              playlist: episodes,
                                            );
                                      },
                                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                                      label: const Text('ស្តាប់ពីភាគ ១ (Play All)'),
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'បញ្ជីវគ្គទាំងអស់ (Episodes)',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Episodes List
                  episodesAsync.when(
                    data: (episodes) {
                      if (episodes.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('មិនទាន់មានវគ្គសម្រាប់រឿងនេះទេ')),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final ep = episodes[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: EpisodeListTile(
                                  episode: ep,
                                  story: story,
                                  playlist: episodes,
                                ),
                              );
                            },
                            childCount: episodes.length,
                          ),
                        ),
                      );
                    },
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => AppLoadingShimmer.episodeTilePlaceholder(),
                          childCount: 3,
                        ),
                      ),
                    ),
                    error: (err, _) => SliverToBoxAdapter(
                      child: AppErrorState(
                        message: 'មិនអាចទាញយកបញ្ជីវគ្គបានទេ។',
                        onRetry: () => ref.refresh(storyEpisodesProvider(storyId)),
                      ),
                    ),
                  ),
                ],
              );
            },
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
