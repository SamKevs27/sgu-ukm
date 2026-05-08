// lib/features/bem/clubs/bem_clubs_screen.dart
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/meeting_model.dart';
import 'package:campus_club/models/member_model.dart';
import 'package:campus_club/providers/attendance_provider.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BemClubsScreen extends ConsumerWidget {
  const BemClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(allClubsProvider);

    return Scaffold(
      body: clubsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (clubs) {
          if (clubs.isEmpty) {
            return const Center(child: Text('No clubs yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allClubsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clubs.length,
              itemBuilder: (_, i) => _ClubCard(club: clubs[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ClubCard extends ConsumerWidget {
  final ClubModel club;
  const _ClubCard({required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meetingsAsync = ref.watch(clubMeetingsProvider(club.clubId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _ClubDetailSheet(club: club),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: club.logoUrl != null
                    ? NetworkImage(club.logoUrl!)
                    : null,
                child: club.logoUrl == null
                    ? Text(
                        club.name[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            club.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _StatusDot(status: club.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${club.memberCount} members',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.event_rounded,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        meetingsAsync.when(
                          loading: () => const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (meetings) => Text(
                            '${meetings.length} meetings',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubDetailSheet extends ConsumerWidget {
  final ClubModel club;
  const _ClubDetailSheet({required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(clubMembersProvider(club.clubId));
    final meetingsAsync = ref.watch(clubMeetingsProvider(club.clubId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                // ── Club header ──
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: club.logoUrl != null
                          ? NetworkImage(club.logoUrl!)
                          : null,
                      child: club.logoUrl == null
                          ? Text(
                              club.name[0].toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            club.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Every ${club.meetingDay} at ${club.meetingTime} · ${club.roomNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(status: club.status),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Stats ──
                meetingsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (meetings) => Row(
                    children: [
                      _StatBox(
                        icon: Icons.event_rounded,
                        label: 'Meetings',
                        value: '${meetings.length}',
                      ),
                      const SizedBox(width: 12),
                      _StatBox(
                        icon: Icons.people_rounded,
                        label: 'Members',
                        value: '${club.memberCount}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Edit button ──
                OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => _EditClubDialog(club: club),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit Club Details'),
                ),
                const Divider(height: 32),

                // ── Meetings ──
                Text(
                  'Meetings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                meetingsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (meetings) {
                    if (meetings.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No meetings yet.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: meetings
                          .map(
                            (m) =>
                                _MeetingTile(meeting: m, clubId: club.clubId),
                          )
                          .toList(),
                    );
                  },
                ),
                const Divider(height: 32),

                // ── Members ──
                Text(
                  'Members',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                membersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (members) {
                    if (members.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No members yet.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: members
                          .map(
                            (m) => _MemberAttendanceTile(
                              member: m,
                              clubId: club.clubId,
                              cycleId: club.cycleId,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditClubDialog extends ConsumerStatefulWidget {
  final ClubModel club;
  const _EditClubDialog({required this.club});

  @override
  ConsumerState<_EditClubDialog> createState() => _EditClubDialogState();
}

class _EditClubDialogState extends ConsumerState<_EditClubDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _roomCtrl;
  late String _meetingDay;
  late final TextEditingController _meetingTimeCtrl;
  bool _loading = false;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.club.name);
    _descCtrl = TextEditingController(text: widget.club.description);
    _roomCtrl = TextEditingController(text: widget.club.roomNumber);
    _meetingDay = widget.club.meetingDay;
    _meetingTimeCtrl = TextEditingController(text: widget.club.meetingTime);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _roomCtrl.dispose();
    _meetingTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(clubServiceProvider)
          .updateClubDetails(
            clubId: widget.club.clubId,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            roomNumber: _roomCtrl.text.trim(),
            meetingDay: _meetingDay,
            meetingTime: _meetingTimeCtrl.text.trim(),
          );
      ref.invalidate(allClubsProvider);
      ref.invalidate(clubMeetingsProvider(widget.club.clubId));
      ref.invalidate(clubMembersProvider(widget.club.clubId));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit Club Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Club Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomCtrl,
              decoration: const InputDecoration(labelText: 'Room Number'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _meetingDay,
              decoration: const InputDecoration(labelText: 'Meeting Day'),
              items: _days
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _meetingDay = v ?? _meetingDay),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _meetingTimeCtrl,
              decoration: const InputDecoration(
                labelText: 'Meeting Time (e.g. 15:00)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _MemberAttendanceTile extends ConsumerWidget {
  final MemberModel member;
  final String clubId;
  final String cycleId;

  const _MemberAttendanceTile({
    required this.member,
    required this.clubId,
    required this.cycleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final params = AttendanceParams(
      clubId: clubId,
      cycleId: cycleId,
      userId: member.userId,
    );
    final attendanceAsync = ref.watch(attendanceDataProvider(params));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          member.name[0].toUpperCase(),
          style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
      title: Text(
        member.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NIM: ${member.nim}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Text(
            'Joined ${_formatDate(member.joinedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      trailing: attendanceAsync.when(
        loading: () => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => const Text('—'),
        data: (data) {
          final percentage = data['percentage'] as double;
          final attended = data['attended'] as int;
          final total = data['totalMeetings'] as int;
          final color = percentage >= 75 ? Colors.green : Colors.red;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '$attended/$total meetings',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _MeetingTile extends ConsumerWidget {
  final MeetingModel meeting;
  final String clubId;

  const _MeetingTile({required this.meeting, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final attendanceAsync = ref.watch(
      meetingAttendanceCountProvider((
        clubId: clubId,
        meetingId: meeting.meetingId,
      )),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title + date ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    meeting.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(meeting.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            if (meeting.description != null &&
                meeting.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                meeting.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),

            // ── Attendance count ──
            attendanceAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (attendees) => Row(
                children: [
                  Icon(
                    Icons.how_to_reg_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$attendees',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // QR status
                  Icon(
                    meeting.isQrActive
                        ? Icons.qr_code_rounded
                        : Icons.qr_code_2_rounded,
                    size: 14,
                    color: meeting.isQrActive
                        ? Colors.green
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    meeting.isQrActive ? 'QR Active' : 'QR Expired',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: meeting.isQrActive
                          ? Colors.green
                          : theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _StatsRow extends StatelessWidget {
  final int meetingCount;
  final int memberCount;
  const _StatsRow({required this.meetingCount, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _StatBox(
          icon: Icons.event_rounded,
          label: 'Meetings this cycle',
          value: '$meetingCount',
        ),
        const SizedBox(width: 12),
        _StatBox(
          icon: Icons.people_rounded,
          label: 'Members',
          value: '$memberCount',
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final ClubStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      ClubStatus.active: Colors.green,
      ClubStatus.pending: Colors.orange,
      ClubStatus.expired: Colors.grey,
      ClubStatus.suspended: Colors.red,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: colors[status] ?? Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ClubStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      ClubStatus.active: Colors.green,
      ClubStatus.pending: Colors.orange,
      ClubStatus.expired: Colors.grey,
      ClubStatus.suspended: Colors.red,
    };
    final labels = {
      ClubStatus.active: 'Active',
      ClubStatus.pending: 'Pending',
      ClubStatus.expired: 'Expired',
      ClubStatus.suspended: 'Suspended',
    };
    final color = colors[status] ?? Colors.grey;
    return Chip(
      label: Text(
        labels[status] ?? status.name,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
