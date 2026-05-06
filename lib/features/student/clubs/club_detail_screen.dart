// lib/features/student/clubs/club_detail_screen.dart
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/services/club_service.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left the club.')),
          );
        }
      } else {
        await service.joinClub(clubId: widget.club.clubId, user: user);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined the club!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingJoin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final members = ref.watch(clubMembersProvider(widget.club.clubId));
    final isBod = user != null && widget.club.bod.isBod(user.uid);

    final isMember = members.valueOrNull
            ?.any((m) => m.userId == user?.uid) ??
        false;

    return Scaffold(
      appBar: AppBar(title: Text(widget.club.name)),
      body: SingleChildScrollView(
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
              child: Text(widget.club.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Center(
              child: _StatusChip(status: widget.club.status),
            ),
            const SizedBox(height: 24),

            // Info cards
            _InfoRow(
                icon: Icons.description_rounded,
                label: 'Description',
                value: widget.club.description),
            const SizedBox(height: 12),
            _InfoRow(
                icon: Icons.schedule_rounded,
                label: 'Meeting',
                value:
                    'Every ${widget.club.meetingDay} at ${widget.club.meetingTime}'),
            const SizedBox(height: 12),
            _InfoRow(
                icon: Icons.room_rounded,
                label: 'Room',
                value: widget.club.roomNumber),
            const SizedBox(height: 12),
            _InfoRow(
                icon: Icons.people_rounded,
                label: 'Members',
                value: '${widget.club.memberCount} students'),
            const SizedBox(height: 32),

            // Join / Leave button (not shown to BoD)
            if (!isBod)
              ElevatedButton.icon(
                onPressed: _loadingJoin ? null : () => _toggleJoin(isMember),
                icon: _loadingJoin
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isMember
                        ? Icons.exit_to_app_rounded
                        : Icons.add_rounded),
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
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

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
              Text(label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline)),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
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
      ClubStatus.pending: 'Pending Review',
      ClubStatus.expired: 'Expired',
      ClubStatus.suspended: 'Suspended',
    };
    final color = colors[status] ?? Colors.grey;
    return Chip(
      label: Text(labels[status] ?? status.name,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}