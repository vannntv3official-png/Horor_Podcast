import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../core/logging/app_logger.dart';
import '../models/user_profile_model.dart';
import 'supabase_provider.dart';

class AuthState {
  final User? user;
  final UserProfileModel? profile;
  final bool isLoading;
  final AppException? error;
  final bool isGuest;

  const AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
    this.isGuest = true,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    UserProfileModel? profile,
    bool? isLoading,
    AppException? error,
    bool clearError = false,
    bool? isGuest,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _supabase;
  final Ref _ref;

  AuthNotifier(this._supabase, this._ref) : super(const AuthState()) {
    _init();
  }

  void _init() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      state = state.copyWith(user: currentUser, isGuest: false);
      _ref.read(localStorageProvider).setHasSeenOnboarding(true);
      _fetchProfile(currentUser.id);
    }

    _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        state = state.copyWith(user: user, isGuest: false);
        _ref.read(localStorageProvider).setHasSeenOnboarding(true);
        _fetchProfile(user.id);
      } else if (data.event == AuthChangeEvent.signedOut) {
        _ref.read(localStorageProvider).setHasSeenOnboarding(true);
        state = const AuthState(isGuest: true);
      }
    });
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      String role = 'user';
      try {
        final roleRes = await _supabase
            .from('user_roles')
            .select('role')
            .eq('user_id', userId)
            .maybeSingle();
        if (roleRes != null && roleRes['role'] != null) {
          role = roleRes['role'] as String;
        }
      } catch (_) {}

      if (res != null) {
        final profile = UserProfileModel.fromJson({
          ...res,
          'user_roles': [
            {'role': role}
          ],
        });
        state = state.copyWith(profile: profile);
      } else {
        // Auto-create missing profile in database so user appears in admin dashboard
        final user = _supabase.auth.currentUser;
        final name = user?.userMetadata?['display_name'] as String? ??
            user?.email?.split('@').first ??
            'អ្នកស្តាប់';
        await _supabase.from('profiles').upsert({
          'id': userId,
          'display_name': name,
          'preferred_language': 'km',
        });
        await _supabase.from('user_roles').upsert({
          'user_id': userId,
          'role': 'user',
        }, onConflict: 'user_id,role');
        state = state.copyWith(
          profile: UserProfileModel(
            id: userId,
            displayName: name,
            preferredLanguage: 'km',
            role: role,
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      AppLogger.warning('Failed to load user profile: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isGuest: false,
          isLoading: false,
        );
        await _ref.read(localStorageProvider).setHasSeenOnboarding(true);
        await _fetchProfile(response.user!.id);
        await _syncGuestFavorites(response.user!.id);
        return true;
      }
      return false;
    } catch (e, st) {
      final appEx = ErrorHandler.handle(e, st);
      state = state.copyWith(isLoading: false, error: appEx);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      if (response.user != null) {
        if (response.user!.identities?.isEmpty ?? false) {
          state = state.copyWith(
            isLoading: false,
            error: const AuthException(
              message: 'អ៊ីមែលនេះមានគណនីរួចហើយ! សូមចូលទៅកាន់ផ្ទាំង "ចូលគណនី (Sign In)"។',
            ),
          );
          return false;
        }
        if (response.session != null) {
          state = state.copyWith(
            user: response.user,
            isGuest: false,
            isLoading: false,
          );
          await _ref.read(localStorageProvider).setHasSeenOnboarding(true);
          await _fetchProfile(response.user!.id);
          await _syncGuestFavorites(response.user!.id);
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: const AuthException(
              message:
                  'គណនីត្រូវបានបង្កើត! ប៉ុន្តែតម្រូវឱ្យ Confirm អ៊ីមែលជាមុនសិន។ សូមពិនិត្យ Inbox អ៊ីមែល ឬបិទ "Confirm email" ក្នុង Supabase Dashboard (Auth > Providers > Email)។',
            ),
          );
          return false;
        }
      }
      return false;
    } catch (e, st) {
      final appEx = ErrorHandler.handle(e, st);
      state = state.copyWith(isLoading: false, error: appEx);
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      AppLogger.warning('Sign out error: $e');
    } finally {
      await _ref.read(localStorageProvider).setHasSeenOnboarding(true);
      state = const AuthState(isGuest: true);
    }
  }

  Future<bool> updateProfile({String? displayName, String? preferredLanguage}) async {
    final user = state.user;
    if (user == null) return false;
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (displayName != null) updates['display_name'] = displayName.trim();
      if (preferredLanguage != null) updates['preferred_language'] = preferredLanguage;

      await _supabase.from('profiles').update(updates).eq('id', user.id);
      await _fetchProfile(user.id);
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to update profile', e, st);
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    final user = state.user;
    if (user == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      // Direct RPC or delete self row triggering cascade
      await _supabase.from('profiles').delete().eq('id', user.id);
      await _supabase.auth.signOut();
      await _ref.read(localStorageProvider).setHasSeenOnboarding(true);
      state = const AuthState(isGuest: true);
      return true;
    } catch (e, st) {
      final appEx = ErrorHandler.handle(e, st);
      state = state.copyWith(isLoading: false, error: appEx);
      return false;
    }
  }

  Future<void> _syncGuestFavorites(String userId) async {
    try {
      final localStorage = _ref.read(localStorageProvider);
      final guestFavorites = localStorage.getGuestFavorites();
      if (guestFavorites.isNotEmpty) {
        for (final storyId in guestFavorites) {
          await _supabase.from('favorites').upsert({
            'user_id': userId,
            'story_id': storyId,
          }, onConflict: 'user_id,story_id');
        }
        await localStorage.clearGuestFavorites();
      }
    } catch (e) {
      AppLogger.warning('Failed syncing guest favorites: $e');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthNotifier(supabase, ref);
});
