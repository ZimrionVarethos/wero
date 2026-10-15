import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/supabase_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';

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
      backgroundColor: AppColors.canvasBlue,
      appBar: const AppHeader(showBackButton: false, actions: []),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
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
                      _isSignUp ? 'Buat Akun Siagaku' : 'Masuk ke Siagaku',
                      style: AppTextStyles.screenTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _isSignUp
                          ? 'Daftar untuk mengakses komunitas dan mitigasi bencana.'
                          : 'Gunakan akun Anda untuk berpartisipasi dan melapor.',
                      style: AppTextStyles.caption,
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
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.chartRed,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ],
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                          ),
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
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Masukkan email yang valid'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata Sandi',
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                      ),
                      validator: (v) => v == null || v.length < 6
                          ? 'Kata sandi minimal 6 karakter'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: AppColors.surface,
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
                                ),
                              ),
                      ),
                    ),
                    if (!_isSignUp) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _fillDemoAccount,
                        icon: const Icon(Icons.flash_on_rounded, size: 18),
                        label: const Text('Masuk Cepat (Akun Demo)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.chartBlue,
                          side: const BorderSide(color: AppColors.chartBlue),
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
