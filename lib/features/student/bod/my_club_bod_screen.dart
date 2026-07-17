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

  static const _screenBackground = Color(0xFFFBFDFF);
  static const _textNavy = Color(0xFF101C3D);
  static const _mutedBlue = Color(0xFF8093C6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(myBodClubsProvider);
    final cyclesAsync = ref.watch(allCyclesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _screenBackground,
      body: clubsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (clubs) {
          if (clubs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_outline_rounded,
                    size: 80,
                    color: _mutedBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You\'re not a BoD of any club.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _textNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a club to get started!',
                    style: TextStyle(
                      color: _mutedBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return cyclesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        itemCount: clubs.length,
        itemBuilder: (_, i) => _BodClubCard(club: clubs[i], cycle: null),
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
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
          child: Row(
            children: [
              Text(
                cycle.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: _textNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Club card ─────────────────────────────────────────────────────────────────

class _BodClubCard extends StatelessWidget {
  final ClubModel club;
  final CycleModel? cycle;

  const _BodClubCard({required this.club, required this.cycle});

  static const _softBlue = Color(0xFFEAF4FF);
  static const _primaryBlue = Color(0xFF2F80FF);
  static const _textNavy = Color(0xFF101C3D);
  static const _mutedBlue = Color(0xFF8093C6);
  static const _dividerBlue = Color(0xFFE9EEF8);

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

    void openManagement() {
      if (!_canManage) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClubManagementScreen(club: club)),
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
          // Tappable for active only; suspended and expired are locked
          onTap: _canManage ? openManagement : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: club.logoUrl != null
                          ? NetworkImage(club.logoUrl!)
                          : null,
                      child: club.logoUrl == null
                          ? Text(
                              club.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: _primaryBlue,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            club.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _textNavy,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              _StatusBadge(
                                label: _statusLabel(status),
                                color: color,
                              ),
                              if (!_canManage) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  status == ClubStatus.suspended
                                      ? Icons.lock_rounded
                                      : Icons.info_outline_rounded,
                                  color: status == ClubStatus.suspended
                                      ? Colors.red.shade300
                                      : _mutedBlue,
                                  size: 17,
                                ),
                              ],
                            ],
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
                      child: _BodClubMetaItem(
                        icon: Icons.groups_2_outlined,
                        label: '${club.memberCount} members',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BodClubMetaItem(
                        icon: Icons.schedule_rounded,
                        label: '${club.meetingDay} ${club.meetingTime}',
                      ),
                    ),
                  ],
                ),
                if (status != ClubStatus.active) ...[
                  const SizedBox(height: 12),
                  Text(
                    switch (status) {
                      ClubStatus.pending => 'Waiting for BEM approval',
                      ClubStatus.expired => 'Cycle ended - renew to continue',
                      ClubStatus.suspended =>
                        'Suspended by BEM - meetings blocked',
                      ClubStatus.active => '',
                    },
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: status == ClubStatus.suspended
                          ? Colors.red.shade300
                          : _mutedBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: _canManage ? openManagement : null,
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _canManage ? _softBlue : _dividerBlue,
                      disabledBackgroundColor: _dividerBlue,
                      foregroundColor: _canManage ? _primaryBlue : _mutedBlue,
                      disabledForegroundColor: _mutedBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    icon: Icon(
                      _canManage
                          ? Icons.admin_panel_settings_outlined
                          : Icons.lock_outline_rounded,
                      size: 18,
                    ),
                    label: Text(_canManage ? 'Manage' : _statusLabel(status)),
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BodClubMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BodClubMetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: _BodClubCard._mutedBlue),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _BodClubCard._mutedBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
