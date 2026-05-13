// lib/features/student/clubs/club_detail_screen.dart
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/attendance_provider.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_club/providers/cycle_provider.dart';

// ── Design tokens (mirrors BEM dashboard & create club screen) ────────────────
const _screenBackground = Color(0xFFFBFDFF);
const _softBlue         = Color(0xFFEAF4FF);
const _primaryBlue      = Color(0xFF2F80FF);
const _textNavy         = Color(0xFF101C3D);
const _mutedBlue        = Color(0xFF8093C6);
const _dividerBlue      = Color(0xFFE9EEF8);

// ── Glass card ────────────────────────────────────────────────────────────────
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

// ── Screen ────────────────────────────────────────────────────────────────────
class ClubDetailScreen extends ConsumerStatefulWidget {
  final ClubModel club;
  const ClubDetailScreen({super.key, required this.club});

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen> {
  bool _loadingJoin = false;

  Future<void> _toggleJoin(bool isMember) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _loadingJoin = true);
    try {
      final service = ref.read(clubServiceProvider);
      if (isMember) {
        await service.leaveClub(clubId: widget.club.clubId, userId: user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _styledSnackBar('You have left the club.', isError: false),
          );
        }
      } else {
        await service.joinClub(clubId: widget.club.clubId, user: user);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _styledSnackBar('Successfully joined the club!', isError: false),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_styledSnackBar('Error: $e', isError: true));
      }
    } finally {
      if (mounted) setState(() => _loadingJoin = false);
    }
  }

  SnackBar _styledSnackBar(String message, {required bool isError}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showAttendanceDetail(BuildContext context, Map<String, dynamic> data) {
    final meetings = data['meetings'] as List<Map<String, dynamic>>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: _screenBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _dividerBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              const Text(
                'Attendance Detail',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(data['percentage'] as double).toStringAsFixed(1)}% · '
                '${data['attended']} of ${data['totalMeetings']} meetings attended',
                style: const TextStyle(color: _mutedBlue, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Divider(color: _dividerBlue),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: meetings.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _dividerBlue),
                  itemBuilder: (_, index) {
                    final m = meetings[index];
                    final date = m['date'] as DateTime;
                    final attended = m['attended'] as bool;
                    final color =
                        attended ? const Color(0xFF10B981) : Colors.red;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              attended
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                              color: color,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _textNavy,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(
                                    color: _mutedBlue,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              attended ? 'Hadir' : 'Tidak Hadir',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final members = ref.watch(clubMembersProvider(widget.club.clubId));
    final isBod = user != null && widget.club.bod.isBod(user.uid);
    final isMember =
        members.valueOrNull?.any((m) => m.userId == user?.uid) ?? false;

    final attendanceParams = user == null
        ? null
        : AttendanceParams(
            clubId: widget.club.clubId,
            cycleId: widget.club.cycleId,
            userId: user.uid,
          );

    final attendanceAsync = attendanceParams != null
        ? ref.watch(attendanceDataProvider(attendanceParams))
        : null;

    return Scaffold(
      backgroundColor: _screenBackground,
      appBar: AppBar(
        backgroundColor: _screenBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: _textNavy),
        title: Text(
          widget.club.name,
          style: const TextStyle(
            color: _textNavy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _primaryBlue,
        onRefresh: () async {
          if (attendanceParams != null) {
            ref.invalidate(attendanceDataProvider(attendanceParams));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Hero card: logo + name + status ─────────────────────
              _GlassCard(
                gradient: LinearGradient(
                  colors: [
                    _primaryBlue.withValues(alpha: 0.09),
                    _softBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: _primaryBlue.withValues(alpha: 0.18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 28, horizontal: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white,
                        backgroundImage: widget.club.logoUrl != null
                            ? NetworkImage(widget.club.logoUrl!)
                            : null,
                        child: widget.club.logoUrl == null
                            ? Text(
                                widget.club.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryBlue,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.club.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _textNavy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _StatusChip(status: widget.club.status),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Attendance card (member only) ────────────────────────
              if (isMember && !isBod && attendanceAsync != null)
                attendanceAsync.when(
                  loading: () => _GlassCard(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _primaryBlue),
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (data) {
                    final percentage = data['percentage'] as double;
                    final attended = data['attended'] as int;
                    final total = data['totalMeetings'] as int;
                    final isGood = percentage >= 75;
                    final color =
                        isGood ? const Color(0xFF10B981) : Colors.red;

                    return _GlassCard(
                      margin: const EdgeInsets.only(bottom: 20),
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.08),
                          color.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderColor: color.withValues(alpha: 0.2),
                      child: InkWell(
                        onTap: () =>
                            _showAttendanceDetail(context, data),
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          color.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.how_to_reg_rounded,
                                        color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'My Attendance',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _mutedBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 1),
                                        Text(
                                          'Tap to see full breakdown',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _mutedBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: color),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '$attended / $total meetings',
                                      style: const TextStyle(
                                        color: _mutedBlue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor:
                                      color.withValues(alpha: 0.15),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // ── Info card ────────────────────────────────────────────
              _GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.description_rounded,
                        label: 'Description',
                        value: widget.club.description,
                      ),
                      const Divider(height: 1, color: _dividerBlue),
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: 'Meeting',
                        value:
                            'Every ${widget.club.meetingDay} at ${widget.club.meetingTime}',
                      ),
                      const Divider(height: 1, color: _dividerBlue),
                      _InfoRow(
                        icon: Icons.room_rounded,
                        label: 'Room',
                        value: widget.club.roomNumber,
                      ),
                      const Divider(height: 1, color: _dividerBlue),
                      _InfoRow(
                        icon: Icons.people_rounded,
                        label: 'Members',
                        value: '${widget.club.memberCount} students',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Join / Leave button ──────────────────────────────────
              if (!isBod)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _loadingJoin ? null : () => _toggleJoin(isMember),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMember
                          ? Colors.red.withValues(alpha: 0.1)
                          : _primaryBlue,
                      foregroundColor:
                          isMember ? Colors.red : Colors.white,
                      disabledBackgroundColor: isMember
                          ? Colors.red.withValues(alpha: 0.06)
                          : _primaryBlue.withValues(alpha: 0.4),
                      elevation: 0,
                      side: isMember
                          ? BorderSide(
                              color: Colors.red.withValues(alpha: 0.3))
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loadingJoin
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  isMember ? Colors.red : Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isMember
                                    ? Icons.exit_to_app_rounded
                                    : Icons.add_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isMember ? 'Leave Club' : 'Join Club',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info row (inside card, no own border) ─────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _softBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: _primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _mutedBlue,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textNavy,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final ClubStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    const colorMap = {
      ClubStatus.active:    Color(0xFF10B981),
      ClubStatus.pending:   Color(0xFFF59E0B),
      ClubStatus.expired:   _mutedBlue,
      ClubStatus.suspended: Color(0xFFEF4444),
    };
    const labelMap = {
      ClubStatus.active:    'Active',
      ClubStatus.pending:   'Pending Review',
      ClubStatus.expired:   'Expired',
      ClubStatus.suspended: 'Suspended',
    };
    final color = colorMap[status] ?? _mutedBlue;
    final label = labelMap[status] ?? status.name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}