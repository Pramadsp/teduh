import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefKey = 'biometric_enabled';

  // Cek apakah HP mendukung Biometrik (Fingerprint / Face ID)
  static Future<bool> isBiometricSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Cek apakah toggle Biometrik diaktifkan oleh pengguna (default: true jika didukung)
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final supported = await isBiometricSupported();
    if (!supported) return false;
    return prefs.getBool(_prefKey) ?? true;
  }

  // Simpan Status Toggle ON/OFF Biometrik oleh pengguna
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  // Minta Autentikasi Sidik Jari / Face ID OS
  static Future<bool> authenticate({required String localizedReason}) async {
    try {
      final enabled = await isBiometricEnabled();
      if (!enabled) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
