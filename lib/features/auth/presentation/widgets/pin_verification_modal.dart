import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/user_profile.dart';

class PinVerificationModal extends ConsumerStatefulWidget {
  final String currentUid;

  const PinVerificationModal({super.key, required this.currentUid});

  static Future<bool?> show(BuildContext context, {required String currentUid}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PinVerificationModal(currentUid: currentUid),
    );
  }

  @override
  ConsumerState<PinVerificationModal> createState() => _PinVerificationModalState();
}

class _PinVerificationModalState extends ConsumerState<PinVerificationModal> {
  String _inputPin = '';
  bool _isLoading = false;
  String? _errorMessage;

  void _onKeyPress(String val, String correctPin) {
    if (_inputPin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _errorMessage = null;
        _inputPin += val;
      });

      if (_inputPin.length == 6) {
        _verifyPin(correctPin);
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

  void _verifyPin(String correctPin) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 150));

    if (_inputPin == correctPin) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      HapticFeedback.vibrate();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'PIN salah, silakan coba lagi';
          _inputPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.currentUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: AppColors.sageDark)),
          );
        }

        final profile = UserProfile.fromMap(snapshot.data!.data()!);
        final userPin = profile.pin ?? '';

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.sageDark.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sageDark.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded, size: 32, color: AppColors.sageDark),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Verifikasi PIN Transfer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Masukkan 6-digit PIN keamanan Anda untuk mengotorisasi transfer saldo ini.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ink.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 6 Circular Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < _inputPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
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

                const SizedBox(height: 12),
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
                  const Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.sageDark,
                        strokeWidth: 2,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Custom Numpad 3x4
                _buildNumpad(userPin),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumpad(String correctPin) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((digit) => _buildNumpadBtn(digit, correctPin)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((digit) => _buildNumpadBtn(digit, correctPin)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((digit) => _buildNumpadBtn(digit, correctPin)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 60, height: 60),
            _buildNumpadBtn('0', correctPin),
            SizedBox(
              width: 60,
              height: 60,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _onBackspace,
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.sageDark,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadBtn(String val, String correctPin) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Material(
        color: AppColors.sand,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPress(val, correctPin),
          child: Center(
            child: Text(
              val,
              style: const TextStyle(
                fontSize: 22,
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
