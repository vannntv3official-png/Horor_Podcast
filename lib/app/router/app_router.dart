import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/downloads/presentation/downloads_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/monetization/presentation/vip_subscription_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/stories/presentation/story_details_screen.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/supabase_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  final authState = ref.watch(authProvider);

  final hasSeenOnboarding = localStorage.hasSeenOnboarding();
  final isAuthenticated = authState.isAuthenticated;

  return GoRouter(
    initialLocation: () {
      if (isAuthenticated) return '/';
      if (!hasSeenOnboarding) return '/onboarding';
      return '/login';
    }(),
    redirect: (context, state) {
      final seenOnboarding = localStorage.hasSeenOnboarding();
      final isLoggedIn = ref.read(authProvider).isAuthenticated;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' || location == '/register';
      final isOnboardingRoute = location == '/onboarding';

      // 1. Authenticated users always stay in app, never see auth or onboarding
      if (isLoggedIn) {
        if (isAuthRoute || isOnboardingRoute) {
          return '/';
        }
        return null;
      }

      // 2. Unauthenticated first-time users must see onboarding
      if (!seenOnboarding) {
        if (isOnboardingRoute || isAuthRoute) {
          return null;
        }
        return '/onboarding';
      }

      // 3. Unauthenticated returning users must log in
      if (!isAuthRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/story/:id',
        builder: (context, state) {
          final storyId = state.pathParameters['id'] ?? '';
          return StoryDetailsScreen(storyId: storyId);
        },
      ),
      GoRoute(
        path: '/vip',
        builder: (context, state) => const VipSubscriptionScreen(),
      ),

      // Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primaryContainer,
              elevation: 4,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                  label: 'ទំព័រដើម',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded, color: AppColors.primary),
                  label: 'រុករក',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_outline_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.primary),
                  label: 'ពេញចិត្ត',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                  label: 'គណនី',
                ),
              ],
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) {
                  final category = state.uri.queryParameters['category'];
                  final sort = state.uri.queryParameters['sort'];
                  return ExploreScreen(initialCategory: category, initialSort: sort);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
