import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_shimmer.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../shared/models/episode_model.dart';
import '../../../shared/models/listening_progress_model.dart';
import '../../../shared/models/story_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../audio_player/presentation/player_controller.dart';
import '../data/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return HistoryRepository(supabase);
});

final listeningHistoryProvider = FutureProvider.autoDispose<List<ListeningProgressModel>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  final repo = ref.watch(historyRepositoryProvider);
  return await repo.getListeningHistory(user.id);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(listeningHistoryProvider);
    final isGuest = ref.watch(authProvider).isGuest;

    if (isGuest) {
      return const Scaffold(
        appBar: GlassAppBar(title: 'ប្រវត្តិនៃការស្តាប់', showBack: true),
        body: AppEmptyState(
          icon: Icons.history_rounded,
          title: 'សូមចូលគណនី',
          message: 'ចូលគណនីដើម្បីកត់ត្រា និងបន្តស្តាប់រឿងដែលអ្នកបានស្តាប់កន្លងមក។',
        ),
      );
    }

    return Scaffold(
      appBar: const GlassAppBar(
        title: 'ប្រវត្តិនៃការស្តាប់ (History)',
        showBack: true,
      ),
      body: historyAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, __) => AppLoadingShimmer.episodeTilePlaceholder(),
        ),
        error: (err, _) => AppErrorState(
          message: 'មិនអាចទាញយកប្រវត្តិស្តាប់បានទេ។',
          onRetry: () => ref.refresh(listeningHistoryProvider),
        ),
        data: (historyList) {
          if (historyList.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'មិនទាន់មានប្រវត្តិស្តាប់ទេ',
              message: 'រាល់រឿង និងភាគដែលអ្នកបានស្តាប់ នឹងបង្ហាញនៅទីនេះ។',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(listeningHistoryProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: historyList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = historyList[index];
                final percent = (item.durationSeconds != null && item.durationSeconds! > 0)
                    ? (item.positionSeconds / item.durationSeconds!).clamp(0.0, 1.0)
                    : 0.0;

                return GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 18,
                  onTap: () {
                    if (item.episodeTitle != null) {
                      final ep = EpisodeModel(
                        id: item.episodeId,
                        storyId: item.storyId ?? '',
                        title: item.episodeTitle!,
                        episodeNumber: 1,
                        audioPath: 'podcast-audio/${item.episodeId}.mp3',
                        durationSeconds: item.durationSeconds ?? 0,
                      );
                      final st = StoryModel(
                        id: item.storyId ?? '',
                        title: item.storyTitle ?? '',
                        slug: 'story-${item.storyId}',
                        coverPath: item.coverPath,
                      );

                      ref.read(playerControllerProvider.notifier).playEpisode(
                            episode: ep,
                            story: st,
                            startPosition: Duration(seconds: item.positionSeconds),
                          );
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.episodeTitle ?? 'ភាគនិទាន',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.storyTitle ?? ""} • ${Formatters.formatDuration(item.positionSeconds)} / ${Formatters.formatDuration(item.durationSeconds ?? 0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: AppColors.outlineVariant,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                                minHeight: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
