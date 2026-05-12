// lib/features/student/bod/meeting_detail_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:campus_club/models/attendance_model.dart';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/meeting_model.dart';
import 'package:campus_club/models/user_model.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:campus_club/services/storage_service.dart';
import 'package:campus_club/utils/iterable_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _screenBackground = Color(0xFFFBFDFF);
const _softBlue         = Color(0xFFEAF4FF);
const _primaryBlue      = Color(0xFF2F80FF);
const _textNavy         = Color(0xFF101C3D);
const _mutedBlue        = Color(0xFF8093C6);
const _dividerBlue      = Color(0xFFE9EEF8);
const _green            = Color(0xFF10B981);
const _red              = Color(0xFFEF4444);

// ── Glass Card ────────────────────────────────────────────────────────────────
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

// ── Chip pill ─────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
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
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class MeetingDetailScreen extends ConsumerStatefulWidget {
  final MeetingModel meeting;
  final ClubModel club;
  const MeetingDetailScreen(
      {super.key, required this.meeting, required this.club});

  @override
  ConsumerState<MeetingDetailScreen> createState() =>
      _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen> {
  final _descController = TextEditingController();
  bool _uploadingPhoto = false;
  bool _savingDesc = false;
  bool _publishing = false;
  final Set<String> _attendanceToggleBusy = {};

  @override
  void initState() {
    super.initState();
    _descController.text = widget.meeting.description ?? '';
  }

  String get _qrData => jsonEncode({
        'clubId': widget.club.clubId,
        'meetingId': widget.meeting.meetingId,
        'token': widget.meeting.qrToken,
      });

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await StorageService().uploadMeetingPhoto(
        File(picked.path),
        widget.club.clubId,
        widget.meeting.meetingId,
      );
      final current = List<String>.from(widget.meeting.photoUrls);
      current.add(url);
      await ref.read(meetingServiceProvider).updateMeeting(
            clubId: widget.club.clubId,
            meetingId: widget.meeting.meetingId,
            photoUrls: current,
          );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _saveDescription() async {
    setState(() => _savingDesc = true);
    try {
      await ref.read(meetingServiceProvider).updateMeeting(
            clubId: widget.club.clubId,
            meetingId: widget.meeting.meetingId,
            description: _descController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _green,
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Notes saved!',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDesc = false);
    }
  }

  Future<void> _publishToFyp() async {
    final description = _descController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _red,
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Add a description before publishing.',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Publish to FYP?',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 16, color: _textNavy),
        ),
        content: const Text(
          'This will post the meeting highlights to everyone\'s feed.',
          style: TextStyle(color: _mutedBlue, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _mutedBlue, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _primaryBlue),
            child: const Text('Publish',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _publishing = true);
    try {
      await ref.read(meetingServiceProvider).publishToFeed(
            clubId: widget.club.clubId,
            clubName: widget.club.name,
            meetingId: widget.meeting.meetingId,
            description: description,
            photoUrls: widget.meeting.photoUrls,
            clubLogoUrl: widget.club.logoUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _green,
            content: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Published to FYP!',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _red,
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    final attendanceAsync = ref.watch(meetingAttendanceProvider(
        (clubId: widget.club.clubId, meetingId: widget.meeting.meetingId)));
    final membersAsync = ref.watch(clubMembersProvider(widget.club.clubId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _screenBackground,

        // ── App bar ──────────────────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: const Color(0xFF1B4A7A).withValues(alpha: 0.08),
          elevation: 1,
          iconTheme: const IconThemeData(color: _textNavy),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.meeting.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textNavy,
                ),
              ),
              Text(
                fmt.format(widget.meeting.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: _mutedBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _dividerBlue)),
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
                  Tab(icon: Icon(Icons.qr_code_rounded, size: 18), text: 'QR Code'),
                  Tab(icon: Icon(Icons.how_to_reg_rounded, size: 18), text: 'Attendance'),
                  Tab(icon: Icon(Icons.photo_library_rounded, size: 18), text: 'Photos'),
                ],
              ),
            ),
          ),
        ),

        body: TabBarView(
          children: [
            // ────────────────────────────────────────────────────────────────
            // QR Tab  (notes removed — moved to Photos tab)
            // ────────────────────────────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status pill
                  Center(
                    child: widget.meeting.isQrActive
                        ? _Pill(
                            icon: Icons.timer_rounded,
                            label:
                                'Expires ${fmt.format(widget.meeting.qrExpiresAt!)}',
                            color: _green,
                          )
                        : const _Pill(
                            icon: Icons.timer_off_rounded,
                            label: 'QR Expired',
                            color: _red,
                          ),
                  ),
                  const SizedBox(height: 24),

                  // QR code card
                  Center(
                    child: _GlassCard(
                      gradient: LinearGradient(
                        colors: [
                          _primaryBlue.withValues(alpha: 0.06),
                          _softBlue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderColor: _primaryBlue.withValues(alpha: 0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: _textNavy,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: _textNavy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ────────────────────────────────────────────────────────────────
            // Attendance Tab
            // ────────────────────────────────────────────────────────────────
            attendanceAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _primaryBlue)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: _red))),
              data: (attendance) {
                final members = membersAsync.valueOrNull ?? [];
                final presentCount = attendance.length;

                return Column(
                  children: [
                    // Stat bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Present',
                                  value: presentCount,
                                  icon: Icons.check_circle_rounded,
                                  color: _green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  label: 'Total Members',
                                  value: members.length,
                                  icon: Icons.people_rounded,
                                  color: _primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Toggle the switch to manually mark a member present.',
                            style: TextStyle(
                              fontSize: 11,
                              color: _mutedBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: _dividerBlue),

                    // Member list
                    Expanded(
                      child: members.isEmpty
                          ? const Center(
                              child: Text('No members yet.',
                                  style: TextStyle(color: _mutedBlue)))
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 16, 20, 32),
                              itemCount: members.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final member = members[i];
                                final present = attendance
                                    .any((a) => a.userId == member.userId);
                                final record = attendance
                                    .where((a) => a.userId == member.userId)
                                    .firstOrNull;
                                final isBusy = _attendanceToggleBusy
                                    .contains(member.userId);

                                return _GlassCard(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: present
                                              ? _green.withValues(alpha: 0.15)
                                              : _softBlue,
                                          child: Icon(
                                            present
                                                ? Icons.check_rounded
                                                : Icons.person_rounded,
                                            color: present
                                                ? _green
                                                : _mutedBlue,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                              Row(
                                                children: [
                                                  _Pill(
                                                    icon: Icons.badge_outlined,
                                                    label: member.nim,
                                                    color: _mutedBlue,
                                                  ),
                                                  if (present) ...[
                                                    const SizedBox(width: 6),
                                                    _Pill(
                                                      icon: record?.method ==
                                                              AttendanceMethod
                                                                  .qr
                                                          ? Icons.qr_code_rounded
                                                          : Icons.edit_rounded,
                                                      label: record?.method ==
                                                              AttendanceMethod
                                                                  .qr
                                                          ? 'QR'
                                                          : 'Manual',
                                                      color: record?.method ==
                                                              AttendanceMethod
                                                                  .qr
                                                          ? _primaryBlue
                                                          : const Color(
                                                              0xFFF59E0B),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        isBusy
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: _primaryBlue,
                                                ),
                                              )
                                            : Switch.adaptive(
                                                value: present,
                                                activeColor: _green,
                                                onChanged: (wantPresent) async {
                                                  setState(() =>
                                                      _attendanceToggleBusy
                                                          .add(member.userId));
                                                  try {
                                                    if (wantPresent) {
                                                      final userDoc =
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'users')
                                                              .doc(member.userId)
                                                              .get();
                                                      if (!userDoc.exists) {
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'User profile not found.'),
                                                            ),
                                                          );
                                                        }
                                                        return;
                                                      }
                                                      final user = UserModel
                                                          .fromFirestore(
                                                              userDoc);
                                                      await ref
                                                          .read(
                                                              meetingServiceProvider)
                                                          .markAttendanceManually(
                                                            clubId: widget
                                                                .club.clubId,
                                                            cycleId: widget
                                                                .meeting
                                                                .cycleId,
                                                            meetingId: widget
                                                                .meeting
                                                                .meetingId,
                                                            user: user,
                                                          );
                                                    } else {
                                                      await ref
                                                          .read(
                                                              meetingServiceProvider)
                                                          .clearAttendance(
                                                            clubId: widget
                                                                .club.clubId,
                                                            meetingId: widget
                                                                .meeting
                                                                .meetingId,
                                                            userId:
                                                                member.userId,
                                                          );
                                                    }
                                                  } catch (e) {
                                                    if (!mounted) return;
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          e
                                                              .toString()
                                                              .replaceAll(
                                                                  'Exception: ',
                                                                  ''),
                                                        ),
                                                      ),
                                                    );
                                                  } finally {
                                                    if (mounted) {
                                                      setState(() =>
                                                          _attendanceToggleBusy
                                                              .remove(
                                                                  member.userId));
                                                    }
                                                  }
                                                },
                                              ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),

            // ────────────────────────────────────────────────────────────────
            // Photos Tab  (notes + publish moved here)
            // ────────────────────────────────────────────────────────────────
            Column(
              children: [
                // Photo grid / empty state
                Expanded(
                  child: widget.meeting.photoUrls.isEmpty
                      ? Center(
                          child: _GlassCard(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 40, horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PhotoEmptyIcon(),
                                  SizedBox(height: 16),
                                  Text(
                                    'No photos yet.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: _textNavy,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Tap Add Photo to upload meeting photos.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _mutedBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: widget.meeting.photoUrls.length,
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              widget.meeting.photoUrls[i],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                ),

                // ── Bottom action panel ──────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Meeting Notes field
                        const Row(
                          children: [
                            Icon(Icons.notes_rounded,
                                size: 15, color: _primaryBlue),
                            SizedBox(width: 6),
                            Text(
                              'Meeting Notes',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: _textNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descController,
                          maxLines: 3,
                          style: const TextStyle(
                              fontSize: 14, color: _textNavy),
                          decoration: InputDecoration(
                            hintText:
                                'Add notes or description for this meeting…',
                            hintStyle: const TextStyle(
                                color: _mutedBlue, fontSize: 13),
                            filled: true,
                            fillColor: _softBlue,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color:
                                      _primaryBlue.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: _dividerBlue, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: _primaryBlue, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Row: Add Photo + Save Notes
                        Row(
                          children: [
                            // Add Photo
                            Expanded(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  backgroundColor: _softBlue,
                                  foregroundColor: _primaryBlue,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _uploadingPhoto
                                    ? null
                                    : _pickAndUploadPhoto,
                                icon: _uploadingPhoto
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _primaryBlue),
                                      )
                                    : const Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 18),
                                label: const Text(
                                  'Add Photo',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Save Notes
                            Expanded(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  backgroundColor: _softBlue,
                                  foregroundColor: _primaryBlue,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    _savingDesc ? null : _saveDescription,
                                icon: _savingDesc
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _primaryBlue),
                                      )
                                    : const Icon(Icons.save_rounded,
                                        size: 18),
                                label: const Text(
                                  'Save Notes',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Publish to FYP — full-width primary button
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _publishing ? null : _publishToFyp,
                          icon: _publishing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(
                                  Icons.auto_awesome_rounded, size: 18),
                          label: const Text(
                            'Publish to FYP',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo empty icon helper ───────────────────────────────────────────────────
class _PhotoEmptyIcon extends StatelessWidget {
  const _PhotoEmptyIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.photo_library_rounded,
          size: 36, color: _primaryBlue),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _mutedBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}