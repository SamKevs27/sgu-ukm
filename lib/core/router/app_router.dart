// lib/core/router/app_router.dart
import 'package:campus_club/features/auth/login_selection_screen.dart';
import 'package:campus_club/features/auth/signin_screen.dart';
import 'package:campus_club/features/auth/signup_screen.dart';
import 'package:campus_club/features/bem/bem_shell.dart';
import 'package:campus_club/features/student/student_shell.dart';
import 'package:campus_club/models/user_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── RouterNotifier ────────────────────────────────────────────────────────────
// Extends ChangeNotifier so GoRouter can listen to it via refreshListenable.
// Every time auth state or the resolved user changes, it calls notifyListeners()
// which forces GoRouter to re-run its redirect callback.

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    // Watch both providers and notify router whenever either changes
    _ref.listen(firebaseAuthProvider, (_, __) => notifyListeners());
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(firebaseAuthProvider);
    final currentUser = _ref.read(currentUserProvider);

    // Still loading — stay put, don't redirect yet
    final isLoading = authState.isLoading || currentUser.isLoading;
    if (isLoading) return null;

    final user = currentUser.valueOrNull;
    final isLoggedIn = user != null;

    final loc = state.matchedLocation;
    final isAuthRoute = loc.startsWith('/login') ||
        loc.startsWith('/signin') ||
        loc.startsWith('/signup');

    // Not logged in and trying to access a protected route → go to login
    if (!isLoggedIn && !isAuthRoute) return '/login';

    // Logged in and still on an auth route → go to the right shell
    if (isLoggedIn && isAuthRoute) {
      return user.role == UserRole.bem ? '/bem' : '/student';
    }

    // Logged in but on the wrong shell (e.g. student somehow hits /bem)
    if (isLoggedIn && !isAuthRoute) {
      if (user.role == UserRole.bem && !loc.startsWith('/bem')) return '/bem';
      if (user.role == UserRole.student && !loc.startsWith('/student')) {
        return '/student';
      }
    }

    return null;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,   // ← this is what was missing
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginSelectionScreen(),
      ),
      GoRoute(
        path: '/signin/:role',
        builder: (_, state) =>
            SignInScreen(role: state.pathParameters['role'] ?? 'student'),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (_, __) => const StudentShell(),
      ),
      GoRoute(
        path: '/bem',
        builder: (_, __) => const BemShell(),
      ),
    ],
  );
});