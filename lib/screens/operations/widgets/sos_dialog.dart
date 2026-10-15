import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Result data from the SOS confirmation dialog.
class SosDialogResult {
  const SosDialogResult({required this.mode, this.note});

  final String mode;
  final String? note;
}

/// Modal dialog allowing the user to select SOS broadcast mode and optional note.
class SosConfirmationDialog extends StatefulWidget {
  const SosConfirmationDialog({super.key, required this.location});

  final LatLng location;

  static Future<SosDialogResult?> show(
    BuildContext context, {
    required LatLng location,
  }) {
    return showDialog<SosDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SosConfirmationDialog(location: location),
    );
  }

  @override
  State<SosConfirmationDialog> createState() => _SosConfirmationDialogState();
}

class _SosConfirmationDialogState extends State<SosConfirmationDialog> {
  String _mode = 'PUBLIC';
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildModeOption({required String mode, required String label}) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.chartRed : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.chartRed),
          const SizedBox(width: AppSpacing.sm),
          Text('Konfirmasi Bantuan Darurat', style: AppTextStyles.sectionTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.chartGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: AppColors.chartGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  size: 15,
                  color: AppColors.chartGreen,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'GPS Terkunci: ${widget.location.latitude.toStringAsFixed(4)}, ${widget.location.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.chartGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Pilih mode penyebaran sinyal darurat:',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildModeOption(
            mode: 'PUBLIC',
            label: 'Publik (Relawan & Posko Sekitar)',
          ),
          _buildModeOption(
            mode: 'PRIVATE',
            label: 'Privat (Hanya Kontak Tepercaya)',
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _noteController,
            maxLength: 250,
            decoration: const InputDecoration(
              hintText: 'Kondisi darurat singkat (cth: Terjebak air naik)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final trimmedNote = _noteController.text.trim();
            Navigator.pop(
              context,
              SosDialogResult(
                mode: _mode,
                note: trimmedNote.isEmpty ? null : trimmedNote,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.chartRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: const Text(
            'AKTIFKAN SOS',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
