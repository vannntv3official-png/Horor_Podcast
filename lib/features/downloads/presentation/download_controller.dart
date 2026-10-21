import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/download_item_model.dart';
import '../../../shared/models/episode_model.dart';
import '../../../shared/models/story_model.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/download_manager.dart';

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(localStorageProvider);
  return DownloadManager(dio, storage);
});

class DownloadsState {
  final Map<String, DownloadItemModel> downloadedItems;
  final Map<String, double> activeProgress;
  final int totalStorageBytes;
  final AppException? error;

  const DownloadsState({
    this.downloadedItems = const {},
    this.activeProgress = const {},
    this.totalStorageBytes = 0,
    this.error,
  });

  bool isDownloaded(String episodeId) => downloadedItems.containsKey(episodeId);
  bool isDownloading(String episodeId) => activeProgress.containsKey(episodeId);
  double getProgress(String episodeId) => activeProgress[episodeId] ?? 0.0;

  DownloadsState copyWith({
    Map<String, DownloadItemModel>? downloadedItems,
    Map<String, double>? activeProgress,
    int? totalStorageBytes,
    AppException? error,
    bool clearError = false,
  }) {
    return DownloadsState(
      downloadedItems: downloadedItems ?? this.downloadedItems,
      activeProgress: activeProgress ?? this.activeProgress,
      totalStorageBytes: totalStorageBytes ?? this.totalStorageBytes,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DownloadsNotifier extends StateNotifier<DownloadsState> {
  final DownloadManager _manager;

  DownloadsNotifier(this._manager) : super(const DownloadsState()) {
    _loadDownloads();
  }

  void _loadDownloads() {
    final items = _manager.getDownloadedEpisodes();
    int total = 0;
    for (final item in items.values) {
      total += item.fileSizeBytes;
    }
    state = state.copyWith(
      downloadedItems: items,
      totalStorageBytes: total,
    );
  }

  Future<void> downloadEpisode({
    required EpisodeModel episode,
    required StoryModel story,
  }) async {
    final progressMap = Map<String, double>.from(state.activeProgress);
    progressMap[episode.id] = 0.0;
    state = state.copyWith(activeProgress: progressMap, clearError: true);

    await _manager.startDownload(
      episode: episode,
      story: story,
      onProgress: (progress) {
        final map = Map<String, double>.from(state.activeProgress);
        map[episode.id] = progress;
        state = state.copyWith(activeProgress: map);
      },
      onCompleted: (item) {
        final map = Map<String, double>.from(state.activeProgress);
        map.remove(episode.id);

        final items = Map<String, DownloadItemModel>.from(state.downloadedItems);
        items[episode.id] = item;

        final newTotal = state.totalStorageBytes + item.fileSizeBytes;
        state = state.copyWith(
          activeProgress: map,
          downloadedItems: items,
          totalStorageBytes: newTotal,
        );
      },
      onError: (error) {
        final map = Map<String, double>.from(state.activeProgress);
        map.remove(episode.id);
        state = state.copyWith(activeProgress: map, error: error);
      },
    );
  }

  void cancelDownload(String episodeId) {
    _manager.cancelDownload(episodeId);
    final map = Map<String, double>.from(state.activeProgress);
    map.remove(episodeId);
    state = state.copyWith(activeProgress: map);
  }

  Future<void> deleteDownload(String episodeId) async {
    final item = state.downloadedItems[episodeId];
    final size = item?.fileSizeBytes ?? 0;

    await _manager.deleteDownload(episodeId);

    final items = Map<String, DownloadItemModel>.from(state.downloadedItems);
    items.remove(episodeId);

    final newTotal = (state.totalStorageBytes - size).clamp(0, double.maxFinite.toInt());
    state = state.copyWith(
      downloadedItems: items,
      totalStorageBytes: newTotal,
    );
  }
}

final downloadsControllerProvider =
    StateNotifierProvider<DownloadsNotifier, DownloadsState>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return DownloadsNotifier(manager);
});
