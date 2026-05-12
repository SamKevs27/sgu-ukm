import 'package:campus_club/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _screenBackground = Color(0xFFFBFDFF);
const _softBlue = Color(0xFFEAF4FF);
const _primaryBlue = Color(0xFF2F80FF);
const _textNavy = Color(0xFF101C3D);
const _mutedBlue = Color(0xFF8093C6);
const _dividerBlue = Color(0xFFE9EEF8);

class ProfilePopup extends ConsumerWidget {
  const ProfilePopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Container(
      decoration: const BoxDecoration(
        color: _screenBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: userAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _primaryBlue),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          data: (user) {
            if (user == null) return const SizedBox();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _dividerBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryBlue.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: _softBlue,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _primaryBlue,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Name
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textNavy,
                  ),
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _mutedBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // NIM Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _primaryBlue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 14,
                        color: _primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'NIM: ${user.nim}',
                        style: const TextStyle(
                          color: _primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Sign Out Button — outlined style matching dashboard aesthetic
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      width: 1,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFEF4444).withValues(alpha: 0.08),
                        const Color(0xFFEF4444).withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go('/login');
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Sign Out',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}