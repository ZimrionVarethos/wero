import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/supabase_providers.dart';
import '../../models/region.dart';
import '../../models/user_profile.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_header.dart';
import 'widgets/profile_edit_dialogs.dart';

/// Screen for displaying and updating user profile and default kabupaten/kota.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSaving = false;

  void _onNavTap(int index) {
    if (index == 0) {
      context.go(AppRoutes.activity);
    } else if (index == 1) {
      context.go(AppRoutes.assistant);
    } else if (index == 2) {
      context.go(AppRoutes.community);
    } else if (index == 3) {
      return;
    }
  }

  Future<void> _changeRegion(List<Region> regions, UserProfile? profile) async {
    final sel = await ProfileEditDialogs.pickRegion(
      context,
      regions: regions,
      profile: profile,
    );
    if (sel != null && sel != profile?.regionId) {
      setState(() => _isSaving = true);
      try {
        await ref
            .read(userProfileProvider.notifier)
            .updateProfile(regionId: sel);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wilayah berhasil diperbarui.')),
          );
        }
      } on AppException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editDisplayName(UserProfile? profile) async {
    final name = await ProfileEditDialogs.editDisplayName(
      context,
      profile: profile,
    );
    if (name != null &&
        name.trim().isNotEmpty &&
        name != profile?.displayName) {
      setState(() => _isSaving = true);
      try {
        await ref
            .read(userProfileProvider.notifier)
            .updateProfile(displayName: name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nama berhasil diperbarui.')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final regionsAsync = ref.watch(regionsListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppHeader(showBackButton: context.canPop()),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.canvasBlue,
              child: Text(
                (user?.email != null && user!.email!.isNotEmpty)
                    ? user.email![0].toUpperCase()
                    : 'U',
                style: AppTextStyles.displayEmphasis.copyWith(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          profileAsync.when(
            data: (p) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      p?.displayName ?? 'Pengguna',
                      style: AppTextStyles.screenTitle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _editDisplayName(p),
                    ),
                  ],
                ),
                Text(
                  user?.email ?? 'Belum masuk akun',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Text('Gagal memuat profil', style: AppTextStyles.caption),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Text('Wilayah Default Siaga', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Digunakan untuk memfilter informasi bencana dan feed komunitas lokal Anda.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.base),
          regionsAsync.when(
            data: (regions) {
              final p = profileAsync.asData?.value;
              final selectedName =
                  regions.where((r) => r.id == p?.regionId).firstOrNull?.name ??
                  p?.regionName ??
                  'Belum memilih wilayah';
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.chartBlue,
                ),
                title: Text(selectedName, style: AppTextStyles.label),
                trailing: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right_rounded),
                onTap: user != null ? () => _changeRegion(regions, p) : null,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Gagal memuat wilayah: $e', style: AppTextStyles.caption),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Keselamatan Keluarga', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Kelola kontak darurat keluarga Anda dan lakukan check-in keselamatan bencana.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.base),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: const BorderSide(color: AppColors.border),
            ),
            leading: const Icon(
              Icons.family_restroom_rounded,
              color: AppColors.chartGreen,
            ),
            title: Text(
              'Kerabat Siaga & Family Check-in',
              style: AppTextStyles.label,
            ),
            subtitle: const Text(
              'Kontak Darurat, Status Keselamatan & Hotline',
              style: TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.family),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (user == null)
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Masuk / Daftar Akun'),
            )
          else
            OutlinedButton(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                ref.invalidate(userProfileProvider);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.chartRed,
                side: const BorderSide(color: AppColors.chartRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Keluar dari Akun'),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3,
        onTap: _onNavTap,
      ),
    );
  }
}
