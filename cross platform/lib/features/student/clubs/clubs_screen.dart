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

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(activeClubsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search clubs...',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: clubsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (clubs) {
                final filtered = _search.isEmpty
                    ? clubs
                    : clubs
                        .where((c) =>
                            c.name.toLowerCase().contains(_search) ||
                            c.description.toLowerCase().contains(_search))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No clubs found'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      _ClubCard(club: filtered[i], userId: user?.uid ?? ''),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateClubScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Club'),
      ),
    );
  }
}

class _ClubCard extends ConsumerWidget {
  final ClubModel club;
  final String userId;
  const _ClubCard({required this.club, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClubDetailScreen(club: club),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: club.logoUrl != null
                    ? NetworkImage(club.logoUrl!)
                    : null,
                child: club.logoUrl == null
                    ? Text(
                        club.name[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      club.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 14,
                            color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text('${club.memberCount} members',
                            style: theme.textTheme.bodySmall),
                        const SizedBox(width: 12),
                        Icon(Icons.schedule_rounded,
                            size: 14,
                            color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          '${club.meetingDay} ${club.meetingTime}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}