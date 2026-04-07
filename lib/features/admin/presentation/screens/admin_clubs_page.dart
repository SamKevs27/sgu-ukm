import 'package:flutter/material.dart';

import '../../../../models/app_models.dart';
import '../../../../state/app_state.dart';

class AdminClubsPage extends StatelessWidget {
  const AdminClubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
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
              FilledButton.icon(
                onPressed: () => _openClubDialog(context: context, app: app),
                icon: const Icon(Icons.add),
                label: const Text('Add Club'),
              ),
              const SizedBox(height: 12),
              ...app.clubs.map(
                (club) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      title: Text(club.name),
                      subtitle: Text(club.description),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: () => _openClubDialog(context: context, app: app, club: club),
                            icon: const Icon(Icons.edit, color: Color(0xFF2454D5)),
                          ),
                          IconButton(
                            onPressed: () => app.deleteClub(club.id),
                            icon: const Icon(Icons.delete, color: Color(0xFFD13A52)),
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

  Future<void> _openClubDialog({required BuildContext context, required AppState app, Club? club}) async {
    final nameController = TextEditingController(text: club?.name ?? '');
    final descriptionController = TextEditingController(text: club?.description ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(club == null ? 'Create Club' : 'Edit Club'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Club Name')),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              if (name.isEmpty || description.isEmpty) {
                return;
              }
              if (club == null) {
                app.addClub(name, description);
              } else {
                app.updateClub(club.id, name, description);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
