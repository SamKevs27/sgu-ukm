// lib/features/student/clubs/club_detail_screen.dart
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/attendance_provider.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClubDetailScreen extends ConsumerStatefulWidget {
  final ClubModel club;
  const ClubDetailScreen({super.key, required this.club});

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen> {
  bool _loadingJoin = false;

  Future<void> _toggleJoin(bool isMember) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _loadingJoin = true);
    try {
      final service = ref.read(clubServiceProvider);
      if (isMember) {
        await service.leaveClub(clubId: widget.club.clubId, userId: user.uid);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Left the club.')));
        }
      } else {
        await service.joinClub(clubId: widget.club.clubId, user: user);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Joined the club!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingJoin = false);
    }
  }

  void _showAttendanceDetail(BuildContext context, Map<String, dynamic> data) {
    final meetings = data['meetings'] as List<Map<String, dynamic>>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Detail',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${(data['percentage'] as double).toStringAsFixed(1)}% — '
                '${data['attended']}/${data['totalMeetings']} meetings',
              ),
              const Divider(height: 24),

              // Scrollable list
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: meetings.length,
                  itemBuilder: (_, index) {
                    final m = meetings[index];
                    final date = m['date'] as DateTime;
                    final attended = m['attended'] as bool;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        attended
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: attended ? Colors.green : Colors.red,
                      ),
                      title: Text(m['title'] as String),
                      subtitle: Text('${date.day}/${date.month}/${date.year}'),
                      trailing: Text(
                        attended ? 'Hadir' : 'Tidak Hadir',
                        style: TextStyle(
                          color: attended ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final members = ref.watch(clubMembersProvider(widget.club.clubId));
    final isBod = user != null && widget.club.bod.isBod(user.uid);

    final isMember =
        members.valueOrNull?.any((m) => m.userId == user?.uid) ?? false;

    // Attendance provider — only watch if user is logged in
    final attendanceParams = user == null
        ? null
        : AttendanceParams(
            clubId: widget.club.clubId,
            cycleId: widget.club.cycleId,
            userId: user.uid,
          );

    final attendanceAsync = attendanceParams != null
        ? ref.watch(attendanceDataProvider(attendanceParams))
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.club.name)),
      body: RefreshIndicator(
        onRefresh: () async {
          if (attendanceParams != null) {
            ref.invalidate(attendanceDataProvider(attendanceParams));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + name
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: widget.club.logoUrl != null
                      ? NetworkImage(widget.club.logoUrl!)
                      : null,
                  child: widget.club.logoUrl == null
                      ? Text(
                          widget.club.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  widget.club.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: _StatusChip(status: widget.club.status)),
              const SizedBox(height: 24),

              // Attendance row — only shown if user is a member (not BoD)
              if (isMember && !isBod && attendanceAsync != null) ...[
                attendanceAsync.when(
                  loading: () => const _InfoRow(
                    icon: Icons.how_to_reg,
                    label: 'My Attendance',
                    value: 'Loading...',
                  ),
                  error: (e, _) => const _InfoRow(
                    icon: Icons.how_to_reg,
                    label: 'My Attendance',
                    value: 'Unavailable',
                  ),
                  data: (data) {
                    final percentage = data['percentage'] as double;
                    final attended = data['attended'] as int;
                    final total = data['totalMeetings'] as int;

                    return _AttendanceRow(
                      percentage: percentage,
                      attended: attended,
                      total: total,
                      onTap: () => _showAttendanceDetail(context, data),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Other info rows
              _InfoRow(
                icon: Icons.description_rounded,
                label: 'Description',
                value: widget.club.description,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.schedule_rounded,
                label: 'Meeting',
                value:
                    'Every ${widget.club.meetingDay} at ${widget.club.meetingTime}',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.room_rounded,
                label: 'Room',
                value: widget.club.roomNumber,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.people_rounded,
                label: 'Members',
                value: '${widget.club.memberCount} students',
              ),
              const SizedBox(height: 32),

              // Join / Leave button (not shown to BoD)
              if (!isBod)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadingJoin
                        ? null
                        : () => _toggleJoin(isMember),
                    icon: _loadingJoin
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isMember
                                ? Icons.exit_to_app_rounded
                                : Icons.add_rounded,
                          ),
                    label: Text(isMember ? 'Leave Club' : 'Join Club'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMember
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primary,
                      foregroundColor: isMember
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== attendance row ================

class _AttendanceRow extends StatelessWidget {
  final double percentage;
  final int attended;
  final int total;
  final VoidCallback onTap;

  const _AttendanceRow({
    required this.percentage,
    required this.attended,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = percentage >= 75 ? Colors.green : Colors.red;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.how_to_reg, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Attendance',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($attended/$total meetings)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                  color: color,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        ],
      ),
    );
  }
}

// ─── Info Row ───────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Status Chip ────────────────────────────────────────────────────────────

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
      ClubStatus.pending: 'Pending Review',
      ClubStatus.expired: 'Expired',
      ClubStatus.suspended: 'Suspended',
    };
    final color = colors[status] ?? Colors.grey;
    return Chip(
      label: Text(
        labels[status] ?? status.name,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}
