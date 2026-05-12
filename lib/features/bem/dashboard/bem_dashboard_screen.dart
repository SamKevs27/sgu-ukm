// lib/features/bem/dashboard/bem_dashboard_screen.dart
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/bem_provider.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/cycle_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ── Per-club stats provider ───────────────────────────────────────────────────

final _clubStatsProvider =
    FutureProvider.family<_ClubStats, String>((ref, clubId) async {
  final db = FirebaseFirestore.instance;

  final meetingsSnap = await db
      .collection('clubs')
      .doc(clubId)
      .collection('meetings')
      .count()
      .get();

  final membersSnap = await db
      .collection('clubs')
      .doc(clubId)
      .collection('members')
      .count()
      .get();

  return _ClubStats(
    meetingCount: meetingsSnap.count ?? 0,
    memberCount: membersSnap.count ?? 0,
  );
});

class _ClubStats {
  final int meetingCount;
  final int memberCount;
  const _ClubStats({required this.meetingCount, required this.memberCount});
}

// ── Screen ────────────────────────────────────────────────────────────────────

class BemDashboardScreen extends ConsumerWidget {
  const BemDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use cycle-aware provider so inactive-cycle clubs are marked expired
    final allClubsAsync = ref.watch(allClubsWithCycleStatusProvider);
    final activeCycleAsync = ref.watch(activeCycleProvider);
    final theme = Theme.of(context);
    final fmt = DateFormat('dd MMM yyyy');

    return allClubsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (clubs) {
        final activeClubs =
            clubs.where((c) => c.status == ClubStatus.active).toList();
        final pendingClubs =
            clubs.where((c) => c.status == ClubStatus.pending).toList();
        final suspendedClubs =
            clubs.where((c) => c.status == ClubStatus.suspended).toList();
        final expiredClubs =
            clubs.where((c) => c.status == ClubStatus.expired).toList();

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(allClubsWithCycleStatusProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Active cycle banner ──
              activeCycleAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (cycle) => cycle == null
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_rounded,
                                color: theme.colorScheme.onErrorContainer),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No active cycle. Create one in the Cycles tab.',
                                style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Current Cycle',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600)),
                                  Text(cycle.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme
                                              .onPrimaryContainer)),
                                  Text(
                                    '${fmt.format(cycle.startDate)} – ${fmt.format(cycle.endDate)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // ── Summary stat cards ──
              Text('Overview',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    label: 'Total Clubs',
                    value: clubs.length,
                    icon: Icons.groups_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Active',
                    value: activeClubs.length,
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatCard(
                    label: 'Pending',
                    value: pendingClubs.length,
                    icon: Icons.hourglass_top_rounded,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Suspended',
                    value: suspendedClubs.length,
                    icon: Icons.block_rounded,
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Active clubs list ──
              Text('Active Clubs',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Meetings and members this cycle',
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.outline)),
              const SizedBox(height: 12),

              if (activeClubs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No active clubs yet.',
                        style:
                            TextStyle(color: theme.colorScheme.outline)),
                  ),
                )
              else
                ...activeClubs
                    .map((club) => _ClubDashboardCard(club: club)),

              // ── Pending approval section ──
              if (pendingClubs.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('Pending Approval',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${pendingClubs.length}',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...pendingClubs
                    .map((club) => _PendingClubTile(club: club)),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: theme.colorScheme.outline)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubDashboardCard extends ConsumerWidget {
  final ClubModel club;
  const _ClubDashboardCard({required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(_clubStatsProvider(club.clubId));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: club.logoUrl != null
                  ? NetworkImage(club.logoUrl!)
                  : null,
              child: club.logoUrl == null
                  ? Text(club.name[0].toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(club.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    'Every ${club.meetingDay} · Room ${club.roomNumber}',
                    style: TextStyle(
                        fontSize: 11, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            statsAsync.when(
              loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => Row(
                children: [
                  _MiniStat(
                      icon: Icons.event_rounded,
                      value: stats.meetingCount,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  _MiniStat(
                      icon: Icons.people_rounded,
                      value: stats.memberCount,
                      color: Colors.teal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  const _MiniStat(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text('$value',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _PendingClubTile extends StatelessWidget {
  final ClubModel club;
  const _PendingClubTile({required this.club});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.15),
          backgroundImage: club.logoUrl != null
              ? NetworkImage(club.logoUrl!)
              : null,
          child: club.logoUrl == null
              ? Text(club.name[0].toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange))
              : null,
        ),
        title: Text(club.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            'Every ${club.meetingDay} · Room ${club.roomNumber}',
            style: TextStyle(
                fontSize: 11, color: theme.colorScheme.outline)),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Text('In Review',
              style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}