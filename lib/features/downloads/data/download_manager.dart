import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../app/config/env_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/download_item_model.dart';
import '../../../shared/models/episode_model.dart';
import '../../../shared/models/story_model.dart';

class DownloadManager {
  final Dio _dio;
  final LocalStorage _localStorage;
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadManager(this._dio, this._localStorage);

  Future<String> _getAudioDirectoryPath() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(docsDir.path, 'offline_podcasts'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir.path;
  }

  Map<String, DownloadItemModel> getDownloadedEpisodes() {
    final registry = _localStorage.getDownloadsRegistry();
    final Map<String, DownloadItemModel> result = {};
    registry.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = DownloadItemModel.fromJson(value);
      }
    });
    return result;
  }

  Future<void> _saveRegistry(Map<String, DownloadItemModel> registry) async {
    final Map<String, dynamic> data = {};
    registry.forEach((key, value) {
      data[key] = value.toJson();
    });
    await _localStorage.saveDownloadsRegistry(data);
  }

  Future<void> startDownload({
    required EpisodeModel episode,
    required StoryModel story,
    required void Function(double progress) onProgress,
    required void Function(DownloadItemModel item) onCompleted,
    required void Function(AppException error) onError,
  }) async {
    if (!episode.allowDownload) {
      onError(const DownloadException(message: 'ភាគនេះមិនត្រូវបានអនុញ្ញាតឱ្យទាញយកក្រៅបណ្តាញទេ។'));
      return;
    }

    final audioDir = await _getAudioDirectoryPath();
    // Safe filename without path traversal
    final safeFileName = 'ep_${episode.id}.mp3';
    final targetFilePath = p.join(audioDir, safeFileName);

    final cancelToken = CancelToken();
    _cancelTokens[episode.id] = cancelToken;

    final downloadUrl = episode.getAudioUrl(EnvConfig.supabaseUrl);

    try {
      AppLogger.info('Starting offline download: $downloadUrl -> $targetFilePath');

      await _dio.download(
        downloadUrl,
        targetFilePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > EnvConfig.maxDownloadSizeBytes) {
            cancelToken.cancel('File exceeds maximum download size limit');
            throw const DownloadException(message: 'ទំហំឯកសារធំលើសកម្រិតកំណត់ (100MB)។');
          }
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            onProgress(progress);
          }
        },
      );

      final file = File(targetFilePath);
      if (!await file.exists()) {
        throw const DownloadException(message: 'ឯកសារទាញយកមិនត្រូវបានរកឃើញលើឧបករណ៍ទេ។');
      }

      final fileBytes = await file.length();
      final item = DownloadItemModel(
        episodeId: episode.id,
        storyId: story.id,
        storyTitle: story.title,
        episodeTitle: episode.title,
        episodeNumber: episode.episodeNumber,
        localFilePath: targetFilePath,
        fileSizeBytes: fileBytes,
        durationSeconds: episode.durationSeconds,
        coverPath: story.coverPath,
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedAt: DateTime.now(),
      );

      final registry = getDownloadedEpisodes();
      registry[episode.id] = item;
      await _saveRegistry(registry);

      _cancelTokens.remove(episode.id);
      onCompleted(item);
    } catch (e, st) {
      _cancelTokens.remove(episode.id);
      AppLogger.error('Download failed for episode ${episode.id}', e, st);

      // Clean up incomplete file
      final tempFile = File(targetFilePath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (e is DownloadException) {
        onError(e);
      } else {
        onError(const DownloadException());
      }
    }
  }

  void cancelDownload(String episodeId) {
    if (_cancelTokens.containsKey(episodeId)) {
      _cancelTokens[episodeId]!.cancel('Cancelled by user');
      _cancelTokens.remove(episodeId);
    }
  }

  Future<void> deleteDownload(String episodeId) async {
    final registry = getDownloadedEpisodes();
    final item = registry[episodeId];
    if (item != null) {
      final file = File(item.localFilePath);
      if (await file.exists()) {
        await file.delete();
      }
      registry.remove(episodeId);
      await _saveRegistry(registry);
      AppLogger.info('Deleted offline download for episode $episodeId');
    }
  }

  Future<int> getTotalDownloadedSizeBytes() async {
    final registry = getDownloadedEpisodes();
    int total = 0;
    for (final item in registry.values) {
      total += item.fileSizeBytes;
    }
    return total;
  }
}
