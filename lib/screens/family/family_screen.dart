import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/family_providers.dart';
import '../../models/emergency_contact.dart';
import '../../models/family_checkin.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/add_contact_dialog.dart';
import 'widgets/checkin_action_sheet.dart';
import 'widgets/contact_card.dart';
import 'widgets/family_checkin_card.dart';
import 'widgets/family_hotlines_tab.dart';
import '../../utils/phone_launcher.dart';

/// Screen managing emergency contacts, family safety check-ins, and national hotlines.
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  static const routeName = '/family';

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFeedback(String action, String target) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action ke $target...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(emergencyContactsProvider);
    final checkinsAsync = ref.watch(familyCheckinsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBlue,
      appBar: AppBar(
        title: Text(
          'Kerabat Siaga & Check-in',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.chartBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.chartBlue,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Kerabat Siaga'),
            Tab(text: 'Check-in'),
            Tab(text: 'Hotline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          contactsAsync.when(
            data: _buildContactsTab,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Gagal: $e')),
          ),
          checkinsAsync.when(
            data: _buildCheckinsTab,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Gagal: $e')),
          ),
          FamilyHotlinesTab(
            onCallHotline: (phone) => PhoneLauncher.launchPhone(
              context,
              phone,
              label: 'Hotline Darurat',
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => AddContactDialog.show(context),
              backgroundColor: AppColors.chartBlue,
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: const Text(
                'Tambah Kerabat',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildContactsTab(List<EmergencyContact> contacts) {
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.contacts_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Belum ada Kerabat Siaga', style: AppTextStyles.sectionTitle),
            Text(
              'Tambahkan kontak darurat keluarga Anda.',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: contacts.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final c = contacts[i];
        return ContactCard(
          contact: c,
          onEdit: () => AddContactDialog.show(context, contactToEdit: c),
          onDelete: () => _confirmDelete(c),
          onCall: () =>
              PhoneLauncher.launchPhone(context, c.phoneNumber, label: c.name),
          onWhatsApp: () =>
              PhoneLauncher.launchWhatsApp(context, c.phoneNumber),
        );
      },
    );
  }

  Widget _buildCheckinsTab(List<FamilyCheckin> checkins) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Status Keselamatan Anda',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 4),
              Text(
                'Perbarui kondisi Anda dengan 1-klik agar keluarga mengetahui keadaan Anda saat bencana.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () => CheckinActionSheet.show(context),
                icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                label: const Text(
                  'Perbarui Status Keselamatan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chartGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        Text(
          'Pembaruan Keselamatan Terkini',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...checkins.map(
          (chk) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: FamilyCheckinCard(
              checkin: chk,
              onShare: () => _showFeedback('Membagikan status', chk.userName),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(EmergencyContact contact) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kerabat Siaga?'),
        content: Text('Hapus "${contact.name}" dari kontak darurat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chartRed,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(familyServiceProvider).deleteContact(contact.id);
      ref.invalidate(emergencyContactsProvider);
    }
  }
}
