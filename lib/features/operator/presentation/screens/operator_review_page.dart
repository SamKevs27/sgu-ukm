import 'package:flutter/material.dart';

import '../../../../models/app_models.dart';
import '../../../../state/app_state.dart';

class OperatorReviewPage extends StatelessWidget {
  const OperatorReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final pending = app.joinRequests.where((request) => app.operatorClubIds.contains(request.clubId)).toList();
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7FAFF), Color(0xFFF0F4FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Student Join Requests', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (pending.isEmpty)
                const Card(child: ListTile(title: Text('No pending requests right now.')))
              else
                ...pending.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        title: Text(request.studentName),
                        subtitle: Text(app.clubName(request.clubId)),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              onPressed: () => app.updateRequestStatus(request.id, ApplicationStatus.approved),
                              icon: const Icon(Icons.check_circle, color: Color(0xFF29B271)),
                            ),
                            IconButton(
                              onPressed: () => app.updateRequestStatus(request.id, ApplicationStatus.rejected),
                              icon: const Icon(Icons.cancel, color: Color(0xFFD74D67)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
