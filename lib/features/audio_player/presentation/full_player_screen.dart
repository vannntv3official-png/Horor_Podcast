import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/env_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../favorites/presentation/favorites_controller.dart';
import 'playback_speed_dialog.dart';
import 'player_controller.dart';
import 'sleep_timer_dialog.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final episode = playerState.currentEpisode;

    if (episode == null) {
      return const SizedBox.shrink();
    }

    final controller = ref.read(playerControllerProvider.notifier);
    final story = playerState.currentStory;
    final coverUrl = story?.getCoverUrl(EnvConfig.supabaseUrl) ?? AppConstants.defaultCoverUrl;

    final isFav = story != null
        ? ref.watch(favoritesControllerProvider).contains(story.id)
        : false;

    final currentSeconds = playerState.position.inSeconds;
    final totalSeconds = playerState.duration.inSeconds > 0
        ? playerState.duration.inSeconds
        : episode.durationSeconds;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Color(0xF2FBF9F5), // 95% opacity Soft Ivory
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 1.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Pull down handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                      color: AppColors.primary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'កំពុងចាក់សំឡេង',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? Colors.redAccent : AppColors.primary,
                      ),
                      onPressed: () {
                        if (story != null) {
                          ref.read(favoritesControllerProvider.notifier).toggleFavorite(story.id);
                        }
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Atmospheric Cover Art with Glass Frame
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.72,
                          height: MediaQuery.of(context).size.width * 0.72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x221D102F),
                                blurRadius: 28,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: CachedNetworkImage(
                              imageUrl: coverUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.secondaryLight,
                                child: const Center(
                                  child: Icon(Icons.music_note_rounded, size: 64, color: AppColors.secondary),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.secondaryLight,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported_rounded, size: 64, color: AppColors.secondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Episode and Story Titles
                      Text(
                        episode.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story?.title ?? 'Khmer Horror Podcast',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.secondary,
                            ),
                      ),
                      if (story?.narratorName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mic_none_rounded, size: 14, color: AppColors.accentDark),
                            const SizedBox(width: 4),
                            Text(
                              'និទានដោយ: ${story!.narratorName}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.accentDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Scrubber / Seek Bar
                      Slider(
                        value: currentSeconds.toDouble().clamp(0.0, totalSeconds.toDouble()),
                        max: (totalSeconds > 0 ? totalSeconds : 1).toDouble(),
                        onChanged: (val) {
                          controller.seek(Duration(seconds: val.toInt()));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Formatters.formatDuration(currentSeconds),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              Formatters.formatDuration(totalSeconds),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Previous
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            color: AppColors.primary,
                            iconSize: 36,
                            onPressed: () => controller.playPrevious(),
                          ),
                          // Rewind 10s
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded),
                            color: AppColors.primary,
                            iconSize: 32,
                            onPressed: () => controller.seekBackward(seconds: 10),
                          ),
                          // Play / Pause Circle
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x331D102F),
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IconButton(
                              iconSize: 68,
                              padding: EdgeInsets.zero,
                              icon: playerState.isBuffering
                                  ? const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: AppColors.accent,
                                      ),
                                    )
                                  : Icon(
                                      playerState.isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: AppColors.primary,
                                    ),
                              onPressed: () => controller.togglePlayPause(),
                            ),
                          ),
                          // Forward 10s
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded),
                            color: AppColors.primary,
                            iconSize: 32,
                            onPressed: () => controller.seekForward(seconds: 10),
                          ),
                          // Next
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            color: AppColors.primary,
                            iconSize: 36,
                            onPressed: () => controller.playNext(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bottom Utilities: Speed, Sleep Timer, Playlist
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Speed Pill
                          ActionChip(
                            avatar: const Icon(Icons.speed_rounded, size: 16, color: AppColors.primary),
                            label: Text('${playerState.speed}x'),
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(color: AppColors.glassBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const PlaybackSpeedDialog(),
                              );
                            },
                          ),
                          const SizedBox(width: 14),

                          // Sleep Timer Pill
                          ActionChip(
                            avatar: Icon(
                              Icons.bedtime_outlined,
                              size: 16,
                              color: playerState.sleepTimerMinutesRemaining != null
                                  ? AppColors.accentDark
                                  : AppColors.primary,
                            ),
                            label: Text(
                              playerState.sleepTimerMinutesRemaining != null
                                  ? '${playerState.sleepTimerMinutesRemaining} នាទី'
                                  : playerState.sleepTimerAtEndOfEpisode
                                      ? 'ចប់ភាគ'
                                      : 'ម៉ោងគេង',
                              style: TextStyle(
                                color: playerState.sleepTimerMinutesRemaining != null
                                    ? AppColors.accentDark
                                    : AppColors.primary,
                                fontWeight: playerState.sleepTimerMinutesRemaining != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            backgroundColor: playerState.sleepTimerMinutesRemaining != null
                                ? AppColors.accentLight.withOpacity(0.5)
                                : AppColors.surface,
                            side: const BorderSide(color: AppColors.glassBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const SleepTimerDialog(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
