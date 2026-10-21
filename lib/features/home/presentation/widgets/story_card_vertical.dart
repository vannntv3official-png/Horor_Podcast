import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../app/config/env_config.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../shared/models/story_model.dart';

class StoryCardVertical extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const StoryCardVertical({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = story.getCoverUrl(EnvConfig.supabaseUrl);
    final displayUrl = coverUrl.isNotEmpty ? coverUrl : AppConstants.defaultCoverUrl;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 20,
      onTap: onTap,
      child: Row(
        children: [
          // Cover Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: displayUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.secondaryLight),
              errorWidget: (_, __, ___) => Container(color: AppColors.secondaryLight),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (story.categoryName != null) ...[
                  Text(
                    story.categoryName!,
                    style: const TextStyle(
                      color: AppColors.accentDark,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (story.narratorName != null) ...[
                      const Icon(Icons.mic_none_rounded, size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          story.narratorName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
