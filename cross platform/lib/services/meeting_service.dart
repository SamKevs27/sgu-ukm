import 'package:campus_club/models/attendance_model.dart';
import 'package:campus_club/models/feed_model.dart';
import 'package:campus_club/models/meeting_model.dart';
import 'package:campus_club/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class MeetingService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Streams ───────────────────────────────────────────────

  Stream<List<MeetingModel>> watchClubMeetings(String clubId) {
    return _db
        .collection('clubs')
        .doc(clubId)
        .collection('meetings')
        .snapshots()
        .map((s) {
          final meetings = s.docs.map(MeetingModel.fromFirestore).toList();
          meetings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return meetings;
        });
  }

  Stream<List<AttendanceModel>> watchMeetingAttendance(
      String clubId, String meetingId) {
    return _db
        .collection('clubs')
        .doc(clubId)
        .collection('meetings')
        .doc(meetingId)
        .collection('attendance')
        .snapshots()
        .map((s) {
          final list = s.docs.map(AttendanceModel.fromFirestore).toList();
          list.sort((a, b) => a.markedAt.compareTo(b.markedAt));
          return list;
        });
  }

  Stream<List<FeedModel>> watchFeed() {
    return _db
        .collection('feed')
        .snapshots()
        .map((s) {
          final items = s.docs.map(FeedModel.fromFirestore).toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // ─── Actions ───────────────────────────────────────────────

  /// BoD creates a new meeting — auto-generates QR token
  Future<MeetingModel> createMeeting({
    required String clubId,
    required String cycleId,
    required String title,
    required String createdBy,
    int qrValidMinutes = 30,
  }) async {
    final ref = _db
        .collection('clubs')
        .doc(clubId)
        .collection('meetings')
        .doc();

    final meeting = MeetingModel(
      meetingId: ref.id,
      clubId: clubId,
      cycleId: cycleId,
      title: title,
      photoUrls: [],
      qrToken: _uuid.v4(),
      qrExpiresAt:
          DateTime.now().add(Duration(minutes: qrValidMinutes)),
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await ref.set(meeting.toFirestore());
    return meeting;
  }

  /// Mark attendance via QR scan
  Future<void> markAttendanceByQr({
    required String clubId,
    required String meetingId,
    required String qrToken,
    required UserModel user,
  }) async {
    // Verify token
    final meetingDoc = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('meetings')
        .doc(meetingId)
        .get();

    if (!meetingDoc.exists) throw Exception('Meeting not found.');

    final meeting = MeetingModel.fromFirestore(meetingDoc);

    if (meeting.qrToken != qrToken) {
      throw Exception('Invalid QR code.');
    }
    if (!meeting.isQrActive) {
      throw Exception('QR code has expired.');
    }

    await _markAttendance(
        clubId: clubId,
        meetingId: meetingId,
        user: user,
        method: AttendanceMethod.qr);
  }

  /// BoD manually marks attendance
  Future<void> markAttendanceManually({
    required String clubId,
    required String meetingId,
    required UserModel user,
  }) =>
      _markAttendance(
          clubId: clubId,
          meetingId: meetingId,
          user: user,
          method: AttendanceMethod.manual);

  Future<void> _markAttendance({
    required String clubId,
    required String meetingId,
    required UserModel user,
    required AttendanceMethod method,
  }) async {
    final ref = _db
        .collection('clubs')
        .doc(clubId)
        .collection('meetings')
        .doc(meetingId)
        .collection('attendance')
        .doc(user.uid);

    final existing = await ref.get();
    if (existing.exists) throw Exception('Already marked as present.');

    await ref.set({
      'userId': user.uid,
      'name': user.name,
      'nim': user.nim,
      'markedAt': Timestamp.fromDate(DateTime.now()),
      'method': method.name,
    });
  }

  /// BoD updates meeting description + photos
  Future<void> updateMeeting({
    required String clubId,
    required String meetingId,
    String? description,
    List<String>? photoUrls,
  }) async {
    final updates = <String, dynamic>{};
    if (description != null) updates['description'] = description;
    if (photoUrls != null) updates['photoUrls'] = photoUrls;

    await _db
        .collection('clubs')
        .doc(clubId)
        .collection('meetings')
        .doc(meetingId)
        .update(updates);
  }

  /// Publish meeting to feed
  Future<void> publishToFeed({
    required String clubId,
    required String clubName,
    required String meetingId,
    required String description,
    required List<String> photoUrls,
    String? clubLogoUrl,
  }) async {
    final ref = _db.collection('feed').doc();
    await ref.set({
      'clubId': clubId,
      'clubName': clubName,
      'clubLogoUrl': clubLogoUrl,
      'meetingId': meetingId,
      'description': description,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}