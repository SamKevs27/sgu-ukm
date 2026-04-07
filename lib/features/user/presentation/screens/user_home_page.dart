import 'package:flutter/material.dart';

import '../../../../state/app_state.dart';
import '../../../../utils/date_format.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key, required this.username});

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
              Text('Welcome, $username', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Latest club feeds', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF637194))),
              const SizedBox(height: 12),
              ...app.feeds.map(
                (feed) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDE8FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.campaign, size: 18, color: Color(0xFF2454D5)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(app.clubName(feed.clubId), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(feed.content, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 10),
                        Text(
                          'By ${feed.author} • ${formatDate(feed.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6E7897)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}
