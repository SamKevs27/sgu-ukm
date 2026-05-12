// lib/features/student/bod/my_club_bod_screen.dart
import 'package:campus_club/features/student/bod/club_management_screen.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/cycle_model.dart';               // ← was missing
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/cycle_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyClubBodScreen extends ConsumerWidget {
  const MyClubBodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(myBodClubsProvider);
    final cyclesAsync = ref.watch(allCyclesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: clubsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (clubs) {
          if (clubs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline_rounded,
                      size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('You\'re not a BoD of any club.',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Create a club to get started!',
                      style: TextStyle(color: theme.colorScheme.outline)),
                ],
              ),
            );
          }

          return cyclesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildList(clubs, null, theme),
            data: (cycles) => _buildList(clubs, cycles, theme),
          );
        },
      ),
    );
  }

  Widget _buildList(
    List<ClubModel> clubs,
    List<CycleModel>? cycles,
    ThemeData theme,
  ) {
    // Build a cycleId → CycleModel map for O(1) lookup
    final cycleMap = {
      if (cycles != null)
        for (final c in cycles) c.cycleId: c,
    };

    if (cycles == null || cycles.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: clubs.length,
        itemBuilder: (_, i) => _BodClubCard(
          club: clubs[i],
          cycle: null,
        ),
      );
    }

    // Group clubs under their cycle, in newest-cycle-first order
    final grouped = <String, List<ClubModel>>{
      for (final c in cycles) c.cycleId: [],
    };
    final ungrouped = <ClubModel>[];
    for (final club in clubs) {
      if (grouped.containsKey(club.cycleId)) {
        grouped[club.cycleId]!.add(club);
      } else {
        ungrouped.add(club);
      }
    }

    final widgets = <Widget>[];

    for (final cycle in cycles) {
      final cycleClubs = grouped[cycle.cycleId] ?? [];
      if (cycleClubs.isEmpty) continue;

      // Cycle header
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            children: [
              Text(cycle.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _cycleBadge(cycle),
            ],
          ),
        ),
      );

      for (final club in cycleClubs) {
        widgets.add(_BodClubCard(club: club, cycle: cycle));
      }
    }

    // Clubs whose cycle no longer exists
    for (final club in ungrouped) {
      widgets.add(_BodClubCard(club: club, cycle: null));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: widgets,
    );
  }

  Widget _cycleBadge(CycleModel cycle) {
    final expired = cycle.isExpired;
    final color = cycle.isActive && !expired
        ? Colors.green
        : expired
            ? Colors.grey
            : Colors.orange;
    final label = cycle.isActive && !expired
        ? 'Active'
        : expired
            ? 'Expired'
            : 'Inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Club card ─────────────────────────────────────────────────────────────────

class _BodClubCard extends StatelessWidget {
  final ClubModel club;

  /// The cycle this club belongs to. Used to override the displayed status
  /// when the cycle has ended — a club that is technically "active" in
  /// Firestore should show as "Expired" if its cycle is over.
  final CycleModel? cycle;

  const _BodClubCard({required this.club, required this.cycle});

  /// Effective status: if the club's own status is active but the cycle is
  /// expired, treat it as expired so the UI reflects reality.
  ClubStatus get _effectiveStatus {
    if (club.status == ClubStatus.active) {
      // Treat as expired if: cycle is over OR cycle is no longer active
      final cycleInactive = cycle == null || cycle!.isExpired || !cycle!.isActive;
      if (cycleInactive) return ClubStatus.expired;
    }
    return club.status;
  }

  bool get _canManage => _effectiveStatus == ClubStatus.active;

  Color _statusColor(ClubStatus s) => switch (s) {
        ClubStatus.active => Colors.green,
        ClubStatus.pending => Colors.orange,
        ClubStatus.suspended => Colors.red,
        ClubStatus.expired => Colors.grey,
      };

  String _statusLabel(ClubStatus s) => switch (s) {
        ClubStatus.active => 'Active',
        ClubStatus.pending => 'In Review',
        ClubStatus.suspended => 'Suspended',
        ClubStatus.expired => 'Expired',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _effectiveStatus;
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _canManage
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClubManagementScreen(club: club),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: club.logoUrl != null
                    ? NetworkImage(club.logoUrl!)
                    : null,
                child: club.logoUrl == null
                    ? Text(club.name[0].toUpperCase(),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Text(_statusLabel(status),
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 4),
                    // Status-specific hint text
                    if (status == ClubStatus.pending)
                      Text('Waiting for BEM approval',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline)),
                    if (status == ClubStatus.expired)
                      Text('Cycle ended — renew to continue',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline)),
                    if (status == ClubStatus.suspended)
                      Text('Club suspended by BEM',
                          style: TextStyle(
                              fontSize: 11, color: Colors.red.shade300)),
                  ],
                ),
              ),
              if (_canManage) const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}