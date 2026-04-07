import 'package:flutter/material.dart';

import '../../../../state/app_state.dart';
import '../../../../utils/iterable_extensions.dart';
import '../widgets/request_status_chip.dart';

class UserClubsPage extends StatelessWidget {
  const UserClubsPage({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8FAFF), Color(0xFFF0F5FF), Color(0xFFF7F9FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomInset),
              children: [
              Text('Available Clubs', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ...app.clubs.map((club) {
                final request = app.joinRequests.where((req) => req.studentName == username && req.clubId == club.id).firstOrNull;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6EEFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.groups_2, color: Color(0xFF2454D5)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(club.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(club.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6F7A99))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          request == null
                              ? FilledButton(
                                  onPressed: () => app.applyToClub(studentName: username, clubId: club.id),
                                  child: const Text('Apply'),
                                )
                              : RequestStatusChip(status: request.status),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              ],
            ),
          ),
        );
      },
    );
  }
}
