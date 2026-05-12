// lib/features/bem/bem_shell.dart
import 'package:campus_club/features/bem/clubs/bem_clubs_screen.dart';
import 'package:campus_club/features/bem/cycles/bem_cycles_screen.dart';
import 'package:campus_club/features/bem/dashboard/bem_dashboard_screen.dart';
import 'package:campus_club/features/bem/requests/bem_requests_screen.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/shared/widgets/liquid_glass_nav_bar.dart';
import 'package:campus_club/shared/widgets/profile_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BemShell extends ConsumerStatefulWidget {
  const BemShell({super.key});

  @override
  ConsumerState<BemShell> createState() => _BemShellState();
}

class _BemShellState extends ConsumerState<BemShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BemDashboardScreen(),
    const BemClubsScreen(),
    const BemRequestsScreen(),
    const BemCyclesScreen(),
  ];

  void _showProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ProfilePopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BEM Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => _showProfile(context),
          ),
        ],
      ),
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: LiquidGlassNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Clubs',
          ),
          NavigationDestination(
            icon: Icon(Icons.approval_outlined),
            selectedIcon: Icon(Icons.approval),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Cycles',
          ),
        ],
      ),
    );
  }
}