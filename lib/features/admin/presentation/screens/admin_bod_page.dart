import 'package:flutter/material.dart';

import '../../../../models/app_models.dart';
import '../../../../state/app_state.dart';

class AdminBodPage extends StatefulWidget {
  const AdminBodPage({super.key});

  @override
  State<AdminBodPage> createState() => _AdminBodPageState();
}

class _AdminBodPageState extends State<AdminBodPage> {
  String? selectedClubId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        if (app.clubs.isEmpty) {
          return const Center(child: Text('Create a club first to manage BoD.'));
        }

        selectedClubId ??= app.clubs.first.id;
        if (!app.clubs.any((club) => club.id == selectedClubId)) {
          selectedClubId = app.clubs.first.id;
        }

        final members = app.bodMembers.where((member) => member.clubId == selectedClubId).toList();

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
              DropdownButtonFormField<String>(
                initialValue: selectedClubId,
                decoration: const InputDecoration(labelText: 'Club'),
                items: app.clubs.map((club) => DropdownMenuItem(value: club.id, child: Text(club.name))).toList(),
                onChanged: (value) => setState(() => selectedClubId = value),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openMemberDialog(context: context, app: app, clubId: selectedClubId!),
                icon: const Icon(Icons.person_add),
                label: const Text('Add BoD Member'),
              ),
              const SizedBox(height: 12),
              ...members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      title: Text(member.name),
                      subtitle: Text(member.position),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: () => _openMemberDialog(context: context, app: app, clubId: member.clubId, member: member),
                            icon: const Icon(Icons.edit, color: Color(0xFF2454D5)),
                          ),
                          IconButton(
                            onPressed: () => app.deleteBodMember(member.id),
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

  Future<void> _openMemberDialog({
    required BuildContext context,
    required AppState app,
    required String clubId,
    BoardMember? member,
  }) async {
    final nameController = TextEditingController(text: member?.name ?? '');
    final positionController = TextEditingController(text: member?.position ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member == null ? 'Add BoD Member' : 'Edit BoD Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: positionController, decoration: const InputDecoration(labelText: 'Position')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final position = positionController.text.trim();
              if (name.isEmpty || position.isEmpty) {
                return;
              }
              if (member == null) {
                app.addBodMember(clubId, name, position);
              } else {
                app.updateBodMember(member.id, name, position);
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
