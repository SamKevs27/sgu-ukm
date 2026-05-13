// lib/features/bem/dashboard/bem_dashboard_screen.dart
import 'package:campus_club/features/student/clubs/club_detail_screen.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/cycle_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:campus_club/features/bem/clubs/bem_clubs_screen.dart';

// ── Per-club stats provider ───────────────────────────────────────────────────
final _clubStatsProvider = FutureProvider.family<_ClubStats, String>((
  ref,
  clubId,
) async {
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

const _screenBackground = Color(0xFFFBFDFF);
const _softBlue = Color(0xFFEAF4FF);
const _primaryBlue = Color(0xFF2F80FF);
const _textNavy = Color(0xFF101C3D);
const _mutedBlue = Color(0xFF8093C6);
const _dividerBlue = Color(0xFFE9EEF8);

// ── Screen ────────────────────────────────────────────────────────────────────
class BemDashboardScreen extends ConsumerWidget {
  const BemDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allClubsAsync = ref.watch(allClubsWithCycleStatusProvider);
    final activeCycleAsync = ref.watch(activeCycleProvider);
    final fmt = DateFormat('dd MMM yyyy');

    return ColoredBox(
      color: _screenBackground,
      child: allClubsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _primaryBlue)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (clubs) {
          final activeClubs =
              clubs.where((c) => c.status == ClubStatus.active).toList();
          final pendingClubs =
              clubs.where((c) => c.status == ClubStatus.pending).toList();
          final suspendedClubs =
              clubs.where((c) => c.status == ClubStatus.suspended).toList();
          return RefreshIndicator(
            color: _primaryBlue,
            onRefresh: () async =>
                ref.invalidate(allClubsWithCycleStatusProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
              children: [
                // ── Active cycle banner ──
                activeCycleAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (cycle) => cycle == null
                      ? _GlassCard(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withValues(alpha: 0.10),
                              Colors.orange.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: Colors.red.withValues(alpha: 0.3),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.red.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.warning_rounded,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'No active cycle. Create one in the Cycles tab.',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _GlassCard(
                          gradient: LinearGradient(
                            colors: [
                              _primaryBlue.withValues(alpha: 0.11),
                              _softBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: _primaryBlue.withValues(alpha: 0.2),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: _primaryBlue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Current Cycle',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _mutedBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cycle.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _textNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${fmt.format(cycle.startDate)} – ${fmt.format(cycle.endDate)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _mutedBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // ── Summary stat cards ──
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textNavy,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatCard(
                      label: 'Total Clubs',
                      value: clubs.length,
                      icon: Icons.groups_rounded,
                      color: _primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Active',
                      value: activeClubs.length,
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      label: 'Pending',
                      value: pendingClubs.length,
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Suspended',
                      value: suspendedClubs.length,
                      icon: Icons.block_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Active clubs list ──
                const Text(
                  'Active Clubs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textNavy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Meetings and members this cycle',
                  style: TextStyle(
                    fontSize: 13,
                    color: _mutedBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                if (activeClubs.isEmpty)
                  const _GlassCard(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 40, color: _mutedBlue),
                            SizedBox(height: 8),
                            Text(
                              'No active clubs yet.',
                              style: TextStyle(
                                color: _mutedBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...activeClubs
                      .map((club) => _ClubDashboardCard(club: club)),

                // ── Pending approval section ──
                if (pendingClubs.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Text(
                        'Pending Approval',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _textNavy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${pendingClubs.length}',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...pendingClubs.map((club) => _PendingClubTile(club: club)),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Reusable Glass Card ───────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  const _GlassCard({
    required this.child,
    this.gradient,
    this.borderColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
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
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? Colors.white : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor ?? _dividerBlue, width: 1),
        ),
        child: child,
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _GlassCard(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: color.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _mutedBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Club Dashboard Card ───────────────────────────────────────────────────────
class _ClubDashboardCard extends ConsumerWidget {
  final ClubModel club;
  const _ClubDashboardCard({required this.club});

  void _openDetail(BuildContext context) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_clubStatsProvider(club.clubId));

    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _softBlue,
                    backgroundImage: club.logoUrl != null
                        ? NetworkImage(club.logoUrl!)
                        : null,
                    child: club.logoUrl == null
                        ? Text(
                            club.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _textNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Every ${club.meetingDay} · Room ${club.roomNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _mutedBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                statsAsync.when(
                  loading: () => const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _primaryBlue),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) => Row(
                    children: [
                      _MiniStat(
                        icon: Icons.event_rounded,
                        value: stats.meetingCount,
                        color: _primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      _MiniStat(
                        icon: Icons.people_rounded,
                        value: stats.memberCount,
                        color: const Color(0xFF14B8A6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: _mutedBlue, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mini Stat ─────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending Club Tile ─────────────────────────────────────────────────────────
class _PendingClubTile extends StatelessWidget {
  final ClubModel club;
  const _PendingClubTile({required this.club});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF59E0B);

    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      gradient: LinearGradient(
        colors: [
          orange.withValues(alpha: 0.08),
          orange.withValues(alpha: 0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: orange.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: orange.withValues(alpha: 0.15),
              backgroundImage:
                  club.logoUrl != null ? NetworkImage(club.logoUrl!) : null,
              child: club.logoUrl == null
                  ? Text(
                      club.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: orange,
                        fontSize: 16,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _textNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Every ${club.meetingDay} · Room ${club.roomNumber}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _mutedBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: orange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'In Review',
                style: TextStyle(
                  color: orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}