// lib/features/student/bod/my_club_bod_screen.dart
import 'package:campus_club/features/student/bod/club_management_screen.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/cycle_model.dart';
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
    if (cycles == null || cycles.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: clubs.length,
        itemBuilder: (_, i) =>
            _BodClubCard(club: clubs[i], cycle: null),
      );
    }

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
  final CycleModel? cycle;

  const _BodClubCard({required this.club, required this.cycle});

  /// Effective display status:
  /// - Suspended always wins (Firestore value, set by BEM)
  /// - If active but cycle is inactive/expired → show as Expired
  /// - Otherwise show the real status
  ClubStatus get _effectiveStatus {
    // Suspended is set explicitly by BEM — always show it
    if (club.status == ClubStatus.suspended) return ClubStatus.suspended;

    // If active, check whether the cycle is still live
    if (club.status == ClubStatus.active) {
      final cycleInactive =
          cycle == null || cycle!.isExpired || !cycle!.isActive;
      if (cycleInactive) return ClubStatus.expired;
    }

    return club.status;
  }

  /// Only allow management if truly active (cycle live + not suspended)
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
        // Tappable for active only; suspended and expired are locked
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
                        border:
                            Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Text(_statusLabel(status),
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 4),
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
                      Text('Suspended by BEM — meetings blocked',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade300)),
                  ],
                ),
              ),
              if (_canManage) const Icon(Icons.chevron_right_rounded),
              // Lock icon for suspended
              if (status == ClubStatus.suspended)
                Icon(Icons.lock_rounded,
                    color: Colors.red.shade300, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}