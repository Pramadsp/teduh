import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/widgets/auth_gate.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/reports/presentation/screens/report_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/transactions/presentation/screens/transaction_list_screen.dart';
import 'shell_scaffold.dart';

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
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionListScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
