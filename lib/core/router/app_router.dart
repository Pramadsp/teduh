import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/transactions/presentation/screens/transaction_list_screen.dart';
import 'shell_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ShellScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Beranda')),
          ),
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionListScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Laporan')),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Pengaturan')),
          ),
        ),
      ],
    ),
  ],
);
