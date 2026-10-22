import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_shimmer.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../home/presentation/widgets/story_card_vertical.dart';
import 'favorites_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(favoriteStoriesProvider);

    return Scaffold(
      appBar: const GlassAppBar(
        title: 'រឿងដែលបានរក្សាទុក (Favorites)',
      ),
      body: storiesAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => AppLoadingShimmer.episodeTilePlaceholder(),
        ),
        error: (err, _) => AppErrorState(
          message: 'មិនអាចផ្ទុកបញ្ជីរឿងពេញចិត្តបានទេ។',
          onRetry: () => ref.refresh(favoriteStoriesProvider),
        ),
        data: (stories) {
          if (stories.isEmpty) {
            return AppEmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'មិនទាន់មានរឿងពេញចិត្តទេ',
              message: 'ចុចលើរូបបេះដូងពេលកំពុងស្តាប់ ឬមើលរឿង ដើម្បីរក្សាទុកនៅទីនេះ។',
              buttonText: 'រុករករឿងឥឡូវនេះ',
              onButtonPressed: () => context.go('/explore'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(favoriteStoriesProvider),
            color: AppColors.accent,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final story = stories[index];
                return Dismissible(
                  key: Key(story.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('លុបចេញ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                  onDismissed: (_) {
                    ref.read(favoritesControllerProvider.notifier).toggleFavorite(story.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('បានលុប "${story.title}" ចេញពីរឿងពេញចិត្ត'),
                        action: SnackBarAction(
                          label: 'ត្រឡប់វិញ',
                          onPressed: () {
                            ref.read(favoritesControllerProvider.notifier).toggleFavorite(story.id);
                          },
                        ),
                      ),
                    );
                  },
                  child: StoryCardVertical(
                    story: story,
                    onTap: () => context.push('/story/${story.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
