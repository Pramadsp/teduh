import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/widgets/auth_gate.dart';
import 'shell_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(
        child: MainScreen(),
      ),
    ),
  ],
);
