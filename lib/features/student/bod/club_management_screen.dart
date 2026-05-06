// lib/features/student/bod/club_management_screen.dart
import 'package:campus_club/features/student/bod/meeting_detail_screen.dart';
import 'package:campus_club/features/student/bod/create_meeting_screen.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/meeting_model.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ClubManagementScreen extends ConsumerWidget {
  final ClubModel club;
  const ClubManagementScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(clubMeetingsProvider(club.clubId));
    final membersAsync = ref.watch(clubMembersProvider(club.clubId));
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(club.name),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Meetings'),
              Tab(icon: Icon(Icons.people_rounded), text: 'Members'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateMeetingScreen(club: club),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Meeting'),
        ),
        body: TabBarView(
          children: [
            // ── Meetings tab ──
            meetingsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (meetings) {
                if (meetings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note_rounded,
                            size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        const Text('No meetings yet.'),
                        const SizedBox(height: 4),
                        Text('Tap + to create your first meeting!',
                            style: TextStyle(
                                color: theme.colorScheme.outline,
                                fontSize: 13)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meetings.length,
                  itemBuilder: (_, i) =>
                      _MeetingCard(meeting: meetings[i], club: club),
                );
              },
            ),

            // ── Members tab ──
            membersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (members) {
                if (members.isEmpty) {
                  return const Center(child: Text('No members yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (_, i) {
                    final m = members[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(m.name[0].toUpperCase()),
                      ),
                      title: Text(m.name),
                      subtitle: Text('NIM: ${m.nim}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded,
                            color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Remove Member'),
                              content: Text(
                                  'Remove ${m.name} from the club?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Remove',
                                        style:
                                            TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(clubServiceProvider)
                                .removeMember(
                                    clubId: club.clubId,
                                    userId: m.userId);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final ClubModel club;
  const _MeetingCard({required this.meeting, required this.club});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd MMM yyyy, HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MeetingDetailScreen(meeting: meeting, club: club),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.event_rounded,
                    color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meeting.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(fmt.format(meeting.createdAt),
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline)),
                    if (meeting.isQrActive) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_rounded,
                              size: 13, color: Colors.green),
                          const SizedBox(width: 4),
                          Text('QR Active',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.green[700])),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}