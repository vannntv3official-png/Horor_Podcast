import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../app/config/env_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/debouncer.dart';
import '../../../shared/models/episode_model.dart';
import '../../../shared/models/story_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../downloads/presentation/download_controller.dart';
import '../data/audio_handler.dart';

final audioHandlerProvider = Provider<KhmerAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in bootstrap');
});

class PlayerStateModel {
  final EpisodeModel? currentEpisode;
  final StoryModel? currentStory;
  final List<EpisodeModel> queue;
  final int queueIndex;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double speed;
  final LoopMode loopMode;
  final bool isShuffle;
  final int? sleepTimerMinutesRemaining;
  final bool sleepTimerAtEndOfEpisode;
  final AppException? error;

  const PlayerStateModel({
    this.currentEpisode,
    this.currentStory,
    this.queue = const [],
    this.queueIndex = 0,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.loopMode = LoopMode.off,
    this.isShuffle = false,
    this.sleepTimerMinutesRemaining,
    this.sleepTimerAtEndOfEpisode = false,
    this.error,
  });

  bool get hasMedia => currentEpisode != null;

  PlayerStateModel copyWith({
    EpisodeModel? currentEpisode,
    StoryModel? currentStory,
    List<EpisodeModel>? queue,
    int? queueIndex,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? speed,
    LoopMode? loopMode,
    bool? isShuffle,
    int? sleepTimerMinutesRemaining,
    bool clearSleepTimer = false,
    bool? sleepTimerAtEndOfEpisode,
    AppException? error,
    bool clearError = false,
  }) {
    return PlayerStateModel(
      currentEpisode: currentEpisode ?? this.currentEpisode,
      currentStory: currentStory ?? this.currentStory,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      loopMode: loopMode ?? this.loopMode,
      isShuffle: isShuffle ?? this.isShuffle,
      sleepTimerMinutesRemaining: clearSleepTimer
          ? null
          : (sleepTimerMinutesRemaining ?? this.sleepTimerMinutesRemaining),
      sleepTimerAtEndOfEpisode: clearSleepTimer
          ? false
          : (sleepTimerAtEndOfEpisode ?? this.sleepTimerAtEndOfEpisode),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PlayerController extends StateNotifier<PlayerStateModel> {
  final KhmerAudioHandler _handler;
  final Ref _ref;
  final Debouncer _progressDebouncer = Debouncer(delay: const Duration(seconds: 8));
  Timer? _sleepCountdownTimer;

  PlayerController(this._handler, this._ref) : super(const PlayerStateModel()) {
    _bindStreams();
    _handler.onPlaybackCompleted = _handlePlaybackCompleted;
  }

  void _bindStreams() {
    _handler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final isBuffering = playbackState.processingState == AudioProcessingState.buffering ||
          playbackState.processingState == AudioProcessingState.loading;

      state = state.copyWith(
        isPlaying: isPlaying,
        isBuffering: isBuffering,
        position: playbackState.position,
        speed: playbackState.speed,
      );

      // Periodically sync listening progress
      _scheduleProgressSync();
    });

    _handler.mediaItem.listen((item) {
      if (item != null && item.duration != null) {
        state = state.copyWith(duration: item.duration!);
      }
    });

    _handler.player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _handler.player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });
  }

  void _handlePlaybackCompleted() {
    _scheduleProgressSync(immediate: true, completed: true);

    if (state.loopMode == LoopMode.one) {
      seek(Duration.zero);
      _handler.play();
      return;
    }

    if (state.queue.isNotEmpty) {
      if (state.queueIndex < state.queue.length - 1) {
        playNext();
      } else if (state.loopMode == LoopMode.all) {
        playEpisode(
          episode: state.queue.first,
          story: state.currentStory,
          playlist: state.queue,
        );
      }
    }
  }

  Future<void> playEpisode({
    required EpisodeModel episode,
    StoryModel? story,
    List<EpisodeModel>? playlist,
    Duration? startPosition,
    String? localAudioPath,
  }) async {
    state = state.copyWith(
      currentEpisode: episode,
      currentStory: story,
      queue: playlist ?? [episode],
      queueIndex: playlist != null ? playlist.indexOf(episode) : 0,
      clearError: true,
      isBuffering: true,
    );

    try {
      // Smart offline detection: prefer downloaded local file if available
      String? resolvedAudioPath = localAudioPath;
      if (resolvedAudioPath == null) {
        try {
          final downloads = _ref.read(downloadsControllerProvider);
          final downloaded = downloads.downloadedItems[episode.id];
          if (downloaded != null) {
            resolvedAudioPath = downloaded.localFilePath;
          }
        } catch (_) {}
      }

      final isLocal = resolvedAudioPath != null;
      final audioUrl = resolvedAudioPath ?? episode.getAudioUrl(EnvConfig.supabaseUrl);
      final coverUrl = story?.getCoverUrl(EnvConfig.supabaseUrl);

      await _handler.playCustomMediaItem(
        audioUrl: audioUrl,
        episodeId: episode.id,
        title: episode.title,
        storyTitle: story?.title ?? 'Khmer Horror Podcast',
        coverUrl: coverUrl,
        initialPosition: startPosition,
        duration: Duration(seconds: episode.durationSeconds),
        isLocalFile: isLocal,
      );

      _recordListeningEvent(episode.id, 'play');
    } catch (e, st) {
      final appEx = ErrorHandler.handle(e, st);
      state = state.copyWith(isBuffering: false, error: appEx);
    }
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _handler.pause();
      _scheduleProgressSync(immediate: true);
    } else {
      await _handler.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _handler.seek(position);
    _scheduleProgressSync(immediate: true);
  }

  Future<void> seekForward({int seconds = 10}) async {
    final target = state.position + Duration(seconds: seconds);
    final clamped = target > state.duration ? state.duration : target;
    await seek(clamped);
  }

  Future<void> seekBackward({int seconds = 10}) async {
    final target = state.position - Duration(seconds: seconds);
    final clamped = target < Duration.zero ? Duration.zero : target;
    await seek(clamped);
  }

  Future<void> setSpeed(double speed) async {
    await _handler.setSpeed(speed);
    state = state.copyWith(speed: speed);
    _ref.read(localStorageProvider).savePlaybackSpeed(speed);
  }

  Future<void> toggleRepeatMode() async {
    final nextMode = switch (state.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _handler.setLoopMode(nextMode);
    state = state.copyWith(loopMode: nextMode);
  }

  Future<void> toggleShuffle() async {
    final newShuffle = !state.isShuffle;
    await _handler.setShuffleEnabled(newShuffle);
    state = state.copyWith(isShuffle: newShuffle);
  }

  Future<void> stop() async {
    _sleepCountdownTimer?.cancel();
    await _handler.stop();
    state = const PlayerStateModel();
  }

  // Next / Previous Episode
  Future<void> playNext() async {
    if (state.queue.isNotEmpty && state.queueIndex < state.queue.length - 1) {
      final nextIndex = state.queueIndex + 1;
      final nextEpisode = state.queue[nextIndex];
      await playEpisode(
        episode: nextEpisode,
        story: state.currentStory,
        playlist: state.queue,
      );
    }
  }

  Future<void> playPrevious() async {
    if (state.position.inSeconds > 5) {
      await seek(Duration.zero);
      return;
    }
    if (state.queue.isNotEmpty && state.queueIndex > 0) {
      final prevIndex = state.queueIndex - 1;
      final prevEpisode = state.queue[prevIndex];
      await playEpisode(
        episode: prevEpisode,
        story: state.currentStory,
        playlist: state.queue,
      );
    }
  }

  // Sleep Timer
  void setSleepTimerMinutes(int minutes) {
    _handler.setSleepTimerMinutes(minutes, onFinished: () {
      state = state.copyWith(clearSleepTimer: true);
    });

    state = state.copyWith(
      sleepTimerMinutesRemaining: minutes,
      sleepTimerAtEndOfEpisode: false,
    );

    _sleepCountdownTimer?.cancel();
    _sleepCountdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final current = state.sleepTimerMinutesRemaining;
      if (current != null && current > 1) {
        state = state.copyWith(sleepTimerMinutesRemaining: current - 1);
      } else {
        timer.cancel();
        state = state.copyWith(clearSleepTimer: true);
      }
    });
  }

  void setSleepTimerEndOfEpisode() {
    _handler.setSleepTimerEndOfEpisode();
    _sleepCountdownTimer?.cancel();
    state = state.copyWith(
      clearSleepTimer: true,
      sleepTimerAtEndOfEpisode: true,
    );
  }

  void cancelSleepTimer() {
    _handler.cancelSleepTimer();
    _sleepCountdownTimer?.cancel();
    state = state.copyWith(clearSleepTimer: true);
  }

  // Sync listening progress to Supabase
  void _scheduleProgressSync({bool immediate = false, bool completed = false}) {
    if (immediate) {
      _syncProgress(completed: completed);
    } else {
      _progressDebouncer.run(() => _syncProgress(completed: completed));
    }
  }

  Future<void> _syncProgress({bool completed = false}) async {
    final episode = state.currentEpisode;
    final user = _ref.read(authProvider).user;
    if (episode == null || user == null) return;

    final posSeconds = state.position.inSeconds;
    if (posSeconds < 3 && !completed) return;

    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.from('listening_progress').upsert({
        'user_id': user.id,
        'episode_id': episode.id,
        'position_seconds': posSeconds,
        'completed': completed || (state.duration.inSeconds > 0 && posSeconds >= state.duration.inSeconds - 5),
        'last_played_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, episode_id');
    } catch (e) {
      // Non-blocking background sync failure
      AppLogger.warning('Failed to sync listening progress: $e');
    }
  }

  Future<void> _recordListeningEvent(String episodeId, String eventType) async {
    try {
      final user = _ref.read(authProvider).user;
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.from('listening_events').insert({
        'user_id': user?.id,
        'episode_id': episodeId,
        'event_type': eventType,
        'listened_seconds': 0,
      });
    } catch (e) {
      // Non-blocking telemetry
      AppLogger.warning('Telemetry record failed: $e');
    }
  }

  @override
  void dispose() {
    _progressDebouncer.dispose();
    _sleepCountdownTimer?.cancel();
    super.dispose();
  }
}

final playerControllerProvider = StateNotifierProvider<PlayerController, PlayerStateModel>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return PlayerController(handler, ref);
});
