import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/slip/presentation/pages/slip_import_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/swipe/presentation/pages/swipe_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen auth state changes → router จะ refresh อัตโนมัติเมื่อ login/logout
  final notifier = ValueNotifier<bool>(
    ref.read(authServiceProvider).currentUser != null,
  );
  ref.listen(authStateProvider, (_, next) {
    next.whenData((state) {
      notifier.value = state.session != null;
    });
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authServiceProvider).currentUser != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
      GoRoute(path: '/slip-import', builder: (_, __) => const SlipImportPage()),
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
      GoRoute(path: '/swipe', builder: (_, __) => const SwipePage()),
    ],
  );
});
