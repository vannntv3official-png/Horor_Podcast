import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../app/config/env_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../downloads/presentation/download_controller.dart';
import '../../favorites/presentation/favorites_controller.dart';
import 'playback_speed_dialog.dart';
import 'player_controller.dart';
import 'sleep_timer_dialog.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  bool _showRemainingTime = false;

  void _shareEpisode(BuildContext context, String storyTitle, String episodeTitle) {
    Clipboard.setData(
      ClipboardData(
        text: 'ស្តាប់ "$episodeTitle" នៃរឿង "$storyTitle" លើកម្មវិធី Khmer Horror Podcast: https://khmerhorrorpodcast.com',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('បានចម្លងតំណភ្ជាប់រឿងទៅកាន់ Clipboard រួចរាល់!'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _showQueueBottomSheet(BuildContext context, PlayerStateModel playerState, PlayerController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xF2140B22) : const Color(0xF5FBF9F5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.queue_music_rounded, color: isDark ? AppColors.accent : AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'បញ្ជីវគ្គបន្ទាប់ (Playing Queue)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        '${playerState.queue.length} ភាគ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: playerState.queue.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = playerState.queue[index];
                      final isCurrent = index == playerState.queueIndex;

                      return Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? (isDark ? const Color(0x33C89B3C) : AppColors.primaryContainer.withOpacity(0.35))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.accent : (isDark ? const Color(0xFF281C38) : AppColors.secondaryLight),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isCurrent ? Icons.volume_up_rounded : Icons.music_note_rounded,
                              size: 18,
                              color: isCurrent ? Colors.white : (isDark ? AppColors.accent : AppColors.primary),
                            ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent
                                  ? (isDark ? AppColors.accent : AppColors.primary)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            ),
                          ),
                          subtitle: Text(
                            'វគ្គ ${item.episodeNumber} • ${Formatters.formatDuration(item.durationSeconds)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          trailing: isCurrent
                              ? const Text(
                                  'កំពុងចាក់',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            controller.playEpisode(
                              episode: item,
                              story: playerState.currentStory,
                              playlist: playerState.queue,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final episode = playerState.currentEpisode;

    if (episode == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = ref.read(playerControllerProvider.notifier);
    final story = playerState.currentStory;
    final coverUrl = story?.getCoverUrl(EnvConfig.supabaseUrl) ?? AppConstants.defaultCoverUrl;

    final isFav = story != null
        ? ref.watch(favoritesControllerProvider).contains(story.id)
        : false;

    final downloadsState = ref.watch(downloadsControllerProvider);
    final isDownloaded = downloadsState.isDownloaded(episode.id);

    final currentSeconds = playerState.position.inSeconds;
    final totalSeconds = playerState.duration.inSeconds > 0
        ? playerState.duration.inSeconds
        : episode.durationSeconds;
    final remainingSeconds = (totalSeconds - currentSeconds).clamp(0, totalSeconds);

    final primaryColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.secondary;
    final bgColor = isDark ? const Color(0xF50C0714) : const Color(0xF2FBF9F5);
    final borderColor = isDark ? AppColors.darkGlassBorder : AppColors.glassBorder;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.94,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: borderColor, width: 1.5),
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
                  color: isDark ? AppColors.darkTextTertiary.withOpacity(0.5) : AppColors.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                      color: primaryColor,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Column(
                      children: [
                        Text(
                          'កំពុងចាក់សំឡេង',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                        ),
                        if (story != null)
                          Text(
                            story.title,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: secondaryColor,
                                  fontSize: 11,
                                ),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 22),
                          color: primaryColor,
                          tooltip: 'ចែករំលែក',
                          onPressed: () => _shareEpisode(context, story?.title ?? '', episode.title),
                        ),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? Colors.redAccent : primaryColor,
                          ),
                          tooltip: 'ពេញចិត្ត',
                          onPressed: () {
                            if (story != null) {
                              ref.read(favoritesControllerProvider.notifier).toggleFavorite(story.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Atmospheric Cover Art with Glowing Frame
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: MediaQuery.of(context).size.width * 0.72,
                          height: MediaQuery.of(context).size.width * 0.72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: playerState.isPlaying ? AppColors.accent.withOpacity(0.6) : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: playerState.isPlaying
                                    ? (isDark ? const Color(0x40C89B3C) : const Color(0x331D102F))
                                    : (isDark ? const Color(0x33000000) : const Color(0x141D102F)),
                                blurRadius: playerState.isPlaying ? 32 : 18,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: CachedNetworkImage(
                              imageUrl: coverUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: isDark ? const Color(0xFF281C38) : AppColors.secondaryLight,
                                child: const Center(
                                  child: Icon(Icons.music_note_rounded, size: 64, color: AppColors.accent),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: isDark ? const Color(0xFF281C38) : AppColors.secondaryLight,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported_rounded, size: 64, color: AppColors.secondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Episode and Story Titles
                      Text(
                        episode.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story?.title ?? 'Khmer Horror Podcast',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: secondaryColor,
                            ),
                      ),
                      if (story?.narratorName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mic_none_rounded, size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              'និទានដោយ: ${story!.narratorName}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Scrubber / Seek Bar
                      Slider(
                        value: currentSeconds.toDouble().clamp(0.0, totalSeconds.toDouble()),
                        max: (totalSeconds > 0 ? totalSeconds : 1).toDouble(),
                        onChanged: (val) {
                          controller.seek(Duration(seconds: val.toInt()));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Formatters.formatDuration(currentSeconds),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _showRemainingTime = !_showRemainingTime),
                              child: Text(
                                _showRemainingTime
                                    ? '-${Formatters.formatDuration(remainingSeconds)}'
                                    : Formatters.formatDuration(totalSeconds),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Playback Controls + Shuffle + Repeat
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Shuffle button
                          IconButton(
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: playerState.isShuffle ? AppColors.accent : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                              size: 24,
                            ),
                            tooltip: 'សាប់ចម្រៀង',
                            onPressed: () => controller.toggleShuffle(),
                          ),
                          // Previous
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            color: primaryColor,
                            iconSize: 36,
                            tooltip: 'ភាគមុន',
                            onPressed: () => controller.playPrevious(),
                          ),
                          // Rewind 10s
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded),
                            color: primaryColor,
                            iconSize: 30,
                            tooltip: 'ថយ ១០ វិនាទី',
                            onPressed: () => controller.seekBackward(seconds: 10),
                          ),
                          // Play / Pause Circle
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? const Color(0x66C89B3C) : const Color(0x331D102F),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
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
                                      color: isDark ? AppColors.accent : AppColors.primary,
                                    ),
                              onPressed: () => controller.togglePlayPause(),
                            ),
                          ),
                          // Forward 10s
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded),
                            color: primaryColor,
                            iconSize: 30,
                            tooltip: 'ទៅមុខ ១០ វិនាទី',
                            onPressed: () => controller.seekForward(seconds: 10),
                          ),
                          // Next
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            color: primaryColor,
                            iconSize: 36,
                            tooltip: 'ភាគបន្ទាប់',
                            onPressed: () => controller.playNext(),
                          ),
                          // Repeat button
                          IconButton(
                            icon: Icon(
                              playerState.loopMode == LoopMode.one
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              color: playerState.loopMode != LoopMode.off
                                  ? AppColors.accent
                                  : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                              size: 24,
                            ),
                            tooltip: 'ចាក់ឡើងវិញ',
                            onPressed: () => controller.toggleRepeatMode(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bottom Utilities: Speed, Sleep Timer, Queue, Offline Status
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          // Speed Pill
                          ActionChip(
                            avatar: Icon(Icons.speed_rounded, size: 16, color: primaryColor),
                            label: Text('${playerState.speed}x'),
                            backgroundColor: isDark ? const Color(0xFF1B1229) : AppColors.surface,
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const PlaybackSpeedDialog(),
                              );
                            },
                          ),

                          // Sleep Timer Pill
                          ActionChip(
                            avatar: Icon(
                              Icons.bedtime_outlined,
                              size: 16,
                              color: playerState.sleepTimerMinutesRemaining != null
                                  ? AppColors.accent
                                  : primaryColor,
                            ),
                            label: Text(
                              playerState.sleepTimerMinutesRemaining != null
                                  ? '${playerState.sleepTimerMinutesRemaining} នាទី'
                                  : playerState.sleepTimerAtEndOfEpisode
                                      ? 'ចប់ភាគ'
                                      : 'ម៉ោងគេង',
                              style: TextStyle(
                                color: playerState.sleepTimerMinutesRemaining != null
                                    ? AppColors.accent
                                    : primaryColor,
                                fontWeight: playerState.sleepTimerMinutesRemaining != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            backgroundColor: playerState.sleepTimerMinutesRemaining != null
                                ? (isDark ? const Color(0x33C89B3C) : AppColors.accentLight.withOpacity(0.5))
                                : (isDark ? const Color(0xFF1B1229) : AppColors.surface),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const SleepTimerDialog(),
                              );
                            },
                          ),

                          // Queue / Playlist Pill
                          ActionChip(
                            avatar: Icon(Icons.queue_music_rounded, size: 16, color: primaryColor),
                            label: Text('បញ្ជីវគ្គ (${playerState.queue.length})'),
                            backgroundColor: isDark ? const Color(0xFF1B1229) : AppColors.surface,
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onPressed: () => _showQueueBottomSheet(context, playerState, controller),
                          ),

                          // Offline Status Pill (if downloaded)
                          if (isDownloaded)
                            ActionChip(
                              avatar: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                              label: const Text('Offline រួចរាល់'),
                              backgroundColor: isDark ? const Color(0xFF122815) : AppColors.successContainer.withOpacity(0.4),
                              side: const BorderSide(color: AppColors.success),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onPressed: () {},
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
