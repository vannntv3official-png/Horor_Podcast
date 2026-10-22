import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../shared/models/episode_model.dart';
import '../../../../shared/models/listening_progress_model.dart';
import '../../../../shared/models/story_model.dart';
import '../../../audio_player/presentation/player_controller.dart';

class ContinueListeningSection extends ConsumerWidget {
  final List<ListeningProgressModel> items;

  const ContinueListeningSection({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'បន្តស្តាប់ (Continue Listening)',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final percent = (item.durationSeconds != null && item.durationSeconds! > 0)
                  ? (item.positionSeconds / item.durationSeconds!).clamp(0.0, 1.0)
                  : 0.0;

              return SizedBox(
                width: 250,
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 18,
                  onTap: () {
                    final ep = EpisodeModel(
                      id: item.episodeId,
                      storyId: item.storyId ?? '',
                      title: item.episodeTitle ?? 'ភាគនិទាន',
                      episodeNumber: 1,
                      audioPath: item.audioPath ?? 'podcast-audio/${item.episodeId}.mp3',
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
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: AppColors.accentDark, size: 20),
                          ),
                          const SizedBox(width: 10),
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
                                Text(
                                  item.storyTitle ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Formatters.formatDuration(item.positionSeconds),
                                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                              ),
                              Text(
                                Formatters.formatDuration(item.durationSeconds ?? 0),
                                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: AppColors.outlineVariant,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                              minHeight: 3.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
