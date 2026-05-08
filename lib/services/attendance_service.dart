import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final _db = FirebaseFirestore.instance;

  /// Watch all attendance records for a user in a specific club + cycle
  Stream<List<Map<String, dynamic>>> watchAttendanceDetail({
    required String clubId,
    required String cycleId,
    required String userId,
  }) {
    return _db
        .collection('attendance')
        .where('clubId', isEqualTo: clubId)
        .where('cycleId', isEqualTo: cycleId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  // ─── Actions ───────────────────────────────────────────────

  /// Get all meetings in a club for a cycle
  Future<List<Map<String, dynamic>>> getMeetings({
    required String clubId,
    required String cycleId,
  }) async {
    final snap = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('meetings')
        .where('cycleId', isEqualTo: cycleId)
        .get();

    final meetings = snap.docs.map((doc) {
      return {
        'meetingId': doc.id,
        'title': doc['title'] as String,
        'date': (doc['createdAt'] as Timestamp).toDate(),
      };
    }).toList();

    /* meetings.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    ); */

    // sort meeting from newest to oldest
    meetings.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    return meetings;
  }

  /// Get attendance percentage + detail for a user in a club + cycle
  Future<Map<String, dynamic>> getAttendanceData({
    required String clubId,
    required String cycleId,
    required String userId,
  }) async {
    final meetings = await getMeetings(clubId: clubId, cycleId: cycleId);

    final attendanceSnap = await _db
        .collection('attendance')
        .where('clubId', isEqualTo: clubId)
        .where('cycleId', isEqualTo: cycleId)
        .where('userId', isEqualTo: userId)
        .get();

    final attendedMeetingIds = attendanceSnap.docs
        .map((d) => d['meetingId'] as String)
        .toSet();

    final detail = meetings.map((m) {
      return {
        'title': m['title'],
        'date': m['date'],
        'attended': attendedMeetingIds.contains(m['meetingId']),
      };
    }).toList();

    final total = meetings.length;
    final attended = attendedMeetingIds.length;
    final percentage = total == 0 ? 0.0 : (attended / total) * 100;

    return {
      'totalMeetings': total,
      'attended': attended,
      'percentage': percentage,
      'meetings': detail,
    };
  }

  /// Check if a user attended a specific meeting
  Future<bool> hasAttended({
    required String clubId,
    required String meetingId,
    required String userId,
  }) async {
    final snap = await _db
        .collection('attendance')
        .where('clubId', isEqualTo: clubId)
        .where('meetingId', isEqualTo: meetingId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  /// Watch all attendance records for a specific meeting
  Stream<List<Map<String, dynamic>>> watchMeetingAttendees({
    required String clubId,
    required String meetingId,
  }) {
    return _db
        .collection('attendance')
        .where('clubId', isEqualTo: clubId)
        .where('meetingId', isEqualTo: meetingId)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  /// Watch attendance count for a meeting
  Stream<int> watchMeetingAttendanceCount({
    required String clubId,
    required String meetingId,
  }) {
    return _db
        .collection('attendance')
        .where('clubId', isEqualTo: clubId)
        .where('meetingId', isEqualTo: meetingId)
        .snapshots()
        .map((s) => s.docs.length);
  }
}
