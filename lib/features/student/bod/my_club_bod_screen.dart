// lib/features/student/bod/my_club_bod_screen.dart
import 'package:campus_club/features/student/bod/club_management_screen.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyClubBodScreen extends ConsumerWidget {
  const MyClubBodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(myBodClubsProvider);
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clubs.length,
            itemBuilder: (_, i) => _BodClubCard(club: clubs[i]),
          );
        },
      ),
    );
  }
}

class _BodClubCard extends StatelessWidget {
  final ClubModel club;
  const _BodClubCard({required this.club});

  Color _statusColor(ClubStatus s) {
    return switch (s) {
      ClubStatus.active => Colors.green,
      ClubStatus.pending => Colors.orange,
      ClubStatus.suspended => Colors.red,
      ClubStatus.expired => Colors.grey,
    };
  }

  String _statusLabel(ClubStatus s) {
    return switch (s) {
      ClubStatus.active => 'Active',
      ClubStatus.pending => 'In Review',
      ClubStatus.suspended => 'Suspended',
      ClubStatus.expired => 'Expired',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(club.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: club.status == ClubStatus.active
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
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Text(_statusLabel(club.status),
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (club.status == ClubStatus.pending) ...[
                      const SizedBox(height: 4),
                      Text('Waiting for BEM approval',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline)),
                    ],
                  ],
                ),
              ),
              if (club.status == ClubStatus.active)
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}