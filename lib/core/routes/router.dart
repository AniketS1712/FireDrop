import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/core/routes/app_routes.dart';
import 'package:firedrop/core/routes/route_paths.dart';
import 'package:firedrop/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─── Router Notifier ──────────────────────────────────────────────────────────
// A ChangeNotifier that listens to currentUserProvider so that go_router
// refreshes its redirect whenever the user's auth/role changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(currentUserProvider, (_, _) => notifyListeners());
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>(
  (ref) => _RouterNotifier(ref),
);

// ─── Router Provider ──────────────────────────────────────────────────────────
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: RoutePaths.splash,
    refreshListenable: notifier,
    routes: AppRoutes.routes,
    redirect: (context, state) => _redirect(ref, state),
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(state.error?.toString() ?? 'Page not found')),
    ),
  );
});

// ─── Redirect Logic ───────────────────────────────────────────────────────────
String? _redirect(Ref ref, GoRouterState state) {
  final userAsync = ref.read(currentUserProvider);

  // While auth state is loading don't redirect (let splash play)
  if (userAsync.isLoading) return null;

  final user = userAsync.value;
  final isLoggedIn = user != null;
  final path = state.uri.path;

  final isOnSplash = path == RoutePaths.splash;
  final isOnLogin = path == RoutePaths.login;
  final isOnSignup = path == RoutePaths.signup;
  final isOnForgotPassword = path == RoutePaths.forgotPassword;
  final isOnPublic = isOnSplash || isOnLogin || isOnSignup || isOnForgotPassword;

  // ── Not logged in ──────────────────────────────────────────────────────────
  if (!isLoggedIn) {
    // Allow splash/login/signup freely; push everything else to login
    return isOnPublic ? null : RoutePaths.login;
  }

  // ── Logged in ──────────────────────────────────────────────────────────────
  final isOrganizer =
      user.role == UserRole.organizer || user.role == UserRole.admin;

  // Redirect away from public routes to appropriate home
  if (isOnPublic) {
    return isOrganizer ? RoutePaths.organizerDashboard : RoutePaths.home;
  }

  // Prevent players from accessing the organizer dashboard
  if (path == RoutePaths.organizerDashboard && !isOrganizer) {
    return RoutePaths.home;
  }

  // Prevent organizers from accessing the player home
  if (path == RoutePaths.home && isOrganizer) {
    return RoutePaths.organizerDashboard;
  }

  return null; // No redirect needed
}
