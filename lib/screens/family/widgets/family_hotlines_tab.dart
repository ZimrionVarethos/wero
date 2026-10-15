import 'package:flutter/material.dart';

import '../../../data/emergency_hotlines_data.dart';
import '../../../theme/app_spacing.dart';
import 'emergency_hotline_tile.dart';

/// Tab listing verified Indonesian emergency hotlines.
class FamilyHotlinesTab extends StatelessWidget {
  const FamilyHotlinesTab({super.key, required this.onCallHotline});

  final ValueChanged<String> onCallHotline;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: nationalEmergencyHotlines.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final h = nationalEmergencyHotlines[i];
        return EmergencyHotlineTile(
          hotline: h,
          onCall: () => onCallHotline(h.number),
        );
      },
    );
  }
}
