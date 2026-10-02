import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/widgets/auth_gate.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/reports/presentation/screens/report_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/transactions/presentation/screens/transaction_list_screen.dart';
import 'shell_scaffold.dart';

CustomTransitionPage<void> _buildSmoothPageTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AuthGate(
          child: ShellScaffold(child: child),
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => _buildSmoothPageTransition(const DashboardScreen(), state),
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) => _buildSmoothPageTransition(const TransactionListScreen(), state),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) => _buildSmoothPageTransition(const ReportScreen(), state),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _buildSmoothPageTransition(const SettingsScreen(), state),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _buildSmoothPageTransition(const ProfileScreen(), state),
        ),
      ],
    ),
  ],
);
