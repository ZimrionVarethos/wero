import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';

/// Form inputs for adding or editing an evacuation facility.
class AdminFacilityFormFields extends StatelessWidget {
  const AdminFacilityFormFields({
    super.key,
    required this.nameCtrl,
    required this.addressCtrl,
    required this.capacityCtrl,
    required this.latCtrl,
    required this.lngCtrl,
    required this.descCtrl,
    required this.selectedKind,
    required this.onKindChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController capacityCtrl;
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;
  final TextEditingController descCtrl;
  final String selectedKind;
  final ValueChanged<String> onKindChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        TextFormField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Posko / Fasilitas *',
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: selectedKind,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Kategori Fasilitas *'),
          items: const [
            DropdownMenuItem(
              value: 'SHELTER',
              child: Text('Shelter / Tempat Pengungsian'),
            ),
            DropdownMenuItem(
              value: 'HEALTH',
              child: Text('Kesehatan / Rumah Sakit / Puskesmas'),
            ),
            DropdownMenuItem(
              value: 'ASSEMBLY',
              child: Text('Titik Kumpul Darurat'),
            ),
          ],
          onChanged: (val) {
            if (val != null) onKindChanged(val);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: addressCtrl,
          decoration: const InputDecoration(labelText: 'Alamat Lengkap *'),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Alamat wajib diisi' : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: latCtrl,
                decoration: const InputDecoration(labelText: 'Latitude *'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Format invalid' : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: lngCtrl,
                decoration: const InputDecoration(labelText: 'Longitude *'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Format invalid' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: capacityCtrl,
          decoration: const InputDecoration(labelText: 'Kapasitas (Jiwa)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: descCtrl,
          decoration: const InputDecoration(
            labelText: 'Keterangan Tambahan / Logistik',
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
