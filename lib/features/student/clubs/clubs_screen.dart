// lib/features/student/clubs/clubs_screen.dart
import 'package:campus_club/features/student/clubs/club_detail_screen.dart';
import 'package:campus_club/features/student/clubs/create_club_screen.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClubsScreen extends ConsumerStatefulWidget {
  const ClubsScreen({super.key});

  @override
  ConsumerState<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends ConsumerState<ClubsScreen> {
  String _search = '';

  static const _screenBackground = Color(0xFFFBFDFF);
  static const _softBlue = Color(0xFFEAF4FF);
  static const _primaryBlue = Color(0xFF2F80FF);
  static const _textNavy = Color(0xFF101C3D);
  static const _mutedBlue = Color(0xFF8093C6);

  @override
  Widget build(BuildContext context) {
    // Uses cycle-aware provider, then filters out anything not truly active
    final clubsAsync = ref.watch(activeClubsWithCycleStatusProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: _screenBackground,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search clubs...',
                hintStyle: TextStyle(
                  color: _mutedBlue,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: _mutedBlue),
                filled: true,
                fillColor: _softBlue,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                  borderSide: BorderSide(color: _primaryBlue, width: 1.2),
                ),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: clubsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (clubs) {
                // Filter out clubs whose cycle is inactive (marked as expired
                // by activeClubsWithCycleStatusProvider)
                final activeCycleClubs = clubs
                    .where((c) => c.status == ClubStatus.active)
                    .toList();

                final filtered = _search.isEmpty
                    ? activeCycleClubs
                    : activeCycleClubs
                          .where(
                            (c) =>
                                c.name.toLowerCase().contains(_search) ||
                                c.description.toLowerCase().contains(_search),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: _mutedBlue,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No clubs found',
                          style: TextStyle(
                            color: _textNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 112),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      _ClubCard(club: filtered[i], userId: user?.uid ?? ''),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96),
        child: FloatingActionButton.extended(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateClubScreen()),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Club'),
        ),
      ),
    );
  }
}

class _ClubCard extends ConsumerWidget {
  final ClubModel club;
  final String userId;
  const _ClubCard({required this.club, required this.userId});

  static const _softBlue = Color(0xFFEAF4FF);
  static const _primaryBlue = Color(0xFF2F80FF);
  static const _textNavy = Color(0xFF101C3D);
  static const _mutedBlue = Color(0xFF8093C6);
  static const _dividerBlue = Color(0xFFE9EEF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    void openDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClubDetailScreen(club: club)),
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
                      backgroundColor: theme.colorScheme.primaryContainer,
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
                      child: _ClubMetaItem(
                        icon: Icons.groups_2_outlined,
                        label: '${club.memberCount} members',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ClubMetaItem(
                        icon: Icons.schedule_rounded,
                        label: '${club.meetingDay} ${club.meetingTime}',
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

class _ClubMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ClubMetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: _ClubCard._mutedBlue),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _ClubCard._mutedBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
