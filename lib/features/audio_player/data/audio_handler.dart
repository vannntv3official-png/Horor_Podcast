import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/logging/app_logger.dart';

Future<KhmerAudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => KhmerAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.khmerhorrorpodcast.app.audio',
      androidNotificationChannelName: 'Khmer Horror Podcast Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );
}

class KhmerAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;

  KhmerAudioHandler() {
    _initPlayerEvents();
  }

  AudioPlayer get player => _player;
  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;

  void _initPlayerEvents() {
    // Broadcast playback state changes
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
            MediaAction.setSpeed,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });

    // Handle completed playback
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_sleepTimerEndTime != null) {
          // If sleep timer was set for end of episode, pause
          pause();
          cancelSleepTimer();
        }
      }
    });
  }

  Future<void> playCustomMediaItem({
    required String audioUrl,
    required String episodeId,
    required String title,
    required String storyTitle,
    String? coverUrl,
    Duration? initialPosition,
    Duration? duration,
    bool isLocalFile = false,
  }) async {
    try {
      final item = MediaItem(
        id: episodeId,
        album: storyTitle,
        title: title,
        artist: 'Khmer Horror Podcast',
        duration: duration,
        artUri: coverUrl != null ? Uri.tryParse(coverUrl) : null,
      );
      mediaItem.add(item);

      if (isLocalFile) {
        await _player.setFilePath(audioUrl, initialPosition: initialPosition);
      } else {
        await _player.setUrl(audioUrl, initialPosition: initialPosition);
      }

      await _player.play();
    } catch (e, st) {
      AppLogger.error('Failed to play audio source: $audioUrl', e, st);
      rethrow;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    cancelSleepTimer();
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  // Sleep Timer
  void setSleepTimerMinutes(int minutes, {VoidCallback? onFinished}) {
    cancelSleepTimer();
    _sleepTimerEndTime = DateTime.now().add(Duration(minutes: minutes));
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      pause();
      cancelSleepTimer();
      onFinished?.call();
    });
  }

  void setSleepTimerEndOfEpisode() {
    cancelSleepTimer();
    _sleepTimerEndTime = DateTime.now().add(const Duration(hours: 3)); // sentinel
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndTime = null;
  }

  Future<void> dispose() async {
    cancelSleepTimer();
    await _player.dispose();
  }
}
