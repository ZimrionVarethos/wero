import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/auth_providers.dart';
import '../core/providers/community_providers.dart';
import '../core/providers/operations_providers.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_header.dart';
import 'activity/widgets/local_community_section.dart';
import 'activity/widgets/quick_access_bar.dart';
import 'operations/widgets/sos_active_card.dart';
import 'operations/widgets/sos_button.dart';

/// Activity Discovery & Operations dashboard screen.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  static const routeName = '/activity';

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  void _onNavTap(int index) {
    if (index == 0) return;
    if (index == 1) {
      context.go(AppRoutes.assistant);
      return;
    }
    if (index == 2) {
      context.go(AppRoutes.community);
      return;
    }
    if (index == 3) {
      context.go(AppRoutes.statistics);
      return;
    }
    if (index == 4) {
      context.go(AppRoutes.profile);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSosAsync = ref.watch(activeSosProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final regions = ref.watch(regionsListProvider).asData?.value;
    final regionName =
        regions?.where((r) => r.id == profile?.regionId).firstOrNull?.name ??
        profile?.regionName;
    final recentPostsAsync = ref.watch(recentLocalPostsProvider);

    final titleCity = regionName != null && regionName.isNotEmpty
        ? regionName
        : 'Lokal';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(showBackButton: Navigator.canPop(context)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentLocalPostsProvider);
          ref.invalidate(activeSosProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.base,
            AppSpacing.pagePadding,
            80, // room for FAB
          ),
          children: [
            activeSosAsync.when(
              data: (sos) => sos != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SosActiveCard(event: sos),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const QuickAccessBar(),
            const SizedBox(height: AppSpacing.lg),
            LocalCommunitySection(
              cityName: titleCity,
              postsAsync: recentPostsAsync,
            ),
          ],
        ),
      ),
      floatingActionButton: const SosButton(),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
        onTap: _onNavTap,
      ),
    );
  }
}
