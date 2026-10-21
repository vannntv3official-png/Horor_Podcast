import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import 'player_controller.dart';

class PlaybackSpeedDialog extends ConsumerWidget {
  const PlaybackSpeedDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);

    return SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      title: Text(
        'ល្បឿនចាក់សំឡេង (Playback Speed)',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
      ),
      children: AppConstants.playbackSpeeds.map((speed) {
        final isSelected = playerState.speed == speed;
        return SimpleDialogOption(
          onPressed: () {
            controller.setSpeed(speed);
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${speed}x ${speed == 1.0 ? "(ធម្មតា)" : ""}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.accentDark : AppColors.textPrimary,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_rounded, color: AppColors.accentDark),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
