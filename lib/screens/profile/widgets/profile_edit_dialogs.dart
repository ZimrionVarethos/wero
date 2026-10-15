import 'package:flutter/material.dart';

import '../../../models/region.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_text_styles.dart';

import 'region_picker_dialog.dart';

/// Modal dialogs for editing profile fields (Region, Display Name).
abstract final class ProfileEditDialogs {
  static Future<String?> pickRegion(
    BuildContext context, {
    required List<Region> regions,
    required UserProfile? profile,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => RegionPickerDialog(
        regions: regions,
        selectedRegionId: profile?.regionId,
      ),
    );
  }

  static Future<String?> editDisplayName(
    BuildContext context, {
    required UserProfile? profile,
  }) {
    final controller = TextEditingController(text: profile?.displayName ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Nama Tampilan', style: AppTextStyles.sectionTitle),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Lengkap'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
