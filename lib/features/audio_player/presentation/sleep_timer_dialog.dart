import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import 'player_controller.dart';

class SleepTimerDialog extends ConsumerWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder),
      ),
      backgroundColor: isDark ? const Color(0xFF1B1229) : AppColors.surface,
      title: Row(
        children: [
          Icon(Icons.bedtime_outlined, color: isDark ? AppColors.accent : AppColors.primary),
          const SizedBox(width: 10),
          Text(
            'កំណត់ម៉ោងគេង (Sleep Timer)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...AppConstants.sleepTimerMinutes.map((minutes) {
            final isSelected = playerState.sleepTimerMinutesRemaining == minutes;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.timer_outlined,
                color: isSelected ? AppColors.accent : (isDark ? AppColors.darkTextTertiary : AppColors.secondary),
              ),
              title: Text(
                '$minutes នាទី',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.accent : primaryColor,
                ),
              ),
              onTap: () {
                controller.setSleepTimerMinutes(minutes);
                Navigator.of(context).pop();
              },
            );
          }),
          ListTile(
            leading: Icon(
              playerState.sleepTimerAtEndOfEpisode
                  ? Icons.check_circle
                  : Icons.stop_circle_outlined,
              color: playerState.sleepTimerAtEndOfEpisode
                  ? AppColors.accent
                  : (isDark ? AppColors.darkTextTertiary : AppColors.secondary),
            ),
            title: Text(
              'ចប់ភាគនេះ (End of Episode)',
              style: TextStyle(
                fontWeight: playerState.sleepTimerAtEndOfEpisode
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: playerState.sleepTimerAtEndOfEpisode ? AppColors.accent : primaryColor,
              ),
            ),
            onTap: () {
              controller.setSleepTimerEndOfEpisode();
              Navigator.of(context).pop();
            },
          ),
          if (playerState.sleepTimerMinutesRemaining != null ||
              playerState.sleepTimerAtEndOfEpisode) ...[
            Divider(color: isDark ? AppColors.darkOutline : AppColors.outline),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: AppColors.error),
              title: const Text(
                'បិទកម្មវិធីកំណត់ម៉ោង',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                controller.cancelSleepTimer();
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('បោះបង់'),
        ),
      ],
    );
  }
}
