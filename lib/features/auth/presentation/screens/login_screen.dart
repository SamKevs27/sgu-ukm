import 'package:flutter/material.dart';

import '../../../../models/app_models.dart';

const _screenBackground = Color(0xFFF2F2F5);
const _fieldBackground = Color(0xFFDCE5EF);
const _primaryBlue = Color(0xFF1EA6DC);
const _deepBlue = Color(0xFF2E49A8);
const _textDark = Color(0xFF20242D);
const _textMuted = Color(0xFF808185);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final void Function(UserRole role, String username) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.user;
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.08),
                        const _SguWordmark(),
                        const SizedBox(height: 86),
                        Text(
                          'SGU Email',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: _textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            hintText: 'samuel.laluyan@student.sgu.ac.id',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: _textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Username is required'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Password',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: _textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _inputDecoration(
                            hintText: 'Enter your password',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _textMuted,
                              ),
                            ),
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: _textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Password is required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value ?? false),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              side: const BorderSide(color: _textMuted, width: 1.5),
                              activeColor: _screenBackground,
                              checkColor: _textDark,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Remember me',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: _textDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: _primaryBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: _primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        DropdownButtonFormField<UserRole>(
                          initialValue: _role,
                          decoration: _inputDecoration(
                            hintText: 'Login as',
                          ),
                          dropdownColor: _surfaceForDropdown,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: _textDark,
                            fontWeight: FontWeight.w600,
                          ),
                          items: UserRole.values
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.name.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _role = value);
                          },
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          height: 58,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              textStyle: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w400,
                                fontSize: 42,
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState?.validate() != true) {
                                return;
                              }
                              widget.onLogin(_role, _usernameController.text.trim());
                            },
                            child: const Text('Log In'),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.16),
                        Text(
                          'v2.3.1',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: _textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: _textMuted,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: _fieldBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      errorBorder: border,
      focusedErrorBorder: border,
      suffixIcon: suffixIcon,
    );
  }
}

const _surfaceForDropdown = Color(0xFFEAF0F7);

class _SguWordmark extends StatelessWidget {
  const _SguWordmark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          children: const [
            TextSpan(
              text: 'SG',
              style: TextStyle(
                color: _primaryBlue,
                fontSize: 88,
                fontWeight: FontWeight.w800,
                letterSpacing: -3,
              ),
            ),
            TextSpan(
              text: 'U',
              style: TextStyle(
                color: _deepBlue,
                fontSize: 88,
                fontWeight: FontWeight.w800,
                letterSpacing: -4,
              ),
            ),
            TextSpan(
              text: '  ',
              style: TextStyle(fontSize: 88),
            ),
            TextSpan(
              text: '®',
              style: TextStyle(
                color: _textMuted,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
