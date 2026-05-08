import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AttendanceMethod { qr, manual }

class AttendanceModel extends Equatable {
  final String userId;
  final String name;
  final String nim;
  final DateTime markedAt;
  final AttendanceMethod method;

  const AttendanceModel({
    required this.userId,
    required this.name,
    required this.nim,
    required this.markedAt,
    required this.method,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      userId: doc.id,
      name: data['name'] ?? '',
      nim: data['nim'] ?? '',
      markedAt: (data['markedAt'] as Timestamp).toDate(),
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