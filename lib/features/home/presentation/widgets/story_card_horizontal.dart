import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../app/config/env_config.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/story_model.dart';

class StoryCardHorizontal extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const StoryCardHorizontal({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = story.getCoverUrl(EnvConfig.supabaseUrl);
    final displayUrl = coverUrl.isNotEmpty ? coverUrl : AppConstants.defaultCoverUrl;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 154,
      margin: const EdgeInsets.only(right: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Container(
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? const Color(0x66000000) : const Color(0x141D102F),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: displayUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                    color: isDark ? const Color(0xFF281C38) : AppColors.secondaryLight,
                    child: Icon(Icons.music_note, color: isDark ? AppColors.accent : AppColors.secondary),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: isDark ? const Color(0xFF281C38) : AppColors.secondaryLight,
                    child: Icon(Icons.music_note, color: isDark ? AppColors.accent : AppColors.secondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              story.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: 3),
            // Category or Narrator
            Text(
              story.narratorName != null
                  ? 'និទាន: ${story.narratorName}'
                  : (story.categoryName ?? 'រឿងខ្មោច'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
