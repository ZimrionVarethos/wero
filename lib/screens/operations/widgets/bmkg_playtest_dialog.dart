import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/bmkg_providers.dart';
import '../../../../routing/app_router.dart';
import '../../../../services/alarm_sound_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import 'playtest_scenario_card.dart';

/// Modal dialog for playtesting BMKG disaster alerts with real audio siren and vibration.
class BmkgPlaytestDialog extends ConsumerStatefulWidget {
  const BmkgPlaytestDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BmkgPlaytestDialog(),
    );
  }

  @override
  ConsumerState<BmkgPlaytestDialog> createState() => _BmkgPlaytestDialogState();
}

class _BmkgPlaytestDialogState extends ConsumerState<BmkgPlaytestDialog> {
  bool _isPlaying = false;
  int _selectedScenario = 0; // 0: Tsunami AWAS (M7.4), 1: Gempa Darat (M6.2)

  final _scenarios = [
    {
      'title': 'Gempa Megathrust M 7.4',
      'level': 'AWAS TSUNAMI',
      'color': AppColors.chartRed,
      'location': 'Pesisir Selatan Jawa (Kedalaman 10 km)',
      'action': 'Segera jauhi pantai dan evakuasi ke tempat tinggi!',
    },
    {
      'title': 'Gempa Darat Sesar Aktif M 6.2',
      'level': 'WASPADA GEMPA KUAT',
      'color': AppColors.accentOrange,
      'location': 'Daratan Sesar Opak (Kedalaman 8 km)',
      'action': 'Lindungi kepala, jauhi kaca dan tiang, cari lapangan terbuka!',
    },
  ];

  late final AlarmSoundService _alarmService;

  @override
  void initState() {
    super.initState();
    _alarmService = ref.read(alarmSoundServiceProvider);
  }

  @override
  void dispose() {
    _alarmService.stopEmergencyAlarm();
    super.dispose();
  }

  Future<void> _toggleAlarm() async {
    if (_isPlaying) {
      await _alarmService.stopEmergencyAlarm();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      await _alarmService.startEmergencyAlarm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenarios[_selectedScenario];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulasi Peringatan BMKG',
                        style: AppTextStyles.screenTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Uji coba sirine alarm darurat & getaran HP',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                _buildLiveBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildScenarioChips(),
            const SizedBox(height: AppSpacing.md),
            PlaytestScenarioCard(scenario: scenario),
            const SizedBox(height: AppSpacing.base),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chartGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.chartGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.chartGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'BMKG LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.chartGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioChips() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: List.generate(_scenarios.length, (idx) {
        final isSelected = _selectedScenario == idx;
        return ChoiceChip(
          label: Text(
            idx == 0 ? 'Skenario Tsunami' : 'Skenario Gempa Darat',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (val) {
            if (val) setState(() => _selectedScenario = idx);
          },
        );
      }),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _toggleAlarm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPlaying
                  ? AppColors.textPrimary
                  : AppColors.chartRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            icon: Icon(
              _isPlaying ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
            ),
            label: Text(
              _isPlaying
                  ? 'HENTIKAN SIRINE (STOP ALARM)'
                  : 'BUNYIKAN SIRINE & NOTIFIKASI',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.evacuation);
            },
            icon: const Icon(Icons.near_me_outlined, size: 18),
            label: const Text('Buka Peta Jalur Evakuasi'),
          ),
        ),
      ],
    );
  }
}
