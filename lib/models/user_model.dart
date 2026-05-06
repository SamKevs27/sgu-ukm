// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { student, bem }

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String nim;
  final UserRole role;
  final String? photoUrl;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.nim,
    required this.role,
    this.photoUrl,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      nim: data['nim'] ?? '',
      role: data['role'] == 'bem' ? UserRole.bem : UserRole.student,
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'nim': nim,
        'role': role.name,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? name,
    String? photoUrl,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        nim: nim,
        role: role,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [uid, name, email, nim, role, photoUrl];
}