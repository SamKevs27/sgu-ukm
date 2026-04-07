import 'package:flutter/material.dart';

import '../../../../state/app_state.dart';

class OperatorPostFeedPage extends StatefulWidget {
  const OperatorPostFeedPage({super.key, required this.username});

  final String username;

  @override
  State<OperatorPostFeedPage> createState() => _OperatorPostFeedPageState();
}

class _OperatorPostFeedPageState extends State<OperatorPostFeedPage> {
  String? selectedClubId;
  final postController = TextEditingController();

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final operatorClubs = app.clubs.where((club) => app.operatorClubIds.contains(club.id)).toList();

    if (operatorClubs.isNotEmpty && (selectedClubId == null || !operatorClubs.any((club) => club.id == selectedClubId))) {
      selectedClubId = operatorClubs.first.id;
    }

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
          Text('Post Feed Update', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (operatorClubs.isEmpty)
            const Card(child: ListTile(title: Text('You are not assigned to any clubs yet.')))
          else ...[
            DropdownButtonFormField<String>(
              initialValue: selectedClubId,
              decoration: const InputDecoration(labelText: 'Club'),
              items: operatorClubs
                  .map(
                    (club) => DropdownMenuItem<String>(
                      value: club.id,
                      child: Text(club.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedClubId = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: postController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'What is new in your club?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                final content = postController.text.trim();
                if (content.isEmpty || selectedClubId == null) {
                  return;
                }
                app.postFeed(
                  clubId: selectedClubId!,
                  author: widget.username,
                  content: content,
                );
                postController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feed posted.')));
              },
              icon: const Icon(Icons.send),
              label: const Text('Publish'),
            ),
          ],
        ],
      ),
    );
  }
}
