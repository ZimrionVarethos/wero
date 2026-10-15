import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// Centralized launcher utility for dialing phone numbers and opening WhatsApp.
abstract final class PhoneLauncher {
  /// Opens the device phone dialer with the given phone number prefilled.
  static Future<void> launchPhone(
    BuildContext context,
    String phoneNumber, {
    String? label,
  }) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor telepon tidak valid.')),
        );
      }
      return;
    }

    final uri = Uri.parse('tel:$clean');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        await _handleFallback(context, clean, label);
      }
    } catch (_) {
      if (context.mounted) {
        await _handleFallback(context, clean, label);
      }
    }
  }

  /// Opens WhatsApp to chat with the specified phone number.
  static Future<void> launchWhatsApp(
    BuildContext context,
    String phoneNumber, {
    String? message,
  }) async {
    var clean = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    }
    final url = message != null
        ? 'https://wa.me/$clean?text=${Uri.encodeComponent(message)}'
        : 'https://wa.me/$clean';
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        await _handleFallback(context, clean, 'WhatsApp');
      }
    } catch (_) {
      if (context.mounted) {
        await _handleFallback(context, clean, 'WhatsApp');
      }
    }
  }

  static Future<void> _handleFallback(
    BuildContext context,
    String cleanNumber,
    String? label,
  ) async {
    await Clipboard.setData(ClipboardData(text: cleanNumber));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${label ?? "Nomor"} ($cleanNumber) disalin ke papan klip.',
          ),
          backgroundColor: AppColors.textPrimary,
          action: SnackBarAction(
            label: 'OK',
            textColor: AppColors.chartBlue,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}
