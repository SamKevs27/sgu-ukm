import 'package:campus_club/features/student/attendance/scan_attendance_screen.dart';
import 'package:campus_club/features/student/clubs/clubs_screen.dart';
import 'package:campus_club/features/student/fyp/fyp_screen.dart';
import 'package:campus_club/features/student/my_clubs/my_clubs_screen.dart';
import 'package:campus_club/features/student/bod/my_club_bod_screen.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/shared/widgets/liquid_glass_nav_bar.dart';
import 'package:campus_club/shared/widgets/profile_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _textNavy = Color(0xFF101C3D);
const _mutedBlue = Color(0xFF8093C6);
const _primaryBlue = Color(0xFF2F80FF);

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _currentIndex = 0;

  final _screens = const [
    ClubsScreen(),
    MyClubsScreen(),
    MyClubBodScreen(),
    FypScreen(),
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
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: userAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (user) => user == null
              ? const SizedBox.shrink()
              : Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.account_circle_rounded),
                      color: _primaryBlue,
                      onPressed: () => _showProfile(context),
                    ),
                    Expanded(
                      child: Text(
                        'Hello, ${user.name.split(' ').first}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _textNavy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan meeting QR',
            color: _primaryBlue,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ScanAttendanceScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
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
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Clubs',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'My Clubs',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'My BoD',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'FYP',
          ),
        ],
      ),
    );
  }
}