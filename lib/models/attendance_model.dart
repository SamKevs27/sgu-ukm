import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AttendanceMethod { qr, manual }

class AttendanceModel extends Equatable {
  const AttendanceModel({
    required this.documentId,
    required this.userId,
    required this.name,
    required this.nim,
    required this.markedAt,
    required this.checkedInAt,
    required this.method,
    required this.clubId,
    required this.cycleId,
    required this.meetingId,
    required this.status,
  });

  final String documentId;
  final String userId;
  final String name;
  final String nim;
  final DateTime markedAt;
  final DateTime checkedInAt;
  final AttendanceMethod method;
  final String clubId;
  final String cycleId;
  final String meetingId;

  /// `attended` means present; any other value is treated as absent in the UI layer.
  final String status;

  bool get isAttended =>
      status.isEmpty || status == 'attended';

  factory AttendanceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Attendance document does not exist');
    }
    DateTime ts(String a, String b) {
      final t = data[a] ?? data[b];
      if (t is! Timestamp) {
        throw Exception('Missing attendance timestamp');
      }
      return t.toDate();
    }

    final methodRaw = data['method']?.toString();
    return AttendanceModel(
      documentId: doc.id,
      userId: data['userId']?.toString() ?? '',
      clubId: data['clubId']?.toString() ?? '',
      cycleId: data['cycleId']?.toString() ?? '',
      meetingId: data['meetingId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      nim: data['nim']?.toString() ?? '',
      markedAt: ts('markedAt', 'checkedInAt'),
      checkedInAt: ts('checkedInAt', 'markedAt'),
      method: methodRaw == 'qr'
          ? AttendanceMethod.qr
          : AttendanceMethod.manual,
      status: data['status']?.toString() ?? 'attended',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'nim': nim,
        'markedAt': Timestamp.fromDate(markedAt),
        'checkedInAt': Timestamp.fromDate(checkedInAt),
        'method': method.name,
        'clubId': clubId,
        'cycleId': cycleId,
        'meetingId': meetingId,
        'status': status,
      };

  @override
  List<Object?> get props =>
      [documentId, userId, markedAt, method, clubId, meetingId, status];
}
