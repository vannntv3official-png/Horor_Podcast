import 'dart:async';
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

  // 1. Initialize Local Storage (fail-safe with fallback)
  final localStorage = await LocalStorage.create();

  // 2. Initialize Supabase (with strict timeout so startup never stalls)
  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    ).timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        AppLogger.warning('Supabase initialization timed out, continuing startup');
        return Supabase.instance;
      },
    );
    AppLogger.info('Supabase initialized successfully.');
  } catch (e) {
    AppLogger.warning('Supabase initialization fallback: $e');
  }

  // 3. Initialize Background Audio Engine (with strict timeout to avoid splash screen deadlocks)
  KhmerAudioHandler audioHandler;
  try {
    audioHandler = await initAudioService().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        AppLogger.warning('AudioService.init timed out, using fallback KhmerAudioHandler');
        return KhmerAudioHandler();
      },
    );
    AppLogger.info('Background audio service initialized.');
  } catch (e, st) {
    AppLogger.error('Audio service init fallback: $e', e, st);
    audioHandler = KhmerAudioHandler();
  }

  // 4. Guaranteed to run the app immediately
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
