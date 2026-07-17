// lib/models/member_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MemberModel extends Equatable {
  final String userId;
  final String name;
  final String nim;
  final DateTime joinedAt;

  const MemberModel({
    required this.userId,
    required this.name,
    required this.nim,
    required this.joinedAt,
  });

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      userId: doc.id,
      name: data['name'] ?? '',
      nim: data['nim'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'nim': nim,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  @override
  List<Object?> get props => [userId, name, nim];
}