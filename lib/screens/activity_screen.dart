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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppHeader(showBackButton: Navigator.canPop(context)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentLocalPostsProvider);
          ref.invalidate(activeSosProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Area hero atas dengan background putih dan lekukan melengkung
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.heroCurve),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sm,
                AppSpacing.pagePadding,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  activeSosAsync.when(
                    data: (sos) => sos != null
                        ? Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: SosActiveCard(event: sos),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const QuickAccessBar(),
                ],
              ),
            ),
            // Konten komunitas di atas kanvas krem
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                80, // room for FAB
              ),
              child: LocalCommunitySection(
                cityName: titleCity,
                postsAsync: recentPostsAsync,
              ),
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
