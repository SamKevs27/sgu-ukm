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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = authState.isLoading || currentUser.isLoading;
      if (isLoading) return null;

      final user = currentUser.valueOrNull;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signin') ||
          state.matchedLocation.startsWith('/signup');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) {
        return user.role == UserRole.bem ? '/bem' : '/student';
      }
      return null;
    },
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