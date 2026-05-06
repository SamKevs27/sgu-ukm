// lib/providers/auth_provider.dart
import 'package:campus_club/models/user_model.dart';
import 'package:campus_club/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Raw Firebase auth state
final firebaseAuthProvider = StreamProvider<User?>((ref) {
  return AuthService().authStateChanges;
});

// The resolved UserModel (null = not logged in)
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(firebaseAuthProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;
  return AuthService().getUserProfile(user.uid);
});

// Convenience: is the current user BEM?
final isBemProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role == UserRole.bem;
});

// The AuthService instance
final authServiceProvider = Provider<AuthService>((ref) => AuthService());