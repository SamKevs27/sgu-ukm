import 'dart:convert';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/meeting_model.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:campus_club/services/meeting_service.dart';
import 'package:campus_club/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'package:campus_club/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingDetailScreen extends ConsumerStatefulWidget {
  final MeetingModel meeting;
  final ClubModel club;
  const MeetingDetailScreen(
      {super.key, required this.meeting, required this.club});

  @override
  ConsumerState<MeetingDetailScreen> createState() =>
      _MeetingDetailScreenState();
}

class _MeetingDetailScreenState
    extends ConsumerState<MeetingDetailScreen> {
  final _descController = TextEditingController();
  bool _uploadingPhoto = false;
  bool _savingDesc = false;

  @override
  void initState() {
    super.initState();
    _descController.text = widget.meeting.description ?? '';
  }

  // QR payload: encoded as JSON with clubId + meetingId + token
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
          const SnackBar(content: Text('Description saved!')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDesc = false);
    }
  }

  Future<void> _publishToFeed() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add a description before publishing.')),
      );
      return;
    }
    await ref.read(meetingServiceProvider).publishToFeed(
          clubId: widget.club.clubId,
          clubName: widget.club.name,
          meetingId: widget.meeting.meetingId,
          description: _descController.text.trim(),
          photoUrls: widget.meeting.photoUrls,
          clubLogoUrl: widget.club.logoUrl,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Published to FYP feed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    final attendanceAsync = ref.watch(meetingAttendanceProvider(
        (clubId: widget.club.clubId,
         meetingId: widget.meeting.meetingId)));
    final membersAsync =
        ref.watch(clubMembersProvider(widget.club.clubId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.meeting.title),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.qr_code_rounded), text: 'QR Code'),
              Tab(icon: Icon(Icons.how_to_reg_rounded), text: 'Attendance'),
              Tab(icon: Icon(Icons.photo_library_rounded), text: 'Photos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── QR Tab ──
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Created: ${fmt.format(widget.meeting.createdAt)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 8),
                  if (widget.meeting.isQrActive)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_rounded,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'QR expires: ${fmt.format(widget.meeting.qrExpiresAt!)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    )
                  else
                    const Text('QR code expired',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red)),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 220,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Description',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _savingDesc ? null : _saveDescription,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _publishToFeed,
                          icon: const Icon(Icons.public_rounded),
                          label: const Text('Publish to FYP'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Attendance Tab ──
            attendanceAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (attendance) {
                final members = membersAsync.valueOrNull ?? [];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _StatBadge(
                            label: 'Present',
                            value: attendance.length,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _StatBadge(
                            label: 'Total Members',
                            value: members.length,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: members.isEmpty
                          ? const Center(child: Text('No members yet.'))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: members.length,
                              itemBuilder: (_, i) {
                                final member = members[i];
                                final present = attendance.any(
                                    (a) => a.userId == member.userId);
                                final record = attendance
                                    .where(
                                        (a) => a.userId == member.userId)
                                    .firstOrNull;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: present
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                    child: Icon(
                                      present
                                          ? Icons.check_rounded
                                          : Icons.close_rounded,
                                      color: present
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                  title: Text(member.name),
                                  subtitle: Text('NIM: ${member.nim}'),
                                  trailing: present
                                      ? Chip(
                                          label: Text(
                                            record?.method ==
                                                    AttendanceMethod.qr
                                                ? 'QR'
                                                : 'Manual',
                                            style: const TextStyle(
                                                fontSize: 11),
                                          ),
                                          backgroundColor: Colors.green
                                              .withOpacity(0.1),
                                        )
                                      : TextButton(
                                          onPressed: () async {
                                            final userDoc =
                                                await FirebaseFirestore
                                                    .instance
                                                    .collection('users')
                                                    .doc(member.userId)
                                                    .get();
                                            final user = UserModel
                                                .fromFirestore(userDoc);
                                            await ref
                                                .read(meetingServiceProvider)
                                                .markAttendanceManually(
                                                  clubId:
                                                      widget.club.clubId,
                                                  meetingId: widget
                                                      .meeting.meetingId,
                                                  user: user,
                                                );
                                          },
                                          child: const Text('Mark'),
                                        ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),

            // ── Photos Tab ──
            Column(
              children: [
                Expanded(
                  child: widget.meeting.photoUrls.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_outlined,
                                  size: 64,
                                  color: theme.colorScheme.outline),
                              const SizedBox(height: 8),
                              const Text('No photos yet'),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: widget.meeting.photoUrls.length,
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.meeting.photoUrls[i],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed:
                        _uploadingPhoto ? null : _pickAndUploadPhoto,
                    icon: _uploadingPhoto
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Add Photo'),
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

class _StatBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}