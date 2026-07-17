import 'package:campus_club/features/student/clubs/club_detail_screen.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyClubsScreen extends ConsumerWidget {
  const MyClubsScreen({super.key});

  static const _screenBackground = Color(0xFFFBFDFF);
  static const _textNavy = Color(0xFF101C3D);
  static const _mutedBlue = Color(0xFF8093C6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(myMemberClubsProvider);
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
                    Icons.groups_outlined,
                    size: 80,
                    color: _mutedBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You haven\'t joined any clubs yet.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _textNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Go to the Clubs tab to explore!',
                    style: TextStyle(
                      color: _mutedBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
            itemCount: clubs.length,
            itemBuilder: (_, i) => _MyClubCard(club: clubs[i]),
          );
        },
      ),
    );
  }
}

class _MyClubCard extends StatelessWidget {
  final ClubModel club;
  const _MyClubCard({required this.club});

  static const _softBlue = Color(0xFFEAF4FF);
  static const _primaryBlue = Color(0xFF2F80FF);
  static const _textNavy = Color(0xFF101C3D);
  static const _mutedBlue = Color(0xFF8093C6);
  static const _dividerBlue = Color(0xFFE9EEF8);

  @override
  Widget build(BuildContext context) {
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
                      child: _MyClubMetaItem(
                        icon: Icons.groups_2_outlined,
                        label: '${club.memberCount} members',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MyClubMetaItem(
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

class _MyClubMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MyClubMetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: _MyClubCard._mutedBlue),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _MyClubCard._mutedBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
