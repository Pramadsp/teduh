import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinLockNotifier extends StateNotifier<bool> {
  PinLockNotifier() : super(false); // Default: locked (perlu verifikasi PIN)

  void unlock() {
    state = true;
  }

  void lock() {
    state = false;
  }
}

final pinLockProvider = StateNotifierProvider<PinLockNotifier, bool>((ref) {
  return PinLockNotifier();
});
