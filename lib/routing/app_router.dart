import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/supabase_providers.dart';
import '../models/community_post.dart';
import '../models/emergency_guide.dart';
import '../screens/activity_screen.dart';
import '../screens/assistant/assistant_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/community/community_feed_screen.dart';
import '../screens/community/create_post_screen.dart';
import '../screens/community/post_detail_screen.dart';
import '../screens/family/family_screen.dart';
import '../screens/guides/emergency_guide_detail_screen.dart';
import '../screens/guides/emergency_guides_screen.dart';
import '../screens/moderation/moderation_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/operations/bmkg_quakes_screen.dart';
import '../screens/operations/evacuation_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/statistics_screen.dart';

/// Central route paths used throughout the application.
abstract final class AppRoutes {
  static const String onboarding = '/';
  static const String activity = '/activity';
  static const String statistics = '/statistics';
  static const String community = '/community';
  static const String createPost = '/community/create';
  static const String postDetail = '/community/detail';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String evacuation = '/evacuation';
  static const String guides = '/guides';
  static const String guideDetail = '/guides/detail';
  static const String assistant = '/assistant';
  static const String family = '/family';
  static const String moderation = '/moderation';
  static const String bmkgQuakes = '/bmkg-quakes';
}

/// Provider exposing the configured [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: user != null ? AppRoutes.activity : AppRoutes.login,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuth = user != null;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      // Strictly redirect unauthenticated users to the login screen
      if (!isAuth && !isLoginRoute) {
        return AppRoutes.login;
      }

      // If authenticated and visiting login route, redirect to main activity
      if (isAuth && isLoginRoute) {
        return AppRoutes.activity;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.activity,
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: AppRoutes.assistant,
        builder: (context, state) => const AssistantScreen(),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.community,
        builder: (context, state) => const CommunityFeedScreen(),
      ),
      GoRoute(
        path: AppRoutes.createPost,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: AppRoutes.postDetail,
        builder: (context, state) {
          final post = state.extra as CommunityPost;
          return PostDetailScreen(post: post);
        },
      ),
      GoRoute(
        path: AppRoutes.evacuation,
        builder: (context, state) => const EvacuationScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.guides,
        builder: (context, state) => const EmergencyGuidesScreen(),
      ),
      GoRoute(
        path: AppRoutes.guideDetail,
        builder: (context, state) {
          final guide = state.extra as EmergencyGuide;
          return EmergencyGuideDetailScreen(guide: guide);
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.family,
        builder: (context, state) => const FamilyScreen(),
      ),
      GoRoute(
        path: AppRoutes.moderation,
        builder: (context, state) => const ModerationScreen(),
      ),
      GoRoute(
        path: AppRoutes.bmkgQuakes,
        builder: (context, state) => const BmkgQuakesScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
    ),
  );
});
