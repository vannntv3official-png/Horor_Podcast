import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'app/app.dart';
import 'app/config/env_config.dart';
import 'core/logging/app_logger.dart';
import 'core/storage/local_storage.dart';
import 'features/audio_player/data/audio_handler.dart';
import 'features/audio_player/presentation/player_controller.dart';
import 'shared/providers/supabase_provider.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('Initializing Khmer Horror Podcast client...');

  // Initialize Local Storage
  final localStorage = await LocalStorage.create();

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    AppLogger.info('Supabase initialized successfully.');
  } catch (e) {
    AppLogger.warning('Supabase initialization fallback: $e');
  }

  // Initialize Background Audio Engine
  KhmerAudioHandler audioHandler;
  try {
    audioHandler = await initAudioService();
    AppLogger.info('Background audio service initialized.');
  } catch (e, st) {
    AppLogger.error('Audio service init fallback', e, st);
    audioHandler = KhmerAudioHandler();
  }

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const KhmerHorrorApp(),
    ),
  );
}
