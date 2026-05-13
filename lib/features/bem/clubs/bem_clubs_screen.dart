// lib/features/bem/clubs/bem_clubs_screen.dart
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/meeting_model.dart';
import 'package:campus_club/models/member_model.dart';
import 'package:campus_club/providers/attendance_provider.dart';
import 'package:campus_club/providers/bem_provider.dart' hide allClubsProvider;
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _screenBackground = Color(0xFFFBFDFF);
const _softBlue = Color(0xFFEAF4FF);
const _primaryBlue = Color(0xFF2F80FF);
const _textNavy = Color(0xFF101C3D);
const _mutedBlue = Color(0xFF8093C6);
const _dividerBlue = Color(0xFFE9EEF8);

class BemClubsScreen extends ConsumerWidget {
  const BemClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(allClubsWithCycleStatusProvider);

    return Scaffold(
      backgroundColor: _screenBackground,
      body: clubsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _primaryBlue)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (clubs) {
          if (clubs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_outlined, size: 80, color: _mutedBlue),
                  SizedBox(height: 16),
                  Text(
                    'No clubs yet.',
                    style: TextStyle(
                      color: _textNavy,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: _primaryBlue,
            onRefresh: () async =>
                ref.invalidate(allClubsWithCycleStatusProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
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

    void openDetail() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: _screenBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => BemClubDetailSheet(club: club),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4A7A).withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: openDetail,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: _softBlue,
                      backgroundImage: club.logoUrl != null
                          ? NetworkImage(club.logoUrl!)
                          : null,
                      child: club.logoUrl == null
                          ? Text(
                              club.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: _primaryBlue,
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  club.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: _textNavy,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(status: club.status),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            club.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _mutedBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: _dividerBlue),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MetaItem(
                        icon: Icons.people_outline_rounded,
                        label: '${club.memberCount} members',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: meetingsAsync.when(
                        loading: () => const _MetaItem(
                          icon: Icons.event_rounded,
                          label: 'Loading...',
                        ),
                        error: (_, __) => const _MetaItem(
                          icon: Icons.event_rounded,
                          label: 'Meetings unavailable',
                        ),
                        data: (meetings) => _MetaItem(
                          icon: Icons.event_rounded,
                          label: '${meetings.length} meetings',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: openDetail,
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _softBlue,
                      foregroundColor: _primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Detail'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: _mutedBlue),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _mutedBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class BemClubDetailSheet extends ConsumerWidget {
  final ClubModel club;
  const BemClubDetailSheet({required this.club});

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
      builder: (_, scrollController) => DecoratedBox(
        decoration: const BoxDecoration(color: _screenBackground),
        child: Column(
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
                    color: _dividerBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  // ── Club header ──
                  _SheetCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _softBlue,
                          backgroundImage: club.logoUrl != null
                              ? NetworkImage(club.logoUrl!)
                              : null,
                          child: club.logoUrl == null
                              ? Text(
                                  club.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: _primaryBlue,
                                    fontWeight: FontWeight.w800,
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
                                  color: _textNavy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Every ${club.meetingDay} at ${club.meetingTime} - ${club.roomNumber}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _mutedBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: club.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Stats ──
                  meetingsAsync.when(
                    loading: () => const LinearProgressIndicator(
                      color: _primaryBlue,
                      backgroundColor: _softBlue,
                    ),
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryBlue,
                      side: const BorderSide(color: _dividerBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (club.status == ClubStatus.active)
                    OutlinedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _SuspendClubDialog(club: club),
                      ),
                      icon: const Icon(Icons.block_rounded, size: 18),
                      label: const Text('Suspend Club'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    )
                  else if (club.status == ClubStatus.suspended)
                    FilledButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Reactivate Club'),
                            content: Text('Set "${club.name}" back to active?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Reactivate'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          try {
                            await ref
                                .read(bemServiceProvider)
                                .reactivateClub(club.clubId);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Reactivate Club'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  const Divider(height: 32, color: _dividerBlue),

                  // ── Meetings ──
                  Text(
                    'Meetings',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _textNavy,
                      fontWeight: FontWeight.w800,
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
                                color: _mutedBlue,
                                fontWeight: FontWeight.w500,
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
                  const Divider(height: 32, color: _dividerBlue),

                  // ── Members ──
                  Text(
                    'Members',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _textNavy,
                      fontWeight: FontWeight.w800,
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
                                color: _mutedBlue,
                                fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  final Widget child;

  const _SheetCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _dividerBlue),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4A7A).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
              initialValue: _meetingDay,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dividerBlue),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _softBlue,
          child: Text(
            member.name[0].toUpperCase(),
            style: const TextStyle(
              color: _primaryBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          member.name,
          style: const TextStyle(color: _textNavy, fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NIM: ${member.nim}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _mutedBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Joined ${_formatDate(member.joinedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _mutedBlue,
                fontWeight: FontWeight.w500,
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
          error: (_, __) => const Text('-'),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$attended/$total meetings',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _mutedBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dividerBlue),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                      color: _textNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _formatDate(meeting.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _mutedBlue,
                    fontWeight: FontWeight.w500,
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
                  color: _mutedBlue,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),

            // ── Attendance count ──
            attendanceAsync.when(
              loading: () => const LinearProgressIndicator(
                color: _primaryBlue,
                backgroundColor: _softBlue,
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (attendees) => Row(
                children: [
                  const Icon(
                    Icons.how_to_reg_rounded,
                    size: 14,
                    color: _primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$attendees',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // QR status
                  Icon(
                    meeting.isQrActive
                        ? Icons.qr_code_rounded
                        : Icons.qr_code_2_rounded,
                    size: 14,
                    color: meeting.isQrActive ? Colors.green : _mutedBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    meeting.isQrActive ? 'QR Active' : 'QR Expired',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: meeting.isQrActive ? Colors.green : _mutedBlue,
                      fontWeight: FontWeight.w600,
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _dividerBlue),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _softBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: _primaryBlue),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _textNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _mutedBlue,
                    fontWeight: FontWeight.w600,
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

class _SuspendClubDialog extends ConsumerStatefulWidget {
  final ClubModel club;
  const _SuspendClubDialog({required this.club});

  @override
  ConsumerState<_SuspendClubDialog> createState() => _SuspendClubDialogState();
}

class _SuspendClubDialogState extends ConsumerState<_SuspendClubDialog> {
  final _reasonCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _suspend() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(bemServiceProvider)
          .suspendClub(
            clubId: widget.club.clubId,
            reason: _reasonCtrl.text.trim().isEmpty
                ? null
                : _reasonCtrl.text.trim(),
          );
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
    return AlertDialog(
      title: Text('Suspend "${widget.club.name}"?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This club will be blocked from creating meetings.'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'e.g. Violation of club policy',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _suspend,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Suspend'),
        ),
      ],
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
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
