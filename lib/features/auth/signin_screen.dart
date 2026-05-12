// ── SignInScreen ─────────────────────────────────────────────────────────────
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

class SignInScreen extends ConsumerStatefulWidget {
  final String role; // 'student' or 'bem'
  const SignInScreen({super.key, required this.role});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  bool get isBem => widget.role == 'bem';

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      appBar: AppBar(
        backgroundColor: _screenBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textNavy),
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          isBem ? 'BEM Sign In' : 'Student Sign In',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _textNavy,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Role icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _primaryBlue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isBem
                      ? Icons.admin_panel_settings_rounded
                      : Icons.person_rounded,
                  size: 40,
                  color: _primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Email field — bright and round
            _StyledTextField(
              controller: _emailController,
              label: 'Email',
              prefixIcon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password field — bright and round
            _StyledTextField(
              controller: _passwordController,
              label: 'Password',
              prefixIcon: Icons.lock_rounded,
              obscureText: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: _primaryBlue,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Sign in button — white with blue border
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _primaryBlue.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loading ? null : _signIn,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _primaryBlue,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _primaryBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Styled TextField (bright, round, clean) ────────────────────────────────
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryBlue.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: _textNavy,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: _primaryBlue,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            floatingLabelStyle: const TextStyle(
              color: _primaryBlue,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(prefixIcon, color: _primaryBlue, size: 22),
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }
}