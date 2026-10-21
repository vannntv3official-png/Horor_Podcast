import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../shared/models/episode_model.dart';
import '../../../shared/models/story_model.dart';
import '../../audio_player/presentation/player_controller.dart';
import 'download_controller.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsState = ref.watch(downloadsControllerProvider);
    final notifier = ref.read(downloadsControllerProvider.notifier);
    final items = downloadsState.downloadedItems.values.toList();

    return Scaffold(
      appBar: const GlassAppBar(
        title: 'ឯកសារទាញយក (Offline)',
        showBack: true,
      ),
      body: items.isEmpty
          ? const AppEmptyState(
              icon: Icons.cloud_download_outlined,
              title: 'មិនទាន់មានឯកសារទាញយកទេ',
              message: 'អ្នកអាចទាញយករឿងដែលអ្នកចូលចិត្ត ដើម្បីស្តាប់នៅពេលគ្មានអ៊ីនធឺណិត។',
            )
          : Column(
              children: [
                // Storage Usage Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.storage_rounded, color: AppColors.accentDark),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ទំហំផ្ទុកសរុប',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${Formatters.formatFileSize(downloadsState.totalStorageBytes)} (${items.length} ភាគ)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Episode List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 18,
                        onTap: () {
                          // Play offline
                          final dummyEpisode = EpisodeModel(
                            id: item.episodeId,
                            storyId: item.storyId,
                            title: item.episodeTitle,
                            episodeNumber: item.episodeNumber,
                            audioPath: item.localFilePath,
                            durationSeconds: item.durationSeconds,
                            storyTitle: item.storyTitle,
                          );
                          final dummyStory = StoryModel(
                            id: item.storyId,
                            title: item.storyTitle,
                            slug: 'offline-${item.storyId}',
                            coverPath: item.coverPath,
                          );

                          ref.read(playerControllerProvider.notifier).playEpisode(
                                episode: dummyEpisode,
                                story: dummyStory,
                                localAudioPath: item.localFilePath,
                              );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.offline_pin_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.episodeTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.storyTitle} • ${Formatters.formatFileSize(item.fileSizeBytes)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text('លុបឯកសារទាញយក?'),
                                    content: Text('តើអ្នកពិតជាចង់លុប "${item.episodeTitle}" មែនទេ?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('បោះបង់'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                        ),
                                        onPressed: () {
                                          notifier.deleteDownload(item.episodeId);
                                          Navigator.of(ctx).pop();
                                        },
                                        child: const Text('លុប'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
