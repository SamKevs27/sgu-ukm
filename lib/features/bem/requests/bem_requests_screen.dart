// lib/features/bem/requests/bem_requests_screen.dart
// lib/features/bem/requests/bem_requests_screen.dart
import 'package:campus_club/models/club_request_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/providers/bem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _screenBackground = Color(0xFFF4F6FA);
const _surfaceWhite = Color(0xFFFDFEFF);
const _softBlue = Color(0xFFEAF2FF);
const _primaryBlue = Color(0xFF3A78F2);
const _textNavy = Color(0xFF1A2647);
const _mutedBlue = Color(0xFF7B8FC2);
const _dividerBlue = Color(0xFFE3EAF6);

class BemRequestsScreen extends ConsumerStatefulWidget {
  const BemRequestsScreen({super.key});

  @override
  ConsumerState<BemRequestsScreen> createState() => _BemRequestsScreenState();
}

class _BemRequestsScreenState extends ConsumerState<BemRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allClubRequestsProvider);
    final theme = Theme.of(context);

    return Container(
      color: _screenBackground,
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _dividerBlue),
            ),
            child: TabBar(
              controller: _tab,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: _primaryBlue,
              unselectedLabelColor: _mutedBlue,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              indicator: BoxDecoration(
                color: _softBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Reviewed'),
              ],
            ),
          ),
        ),
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: _primaryBlue),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (requests) {
              final pending = requests
                  .where((r) => r.status == RequestStatus.pending)
                  .toList();
              final reviewed = requests
                  .where((r) => r.status != RequestStatus.pending)
                  .toList();

              return TabBarView(
                controller: _tab,
                children: [
                  _RequestList(requests: pending, isPending: true),
                  _RequestList(requests: reviewed, isPending: false),
                ],
              );
            },
          ),
        ),
      ],
      ),
    );
  }
}

class _RequestList extends ConsumerWidget {
  final List<ClubRequestModel> requests;
  final bool isPending;

  const _RequestList({required this.requests, required this.isPending});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPending
                  ? Icons.inbox_outlined
                  : Icons.check_circle_outline_rounded,
              size: 72,
              color: _mutedBlue,
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending requests' : 'No reviewed requests yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _textNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 126),
      itemCount: requests.length,
      itemBuilder: (_, i) => _RequestCard(
        request: requests[i],
        isPending: isPending,
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final ClubRequestModel request;
  final bool isPending;

  const _RequestCard({required this.request, required this.isPending});

  String _typeLabel(RequestType t) => switch (t) {
        RequestType.create => 'New Club',
        RequestType.renew => 'Renewal',
        RequestType.update => 'Update',
      };

  Color _typeColor(RequestType t, ColorScheme cs) => switch (t) {
      RequestType.create => _primaryBlue,
      RequestType.renew => const Color(0xFF2CA897),
      RequestType.update => const Color(0xFFCF9627),
      };

  Color _statusColor(RequestStatus s) => switch (s) {
      RequestStatus.pending => const Color(0xFFCF9627),
      RequestStatus.approved => const Color(0xFF43AF61),
      RequestStatus.rejected => const Color(0xFFE14D4D),
      };

  String _statusLabel(RequestStatus s) => switch (s) {
        RequestStatus.pending => 'Pending',
        RequestStatus.approved => 'Approved',
        RequestStatus.rejected => 'Rejected',
      };

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    bool approve,
  ) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Approve Request' : 'Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(approve
                ? 'This will activate the club and notify the BoD.'
                : 'Please provide a reason for rejection.'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: approve ? 'Note (optional)' : 'Reason *',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: approve
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final bemUser = ref.read(currentUserProvider).valueOrNull;
    if (bemUser == null) return;

    try {
      await ref.read(bemServiceProvider).reviewRequest(
            requestId: request.requestId,
            clubId: request.clubId,
            approve: approve,
            reviewedBy: bemUser.uid,
            reviewNote: noteController.text.trim().isEmpty
                ? null
                : noteController.text.trim(),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? '✅ Club approved and activated!'
                : '❌ Request rejected.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    final typeColor = _typeColor(request.type, theme.colorScheme);

    // Load the associated club info
    final clubAsync = ref.watch(clubByIdProvider(request.clubId));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _dividerBlue),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17396A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: type badge + status badge ──
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: typeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _typeLabel(request.type),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(request.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor(request.status).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _statusLabel(request.status),
                    style: TextStyle(
                      color: _statusColor(request.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Club info (loaded from Firestore) ──
            clubAsync.when(
              loading: () => const SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryBlue,
                  ),
                ),
              ),
              error: (_, __) => Text('Club ID: ${request.clubId}',
                  style: theme.textTheme.bodySmall),
              data: (club) {
                if (club == null) {
                  return Text('Club not found',
                      style: TextStyle(color: theme.colorScheme.error));
                }
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _softBlue,
                      backgroundImage: club.logoUrl != null
                          ? NetworkImage(club.logoUrl!)
                          : null,
                      child: club.logoUrl == null
                          ? Text(club.name[0].toUpperCase(),
                              style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _primaryBlue,
                            fontSize: 18))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(club.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: _textNavy)),
                          Text(
                            '${club.meetingDay} · ${club.meetingTime} · Room ${club.roomNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: _mutedBlue,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: _dividerBlue),
            const SizedBox(height: 10),

            // ── Meta info ──
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: _mutedBlue),
                const SizedBox(width: 4),
                Text(
                  'Submitted ${fmt.format(request.createdAt)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: _mutedBlue, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            if (request.reviewNote != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _softBlue.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _dividerBlue),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment_rounded, size: 14, color: _mutedBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.reviewNote!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _textNavy,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Action buttons (only for pending) ──
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE14D4D),
                        side: const BorderSide(color: Color(0xFFE14D4D)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () =>
                          _handleAction(context, ref, false),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () =>
                          _handleAction(context, ref, true),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}