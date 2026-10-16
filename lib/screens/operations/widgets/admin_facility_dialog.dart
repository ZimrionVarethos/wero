import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/operations_providers.dart';
import '../../../models/evacuation_point.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'admin_facility_form_fields.dart';

/// Modal dialog for Admins to Create, Update, or Delete evacuation shelters and points.
class AdminFacilityDialog extends ConsumerStatefulWidget {
  const AdminFacilityDialog({
    super.key,
    this.pointToEdit,
    this.currentLocation,
  });

  final EvacuationPoint? pointToEdit;
  final LatLng? currentLocation;

  static Future<bool?> show(
    BuildContext context, {
    EvacuationPoint? pointToEdit,
    LatLng? currentLocation,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminFacilityDialog(
        pointToEdit: pointToEdit,
        currentLocation: currentLocation,
      ),
    );
  }

  @override
  ConsumerState<AdminFacilityDialog> createState() =>
      _AdminFacilityDialogState();
}

class _AdminFacilityDialogState extends ConsumerState<AdminFacilityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _descCtrl;
  late String _kind;
  bool _isLoading = false;

  bool get _isEditing => widget.pointToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pointToEdit;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _capacityCtrl = TextEditingController(
      text: p?.capacity != null ? '${p!.capacity}' : '',
    );
    _latCtrl = TextEditingController(
      text:
          p?.latitude?.toString() ??
          widget.currentLocation?.latitude.toStringAsFixed(4) ??
          '',
    );
    _lngCtrl = TextEditingController(
      text:
          p?.longitude?.toString() ??
          widget.currentLocation?.longitude.toStringAsFixed(4) ??
          '',
    );
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _kind = p?.kind ?? 'SHELTER';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _capacityCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final s = ref.read(operationsServiceProvider);
      final lat = double.parse(_latCtrl.text.trim());
      final lng = double.parse(_lngCtrl.text.trim());
      final cap = int.tryParse(_capacityCtrl.text.trim());

      if (_isEditing) {
        await s.updateEvacuationPoint(
          id: widget.pointToEdit!.id,
          name: _nameCtrl.text,
          kind: _kind,
          address: _addressCtrl.text,
          latitude: lat,
          longitude: lng,
          capacity: cap,
          description: _descCtrl.text,
        );
      } else {
        await s.createEvacuationPoint(
          name: _nameCtrl.text,
          kind: _kind,
          address: _addressCtrl.text,
          latitude: lat,
          longitude: lng,
          capacity: cap,
          description: _descCtrl.text,
        );
      }
      ref.invalidate(evacuationPointsProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.chartRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Posko?'),
        content: Text('Hapus "${widget.pointToEdit?.name}" secara permanen?'),
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
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(operationsServiceProvider)
          .deleteEvacuationPoint(widget.pointToEdit!.id);
      ref.invalidate(evacuationPointsProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.chartRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.chartBlue,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Kelola Posko (Admin)'
                            : 'Tambah Posko Baru (Admin)',
                        style: AppTextStyles.sectionTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: AdminFacilityFormFields(
                    nameCtrl: _nameCtrl,
                    addressCtrl: _addressCtrl,
                    capacityCtrl: _capacityCtrl,
                    latCtrl: _latCtrl,
                    lngCtrl: _lngCtrl,
                    descCtrl: _descCtrl,
                    selectedKind: _kind,
                    onKindChanged: (kind) => setState(() => _kind = kind),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    if (_isEditing)
                      IconButton(
                        tooltip: 'Hapus Posko',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.chartRed,
                        ),
                        onPressed: _isLoading ? null : _delete,
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.chartBlue,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Simpan' : 'Tambah',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
