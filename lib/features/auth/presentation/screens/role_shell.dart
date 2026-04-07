import 'package:flutter/material.dart';

import '../../../../models/app_models.dart';
import '../../../admin/presentation/screens/admin_bod_page.dart';
import '../../../admin/presentation/screens/admin_clubs_page.dart';
import '../../../operator/presentation/screens/operator_post_feed_page.dart';
import '../../../operator/presentation/screens/operator_review_page.dart';
import '../../../user/presentation/screens/user_clubs_page.dart';
import '../../../user/presentation/screens/user_home_page.dart';
import '../../../user/presentation/screens/user_stats_page.dart';

class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.role, required this.username, required this.onLogout});

  final UserRole role;
  final String username;
  final VoidCallback onLogout;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final destinations = _buildDestinations();
    final isUser = widget.role == UserRole.user;

    if (index >= pages.length) {
      index = 0;
    }

    return Scaffold(
      appBar: isUser
          ? null
          : AppBar(
              title: Text('SGU UKM - ${widget.role.name.toUpperCase()}'),
              actions: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE7FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(widget.username, style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout, color: Color(0xFF0A2C82))),
              ],
            ),
      body: pages[index],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: destinations,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPages() {
    switch (widget.role) {
      case UserRole.admin:
        return [const AdminClubsPage(), const AdminBodPage()];
      case UserRole.operator:
        return [const OperatorReviewPage(), OperatorPostFeedPage(username: widget.username)];
      case UserRole.user:
        return [UserHomePage(username: widget.username), UserClubsPage(username: widget.username), UserStatsPage(username: widget.username)];
    }
  }

  List<NavigationDestination> _buildDestinations() {
    switch (widget.role) {
      case UserRole.admin:
        return const [
          NavigationDestination(icon: Icon(Icons.groups), label: 'Clubs'),
          NavigationDestination(icon: Icon(Icons.badge), label: 'BoD'),
        ];
      case UserRole.operator:
        return const [
          NavigationDestination(icon: Icon(Icons.assignment_turned_in), label: 'Applications'),
          NavigationDestination(icon: Icon(Icons.feed), label: 'Post Feed'),
        ];
      case UserRole.user:
        return const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.apartment), label: 'Clubs'),
          NavigationDestination(icon: Icon(Icons.groups_rounded), label: 'Profile'),
        ];
    }
  }
}
