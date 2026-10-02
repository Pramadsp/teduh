import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teduh/core/theme/app_colors.dart';
import 'package:teduh/features/auth/data/auth_service.dart';
import 'package:teduh/features/auth/presentation/providers/pin_lock_provider.dart';

class UserActivityDetector extends ConsumerStatefulWidget {
  final Widget child;
  final Duration timeoutDuration;

  const UserActivityDetector({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(hours: 24),
  });

  @override
  ConsumerState<UserActivityDetector> createState() => _UserActivityDetectorState();
}

class _UserActivityDetectorState extends ConsumerState<UserActivityDetector> with WidgetsBindingObserver {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Saat aplikasi di-minimize/ditinggal ke background, kunci aplikasi kembali dengan PIN Gate
      ref.read(pinLockProvider.notifier).lock();
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();

    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      _inactivityTimer = Timer(widget.timeoutDuration, _onInactivityTimeout);
    }
  }

  void _onInactivityTimeout() async {
    final currentUser = AuthService().currentUser;
    if (currentUser != null && mounted) {
      ref.read(pinLockProvider.notifier).lock();
      await AuthService().logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi 24 jam Anda telah berakhir. Silakan masuk kembali.'),
            backgroundColor: AppColors.expense,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      onPointerUp: (_) => _resetInactivityTimer(),
      child: widget.child,
    );
  }
}
