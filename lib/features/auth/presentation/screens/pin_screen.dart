import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/biometric_service.dart';
import '../../data/auth_service.dart';

enum PinMode { setup, verify }

class PinScreen extends ConsumerStatefulWidget {
  final String uid;
  final PinMode mode;
  final String? expectedPin;
  final VoidCallback? onSuccess;
  final VoidCallback? onVerified;

  const PinScreen({
    super.key,
    required this.uid,
    required this.mode,
    this.expectedPin,
    this.onSuccess,
    this.onVerified,
  });

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _authService = AuthService();
  String _inputPin = '';
  String? _firstPin;
  bool _isConfirmStep = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.mode == PinMode.verify) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerBiometricAuth();
      });
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final authenticated = await BiometricService.authenticate(
      localizedReason: 'Verifikasi sidik jari untuk membuka aplikasi Teduh',
    );
    if (authenticated && mounted) {
      widget.onSuccess?.call();
      widget.onVerified?.call();
      if (widget.onSuccess == null && widget.onVerified == null) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _onKeyPress(String val) {
    if (_inputPin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _errorMessage = null;
        _inputPin += val;
      });

      if (_inputPin.length == 6) {
        _handlePinComplete();
      }
    }
  }

  void _onBackspace() {
    if (_inputPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _errorMessage = null;
        _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      });
    }
  }

  void _handlePinComplete() async {
    if (widget.mode == PinMode.setup) {
      if (!_isConfirmStep) {
        // Step 1 Completed -> Lanjut Step 2 Konfirmasi
        setState(() {
          _firstPin = _inputPin;
          _inputPin = '';
          _isConfirmStep = true;
        });
      } else {
        // Step 2 Completed -> Cocokkan dengan Step 1
        if (_inputPin == _firstPin) {
          setState(() => _isLoading = true);
          try {
            await _authService.setUserPin(uid: widget.uid, pin: _inputPin);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.sageDark,
                  content: Text(
                    'PIN Keamanan Berhasil Dibuat!',
                    style: TextStyle(color: AppColors.cream, fontWeight: FontWeight.bold),
                  ),
                ),
              );
              widget.onSuccess?.call();
            }
          } catch (e) {
            setState(() {
              _errorMessage = 'Gagal menyimpan PIN: $e';
              _isConfirmStep = false;
              _firstPin = null;
              _inputPin = '';
            });
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        } else {
          HapticFeedback.vibrate();
          setState(() {
            _errorMessage = 'PIN tidak cocok, silakan ulangi dari awal';
            _isConfirmStep = false;
            _firstPin = null;
            _inputPin = '';
          });
        }
      }
    } else {
      // Mode Verify
      setState(() => _isLoading = true);
      try {
        final isValid = widget.expectedPin != null
            ? _inputPin == widget.expectedPin
            : await _authService.verifyUserPin(uid: widget.uid, inputPin: _inputPin);

        if (isValid) {
          if (mounted) {
            widget.onSuccess?.call();
            widget.onVerified?.call();
            if (widget.onSuccess == null && widget.onVerified == null) {
              Navigator.of(context).pop(true);
            }
          }
        } else {
          HapticFeedback.vibrate();
          setState(() {
            _errorMessage = 'PIN salah, silakan coba lagi';
            _inputPin = '';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan verifikasi PIN';
          _inputPin = '';
        });
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.mode == PinMode.setup
        ? (_isConfirmStep ? 'Konfirmasi PIN 6-Digit' : 'Buat PIN 6-Digit Rahasia')
        : 'Masukkan PIN Keamanan';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: widget.mode == PinMode.verify
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),
              // Icon Top Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sageDark.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 44,
                  color: AppColors.sageDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                titleText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'PIN digunakan untuk mengamankan dompet dan otorisasi transfer.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.ink.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 6 Circular Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _inputPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.sageDark : AppColors.sand,
                      border: Border.all(
                        color: isFilled
                            ? AppColors.sageDark
                            : AppColors.sageDark.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (_isLoading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.sageDark,
                    strokeWidth: 2,
                  ),
                ),

              const Spacer(),

              // Custom Numpad 3x4
              _buildNumpad(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((digit) => _buildNumpadBtn(digit)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((digit) => _buildNumpadBtn(digit)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((digit) => _buildNumpadBtn(digit)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            widget.mode == PinMode.verify
                ? SizedBox(
                    width: 68,
                    height: 68,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _triggerBiometricAuth,
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppColors.sageDark,
                          size: 28,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: 68, height: 68),
            _buildNumpadBtn('0'),
            SizedBox(
              width: 68,
              height: 68,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _onBackspace,
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.sageDark,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadBtn(String val) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Material(
        color: AppColors.sand,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPress(val),
          child: Center(
            child: Text(
              val,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
