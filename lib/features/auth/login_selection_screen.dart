// ── LoginSelectionScreen ─────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _screenBackground = Color(0xFFFBFDFF);
const _softBlue = Color(0xFFEAF4FF);
const _primaryBlue = Color(0xFF2F80FF);
const _textNavy = Color(0xFF101C3D);
const _mutedBlue = Color(0xFF8093C6);
const _dividerBlue = Color(0xFFE9EEF8);

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo container with soft blue background
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _softBlue,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _primaryBlue.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 56,
                    color: _primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'SGU UKM Connect',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _textNavy,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'SGU Club Activity Management',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _mutedBlue,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 64),

              // Student button — white with blue border
              _OutlinedGlassButton(
                onPressed: () => context.go('/signin/student'),
                icon: Icons.person_rounded,
                label: 'Sign In as Student',
              ),
              const SizedBox(height: 14),

              // BEM button — white with blue border (same style)
              _OutlinedGlassButton(
                onPressed: () => context.go('/signin/bem'),
                icon: Icons.admin_panel_settings_rounded,
                label: 'Sign In as BEM',
              ),
              const SizedBox(height: 32),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 13,
                      color: _mutedBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Outlined Glass Button (white/transparent with blue border) ─────────────
class _OutlinedGlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _OutlinedGlassButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryBlue.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: _primaryBlue, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}