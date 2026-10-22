import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_shimmer.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../shared/models/story_model.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../../home/presentation/widgets/category_pills.dart';
import '../../home/presentation/widgets/story_card_vertical.dart';

final searchStoriesProvider = FutureProvider.family<List<StoryModel>, ({String query, String? categorySlug, String sortBy})>((ref, params) async {
  final repo = ref.watch(storiesRepositoryProvider);
  return await repo.getStories(
    searchQuery: params.query,
    categorySlug: params.categorySlug,
    sortBy: params.sortBy,
    limit: 30,
  );
});

class ExploreScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialSort;

  const ExploreScreen({
    super.key,
    this.initialCategory,
    this.initialSort,
  });

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 350));
  String _currentQuery = '';
  String? _selectedCategorySlug;
  String _sortBy = 'newest';
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _selectedCategorySlug = widget.initialCategory;
    _sortBy = widget.initialSort ?? 'newest';
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    final storage = ref.read(localStorageProvider);
    setState(() {
      _recentSearches = storage.getRecentSearches();
    });
  }

  void _onSearchChanged(String val) {
    _debouncer.run(() {
      setState(() {
        _currentQuery = val.trim();
      });
      if (val.trim().isNotEmpty) {
        ref.read(localStorageProvider).addRecentSearch(val.trim());
        _loadRecentSearches();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final searchResultsAsync = ref.watch(
      searchStoriesProvider((
        query: _currentQuery,
        categorySlug: _selectedCategorySlug,
        sortBy: _sortBy,
      )),
    );

    return Scaffold(
      appBar: const GlassAppBar(
        title: 'ស្វែងរក និងរុករក (Explore)',
        showBack: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Search Input Box
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'ស្វែងរកតាមចំណងជើង រឿង ឬអ្នកនិទាន...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.secondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textTertiary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _currentQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // Categories Chips
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  data: (categories) => Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: CategoryPills(
                      categories: categories,
                      selectedSlug: _selectedCategorySlug,
                      onSelect: (slug) {
                        setState(() => _selectedCategorySlug = slug);
                      },
                    ),
                  ),
                  loading: () => const SizedBox(height: 40),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Sort dropdown & Recent Searches
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'តម្រៀបតាម:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      DropdownButton<String>(
                        value: _sortBy,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        items: const [
                          DropdownMenuItem(value: 'newest', child: Text('ចេញថ្មីបំផុត (Newest)')),
                          DropdownMenuItem(value: 'popular', child: Text('ពេញនិយមបំផុត (Popular)')),
                          DropdownMenuItem(value: 'title', child: Text('តាមអក្ខរក្រម (Title)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _sortBy = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Search Chips (if query is empty)
              if (_currentQuery.isEmpty && _recentSearches.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ការស្វែងរកថ្មីៗ',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            TextButton(
                              onPressed: () async {
                                await ref.read(localStorageProvider).clearRecentSearches();
                                _loadRecentSearches();
                              },
                              child: const Text('សម្អាត'),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _recentSearches.map((tag) {
                            return ActionChip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.glassBorder),
                              onPressed: () {
                                _searchController.text = tag;
                                setState(() => _currentQuery = tag);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Results List
              searchResultsAsync.when(
                data: (stories) {
                  if (stories.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'រកមិនឃើញរឿងទេ',
                        message: 'សូមសាកល្បងស្វែងរកដោយប្រើពាក្យគន្លឹះផ្សេងទៀត។',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final story = stories[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StoryCardVertical(
                              story: story,
                              onTap: () => context.push('/story/${story.id}'),
                            ),
                          );
                        },
                        childCount: stories.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => AppLoadingShimmer.episodeTilePlaceholder(),
                      childCount: 6,
                    ),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorState(
                    message: 'មិនអាចស្វែងរកបានទេ។ សូមព្យាយាមម្តងទៀត។',
                    onRetry: () => ref.refresh(
                      searchStoriesProvider((
                        query: _currentQuery,
                        categorySlug: _selectedCategorySlug,
                        sortBy: _sortBy,
                      )),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
