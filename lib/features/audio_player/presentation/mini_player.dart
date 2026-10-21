import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/env_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_container.dart';
import 'full_player_screen.dart';
import 'player_controller.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final episode = playerState.currentEpisode;

    if (episode == null) {
      return const SizedBox.shrink();
    }

    final controller = ref.read(playerControllerProvider.notifier);
    final coverUrl = playerState.currentStory?.getCoverUrl(EnvConfig.supabaseUrl) ??
        episode.storyCoverPath ??
        AppConstants.defaultCoverUrl;

    final progressRatio = playerState.duration.inMilliseconds > 0
        ? (playerState.position.inMilliseconds / playerState.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 22,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const FullPlayerScreen(),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear progress indicator at the very top of mini-player
            LinearProgressIndicator(
              value: progressRatio,
              backgroundColor: AppColors.accentLight.withOpacity(0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 2.5,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Cover Image Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: coverUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.secondaryLight,
                        child: const Icon(Icons.music_note, color: AppColors.secondary),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.secondaryLight,
                        child: const Icon(Icons.music_note, color: AppColors.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Episode Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          episode.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          playerState.currentStory?.title ?? 'Khmer Horror Podcast',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Controls
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded),
                    color: AppColors.primary,
                    iconSize: 26,
                    onPressed: () => controller.seekForward(seconds: 10),
                  ),
                  IconButton(
                    icon: playerState.isBuffering
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          )
                        : Icon(
                            playerState.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: AppColors.primary,
                            size: 38,
                          ),
                    onPressed: () => controller.togglePlayPause(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
