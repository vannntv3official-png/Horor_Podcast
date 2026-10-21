import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        showBack: true,
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
            return const AppEmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'មិនទាន់មានរឿងពេញចិត្តទេ',
              message: 'ចុចលើរូបបេះដូងពេលកំពុងស្តាប់ ឬមើលរឿង ដើម្បីរក្សាទុកនៅទីនេះ។',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(favoriteStoriesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final story = stories[index];
                return StoryCardVertical(
                  story: story,
                  onTap: () => context.push('/story/${story.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
