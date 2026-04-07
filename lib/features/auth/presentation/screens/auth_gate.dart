import 'package:flutter/material.dart';

import '../../../../models/app_models.dart';
import '../../../../state/app_state.dart';
import 'login_screen.dart';
import 'role_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AppState _appState = AppState();

  UserRole? role;
  String username = '';

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: _appState,
      child: role == null
          ? LoginScreen(
              onLogin: (selectedRole, user) {
                setState(() {
                  role = selectedRole;
                  username = user;
                });
              },
            )
          : RoleShell(
              role: role!,
              username: username,
              onLogout: () {
                setState(() {
                  role = null;
                  username = '';
                });
              },
            ),
    );
  }
}
