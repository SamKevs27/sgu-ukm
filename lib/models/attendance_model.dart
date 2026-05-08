import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AttendanceMethod { qr, manual }

class AttendanceModel extends Equatable {
  final String userId;
  final String name;
  final String nim;
  final DateTime markedAt;
  final AttendanceMethod method;
  final String clubId;
  final String cycleId;
  final String meetingId;
  final DateTime checkedInAt;
  

  const AttendanceModel({
    required this.userId,
    required this.name,
    required this.nim,
    required this.markedAt,
    required this.method,
    required this.clubId,
    required this.cycleId,
    required this.meetingId,
    required this.checkedInAt
  });

  factory AttendanceModel.fromFirestore(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();

  if (data == null) {
    throw Exception('Attendance document does not exist');
  }

  return AttendanceModel(
    userId: data['userId'] ?? '',
    clubId: data['clubId'] ?? '',
    cycleId: data['cycleId'] ?? '',
    meetingId: data['meetingId'] ?? '',
    name: data['name'] ?? '',
    nim: data['nim'] ?? '',
    markedAt: (data['markedAt'] as Timestamp).toDate(),
    checkedInAt:
          (data['checkedInAt'] as Timestamp).toDate(),
    method: data['method'] == 'qr'
        ? AttendanceMethod.qr
        : AttendanceMethod.manual,
  );
}

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'nim': nim,
        'markedAt': Timestamp.fromDate(markedAt),
        'method': method.name,
      };

  @override
  List<Object?> get props => [userId, markedAt, method];
}