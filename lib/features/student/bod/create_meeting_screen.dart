// lib/features/student/bod/create_meeting_screen.dart
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/providers/cycle_provider.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Shared design tokens (mirrors CreateClubScreen) ───────────────────────────
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

  const _GlassCard({required this.child, this.gradient, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
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

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textNavy,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: _mutedBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Themed input decoration ───────────────────────────────────────────────────
InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _mutedBlue, fontWeight: FontWeight.w500),
    prefixIcon: Icon(icon, color: _mutedBlue, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _dividerBlue),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _dividerBlue),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
    ),
  );
}

// ── QR duration option ────────────────────────────────────────────────────────
class _DurationOption extends StatelessWidget {
  final int minutes;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationOption({
    required this.minutes,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _primaryBlue : _dividerBlue,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.qr_code_rounded,
              size: 22,
              color: selected ? Colors.white : _mutedBlue,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _mutedBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────
class CreateMeetingScreen extends ConsumerStatefulWidget {
  final ClubModel club;
  const CreateMeetingScreen({super.key, required this.club});

  @override
  ConsumerState<CreateMeetingScreen> createState() =>
      _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends ConsumerState<CreateMeetingScreen> {
  final _titleController = TextEditingController();
  int _qrMinutes = 30;
  bool _loading = false;
  String? _error;

  static const _durations = [
    (minutes: 15, label: '15 min'),
    (minutes: 30, label: '30 min'),
    (minutes: 60, label: '1 hour'),
    (minutes: 120, label: '2 hours'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a meeting title.');
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    final cycle = ref.read(activeCycleProvider).valueOrNull;

    if (user == null || cycle == null) {
      setState(() => _error = 'Missing user or active cycle info.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(meetingServiceProvider).createMeeting(
            clubId: widget.club.clubId,
            cycleId: cycle.cycleId,
            title: _titleController.text.trim(),
            createdBy: user.uid,
            qrValidMinutes: _qrMinutes,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycle = ref.watch(activeCycleProvider).valueOrNull;

    return Scaffold(
      backgroundColor: _screenBackground,
      appBar: AppBar(
        backgroundColor: _screenBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: _textNavy),
        title: const Text(
          'New Meeting',
          style: TextStyle(
            color: _textNavy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Club context banner ──────────────────────────────────────
            _GlassCard(
              gradient: LinearGradient(
                colors: [
                  _primaryBlue.withValues(alpha: 0.11),
                  _softBlue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderColor: _primaryBlue.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups_rounded,
                          color: _primaryBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Creating meeting for',
                            style: TextStyle(
                              fontSize: 11,
                              color: _mutedBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.club.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _textNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (cycle != null)
                            Text(
                              cycle.name,
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
              ),
            ),

            const SizedBox(height: 28),

            // ── Meeting details ──────────────────────────────────────────
            const _SectionHeader(
              title: 'Meeting Details',
              subtitle: 'Give this session a clear title',
            ),
            _GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                      color: _textNavy, fontWeight: FontWeight.w600),
                  decoration: _inputDecoration(
                    label: 'Meeting Title *',
                    icon: Icons.title_rounded,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── QR validity ──────────────────────────────────────────────
            const _SectionHeader(
              title: 'QR Code Validity',
              subtitle: 'How long should the attendance QR stay active?',
            ),
            _GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Duration grid
                    Row(
                      children: _durations
                          .map((d) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: d.minutes != _durations.last.minutes ? 10 : 0,
                                  ),
                                  child: _DurationOption(
                                    minutes: d.minutes,
                                    label: d.label,
                                    selected: _qrMinutes == d.minutes,
                                    onTap: () => setState(() => _qrMinutes = d.minutes),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 16),

                    // Info row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _softBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: _primaryBlue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'A QR code is generated automatically when the meeting starts. '
                              'Students must scan within the selected window.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _mutedBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Error message ────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 16),
              _GlassCard(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.08),
                    Colors.red.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: Colors.red.withValues(alpha: 0.25),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Submit button ────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_loading || cycle == null) ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  disabledBackgroundColor:
                      _primaryBlue.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Create Meeting & Generate QR',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}