import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/family_providers.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../models/emergency_contact.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Modal dialog to create or edit an emergency contact.
class AddContactDialog extends ConsumerStatefulWidget {
  const AddContactDialog({super.key, this.contactToEdit});

  final EmergencyContact? contactToEdit;

  static Future<bool?> show(
    BuildContext context, {
    EmergencyContact? contactToEdit,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AddContactDialog(contactToEdit: contactToEdit),
    );
  }

  @override
  ConsumerState<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends ConsumerState<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late String _relationship;
  late bool _isTrusted;
  bool _isLoading = false;

  bool get _isEditing => widget.contactToEdit != null;

  static const _relationships = [
    'Orang Tua',
    'Pasangan',
    'Anak',
    'Saudara Kandung',
    'Keluarga Besar',
    'Tetangga / RT',
    'Rekan Kerja',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.contactToEdit;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phoneNumber ?? '');
    _relationship = c?.relationship ?? 'Keluarga';
    if (!_relationships.contains(_relationship)) {
      _relationship = 'Keluarga Besar';
    }
    _isTrusted = c?.isTrusted ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(familyServiceProvider);
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? 'guest_user';

      if (_isEditing) {
        final updated = widget.contactToEdit!.copyWith(
          name: _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          relationship: _relationship,
          isTrusted: _isTrusted,
        );
        await service.updateContact(updated);
      } else {
        await service.addContact(
          userId: userId,
          name: _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          relationship: _relationship,
          isTrusted: _isTrusted,
        );
      }

      ref.invalidate(emergencyContactsProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
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
        constraints: const BoxConstraints(maxWidth: 480),
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
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.chartBlue,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Ubah Kontak Kerabat'
                            : 'Tambah Kerabat Siaga',
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
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap / Panggilan *',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP / WhatsApp *',
                    hintText: 'Contoh: 081234567890',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().length < 8
                      ? 'Nomor telepon tidak valid'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _relationship,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Hubungan Keluarga *',
                  ),
                  items: _relationships
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _relationship = val);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isTrusted,
                  title: const Text(
                    'Kerabat Siaga Utama (SOS)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Menerima notifikasi darurat saat Anda mengaktifkan SOS privat.',
                    style: TextStyle(fontSize: 11),
                  ),
                  onChanged: (v) => setState(() => _isTrusted = v ?? false),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
