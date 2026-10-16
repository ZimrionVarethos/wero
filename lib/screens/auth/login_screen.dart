import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/supabase_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';

/// Screen for user login and registration via Supabase Auth.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _fillDemoAccount() {
    _emailController.text = 'siagaku.admin@gmail.com';
    _passwordController.text = 'PasswordSiagaku123!';
    _submit();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        final res = await authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text.isNotEmpty
              ? _nameController.text
              : 'Warga Siaga',
        );
        if (res?.session == null && mounted) {
          setState(() {
            _errorMessage = 'Akun terdaftar. Silakan verifikasi email.';
            _isSignUp = false;
          });
          return;
        }
      } else {
        await authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (mounted) {
        ref.invalidate(currentUserProvider);
        ref.invalidate(userProfileProvider);
        context.go('/activity');
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand logo di atas form card (menggantikan header)
                const AppLogo(height: 52),
                const SizedBox(height: AppSpacing.xl),
                // Card form autentikasi
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.borderNeutral.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isSignUp ? 'Daftar Akun Baru' : 'Masuk ke Siagaku',
                          style: AppTextStyles.screenTitle.copyWith(
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _isSignUp
                              ? 'Daftar untuk mengakses mitigasi & komunitas bencana'
                              : 'Gunakan akun Anda untuk berpartisipasi dan melapor',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.softRed,
                              borderRadius: BorderRadius.circular(
                                AppRadius.iconTile,
                              ),
                              border: Border.all(
                                color: AppColors.awas.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.awas,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.base),
                        ],
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration(
                              label: 'Nama Lengkap',
                              icon: Icons.person_outline_rounded,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nama tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.base),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            label: 'Email',
                            icon: Icons.email_outlined,
                          ),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Masukkan email yang valid'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.base),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration(
                            label: 'Kata Sandi',
                            icon: Icons.lock_outline_rounded,
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Kata sandi minimal 6 karakter'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentOrange,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isSignUp ? 'Daftar Sekarang' : 'Masuk',
                                    style: AppTextStyles.label.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        if (!_isSignUp) ...[
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _fillDemoAccount,
                            icon: const Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: AppColors.accentOrange,
                            ),
                            label: const Text('Masuk Cepat (Akun Demo)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryNavy,
                              side: const BorderSide(
                                color: AppColors.borderNeutral,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.base),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                              _errorMessage = null;
                            });
                          },
                          child: Text(
                            _isSignUp
                                ? 'Sudah punya akun? Masuk'
                                : 'Belum punya akun? Daftar sekarang',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryNavy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppColors.primaryNavy),
      filled: true,
      fillColor: AppColors.backgroundCream.withValues(alpha: 0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.borderNeutral),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.borderNeutral),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
      ),
    );
  }
}
