import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../shared/models/episode_model.dart';
import '../../../../shared/models/story_model.dart';
import '../../../audio_player/presentation/player_controller.dart';
import '../../../downloads/presentation/download_controller.dart';

class EpisodeListTile extends ConsumerWidget {
  final EpisodeModel episode;
  final StoryModel story;
  final List<EpisodeModel> playlist;

  const EpisodeListTile({
    super.key,
    required this.episode,
    required this.story,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final isCurrent = playerState.currentEpisode?.id == episode.id;
    final isPlaying = isCurrent && playerState.isPlaying;

    final downloadsState = ref.watch(downloadsControllerProvider);
    final isDownloaded = downloadsState.isDownloaded(episode.id);
    final isDownloading = downloadsState.isDownloading(episode.id);
    final downloadProgress = downloadsState.getProgress(episode.id);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      color: isCurrent ? AppColors.primaryContainer.withOpacity(0.35) : null,
      onTap: () {
        ref.read(playerControllerProvider.notifier).playEpisode(
              episode: episode,
              story: story,
              playlist: playlist,
            );
      },
      child: Row(
        children: [
          // Play indicator or Episode Number
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.accent : AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPlaying
                  ? Icons.pause_rounded
                  : (isCurrent ? Icons.play_arrow_rounded : Icons.headphones_rounded),
              color: isCurrent ? Colors.white : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'វគ្គ ${episode.episodeNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentDark,
                          ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: AppColors.textTertiary)),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.formatDuration(episode.durationSeconds),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Download Action
          if (episode.allowDownload) ...[
            if (isDownloaded)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
              )
            else if (isDownloading)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    value: downloadProgress > 0 ? downloadProgress : null,
                    strokeWidth: 2.5,
                    color: AppColors.accent,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.download_rounded, color: AppColors.secondary),
                onPressed: () {
                  ref.read(downloadsControllerProvider.notifier).downloadEpisode(
                        episode: episode,
                        story: story,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('បានចាប់ផ្តើមទាញយក "${episode.title}"')),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
