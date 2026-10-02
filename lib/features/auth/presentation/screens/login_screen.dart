import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teduh/core/theme/app_colors.dart';
import 'package:teduh/features/auth/data/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegistering) {
        await _authService.registerWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
      } else {
        await _authService.loginWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getIndonesianErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getIndonesianErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan dengan email tersebut.';
      case 'wrong-password':
        return 'Kata sandi yang Anda masukkan salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan email lain.';
      case 'invalid-email':
        return 'Format alamat email tidak valid.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      default:
        return 'Terjadi kesalahan login: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.sageDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.sage,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.park_rounded, size: 40, color: AppColors.cream),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Teduh',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Urusan uang jadi lebih tenang.',
                    style: TextStyle(
                      color: AppColors.sageDark,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.sageDark.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.expense.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.expense.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.expense, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_isRegistering) ...[
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: AppColors.ink),
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap (Suami / Istri)',
                              fillColor: AppColors.cream,
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.ink),
                          decoration: const InputDecoration(
                            labelText: 'Alamat Email',
                            fillColor: AppColors.cream,
                          ),
                          validator: (val) =>
                              val == null || !val.contains('@') ? 'Email tidak valid' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.ink),
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi',
                            fillColor: AppColors.cream,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.sageDark,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (val) =>
                              val == null || val.length < 6 ? 'Kata sandi minimal 6 karakter' : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sageDark,
                            foregroundColor: AppColors.cream,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: AppColors.cream, strokeWidth: 2.5),
                                )
                              : Text(
                                  _isRegistering ? 'Daftar Sekarang' : 'Masuk',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isRegistering = !_isRegistering;
                              _errorMessage = null;
                            });
                          },
                          child: Text(
                            _isRegistering
                                ? 'Sudah punya akun? Masuk di sini'
                                : 'Belum punya akun? Daftar di sini',
                            style: const TextStyle(
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
