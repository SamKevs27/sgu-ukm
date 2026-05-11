import 'package:campus_club/models/attendance_model.dart';
import 'package:campus_club/models/feed_model.dart';
import 'package:campus_club/models/meeting_model.dart';
import 'package:campus_club/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class MeetingService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  static String attendanceDocumentId(String userId, String meetingId) =>
      '${userId}_$meetingId';

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

  /// Top-level [attendance] collection (see Firestore schema).
  Stream<List<AttendanceModel>> watchMeetingAttendance(
    String clubId,
    String meetingId,
  ) {
    return _db
        .collection('attendance')
        .where('clubId', isEqualTo: clubId)
        .where('meetingId', isEqualTo: meetingId)
        .snapshots()
        .map((s) {
          final list =
              s.docs.map(AttendanceModel.fromFirestore).toList();
          list.sort((a, b) => a.checkedInAt.compareTo(b.checkedInAt));
          return list
              .where((a) => a.isAttended)
              .toList();
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

  /// Mark attendance via QR scan (students only).
  Future<void> markAttendanceByQr({
    required String clubId,
    required String meetingId,
    required String qrToken,
    required UserModel user,
  }) async {
    if (user.role != UserRole.student) {
      throw Exception('Only student accounts can check in with QR.');
    }

    final memberSnap = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('members')
        .doc(user.uid)
        .get();
    if (!memberSnap.exists) {
      throw Exception('You must join this club before checking in.');
    }

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
        cycleId: meeting.cycleId,
        meetingId: meetingId,
        user: user,
        method: AttendanceMethod.qr);
  }

  /// BoD manually marks attendance as present.
  Future<void> markAttendanceManually({
    required String clubId,
    required String cycleId,
    required String meetingId,
    required UserModel user,
  }) {
    if (user.role != UserRole.student) {
      throw Exception('Only student accounts can be marked present.');
    }
    return _markAttendance(
        clubId: clubId,
        cycleId: cycleId,
        meetingId: meetingId,
        user: user,
        method: AttendanceMethod.manual);
  }

  /// BoD clears attendance for this member at this meeting (handles legacy random doc IDs).
  Future<void> clearAttendance({
    required String clubId,
    required String meetingId,
    required String userId,
  }) async {
    final snap = await _db
        .collection('attendance')
        .where('clubId', isEqualTo: clubId)
        .where('meetingId', isEqualTo: meetingId)
        .where('userId', isEqualTo: userId)
        .get();

    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  bool _countsAsPresent(Map<String, dynamic>? data) {
    if (data == null) return false;
    final status = data['status']?.toString() ?? '';
    return status.isEmpty || status == 'attended';
  }

  Future<void> _markAttendance({
    required String clubId,
    required String cycleId,
    required String meetingId,
    required UserModel user,
    required AttendanceMethod method,
  }) async {
    final dup = await _db
        .collection('attendance')
        .where('clubId', isEqualTo: clubId)
        .where('meetingId', isEqualTo: meetingId)
        .where('userId', isEqualTo: user.uid)
        .limit(10)
        .get();

    if (dup.docs.any((d) => _countsAsPresent(d.data()))) {
      throw Exception('Already marked as present.');
    }

    final docId = attendanceDocumentId(user.uid, meetingId);
    final ref = _db.collection('attendance').doc(docId);

    final now = DateTime.now();
    await ref.set({
      'userId': user.uid,
      'clubId': clubId,
      'cycleId': cycleId,
      'meetingId': meetingId,
      'checkedInAt': Timestamp.fromDate(now),
      'markedAt': Timestamp.fromDate(now),
      'status': 'attended',
      'name': user.name,
      'nim': user.nim,
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
