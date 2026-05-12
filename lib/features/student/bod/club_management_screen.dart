// lib/features/student/bod/club_management_screen.dart
import 'package:campus_club/features/student/bod/meeting_detail_screen.dart';
import 'package:campus_club/features/student/bod/create_meeting_screen.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/meeting_model.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ── Design tokens (matches BEM dashboard) ────────────────────────────────────
const _screenBackground = Color(0xFFFBFDFF);
const _softBlue         = Color(0xFFEAF4FF);
const _primaryBlue      = Color(0xFF2F80FF);
const _textNavy         = Color(0xFF101C3D);
const _mutedBlue        = Color(0xFF8093C6);
const _dividerBlue      = Color(0xFFE9EEF8);

// ── Glass Card (identical to BEM dashboard) ───────────────────────────────────
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

// ── Chip-style mini stat (mirrors BEM _MiniStat) ─────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

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
            label,
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

// ── Main Screen ───────────────────────────────────────────────────────────────
class ClubManagementScreen extends ConsumerWidget {
  final ClubModel club;
  const ClubManagementScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(clubMeetingsProvider(club.clubId));
    final membersAsync  = ref.watch(clubMembersProvider(club.clubId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _screenBackground,
        // ── App bar ──────────────────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: const Color(0xFF1B4A7A).withValues(alpha: 0.08),
          elevation: 1,
          iconTheme: const IconThemeData(color: _textNavy),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
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
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textNavy,
                      ),
                    ),
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
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _dividerBlue, width: 1),
                ),
              ),
              child: TabBar(
                labelColor: _primaryBlue,
                unselectedLabelColor: _mutedBlue,
                indicatorColor: _primaryBlue,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.calendar_month_rounded, size: 18), text: 'Meetings'),
                  Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Members'),
                ],
              ),
            ),
          ),
        ),

        // ── FAB ──────────────────────────────────────────────────────────────
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateMeetingScreen(club: club)),
          ),
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'New Meeting',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),

        // ── Tab bodies ───────────────────────────────────────────────────────
        body: TabBarView(
          children: [
            // ── Meetings tab ─────────────────────────────────────────────────
            meetingsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _primaryBlue),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (meetings) {
                if (meetings.isEmpty) {
                  return _EmptyState(
                    icon: Icons.event_note_rounded,
                    message: 'No meetings yet.',
                    hint: 'Tap + to create your first meeting!',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: meetings.length,
                  itemBuilder: (_, i) =>
                      _MeetingCard(meeting: meetings[i], club: club),
                );
              },
            ),

            // ── Members tab ──────────────────────────────────────────────────
            membersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _primaryBlue),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return _EmptyState(
                    icon: Icons.people_outline_rounded,
                    message: 'No members yet.',
                    hint: 'Members will appear here once they join.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: members.length,
                  itemBuilder: (_, i) =>
                      _MemberCard(member: members[i], club: club, ref: ref),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 36, color: _primaryBlue),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: _textNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _mutedBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Meeting Card ──────────────────────────────────────────────────────────────
class _MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final ClubModel club;
  const _MeetingCard({required this.meeting, required this.club});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');

    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MeetingDetailScreen(meeting: meeting, club: club),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _primaryBlue.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: _primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _textNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(meeting.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _mutedBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (meeting.isQrActive) ...[
                      const SizedBox(height: 6),
                      _Chip(
                        icon: Icons.qr_code_rounded,
                        label: 'QR Active',
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ],
                ),
              ),
              // Chevron
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: _primaryBlue,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Member Card ───────────────────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final dynamic member; // replace with your actual member model type
  final ClubModel club;
  final WidgetRef ref;

  const _MemberCard({
    required this.member,
    required this.club,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: _softBlue,
              child: Text(
                member.name[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _primaryBlue,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + NIM
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _textNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _Chip(
                    icon: Icons.badge_outlined,
                    label: member.nim,
                    color: _mutedBlue,
                  ),
                ],
              ),
            ),
            // Remove button
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: const Text(
                      'Remove Member',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _textNavy,
                      ),
                    ),
                    content: Text(
                      'Remove ${member.name} from the club?',
                      style: const TextStyle(color: _mutedBlue),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: _mutedBlue),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(clubServiceProvider)
                      .removeMember(clubId: club.clubId, userId: member.userId);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.person_remove_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}