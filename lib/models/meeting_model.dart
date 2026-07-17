// lib/models/meeting_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MeetingModel extends Equatable {
  final String meetingId;
  final String clubId;
  final String cycleId;
  final String title;
  final String? description;
  final List<String> photoUrls;
  final String qrToken;       // UUID used to validate QR scans
  final DateTime? qrExpiresAt;
  final String createdBy;
  final DateTime createdAt;

  const MeetingModel({
    required this.meetingId,
    required this.clubId,
    required this.cycleId,
    required this.title,
    this.description,
    required this.photoUrls,
    required this.qrToken,
    this.qrExpiresAt,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isQrActive =>
      qrExpiresAt != null && DateTime.now().isBefore(qrExpiresAt!);

  factory MeetingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingModel(
      meetingId: doc.id,
      clubId: data['clubId'] ?? '',
      cycleId: data['cycleId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      qrToken: data['qrToken'] ?? '',
      qrExpiresAt: data['qrExpiresAt'] != null
          ? (data['qrExpiresAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clubId': clubId,
        'cycleId': cycleId,
        'title': title,
        'description': description,
        'photoUrls': photoUrls,
        'qrToken': qrToken,
        'qrExpiresAt':
            qrExpiresAt != null ? Timestamp.fromDate(qrExpiresAt!) : null,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  MeetingModel copyWith({
    String? title,
    String? description,
    List<String>? photoUrls,
    DateTime? qrExpiresAt,
  }) =>
      MeetingModel(
        meetingId: meetingId,
        clubId: clubId,
        cycleId: cycleId,
        title: title ?? this.title,
        description: description ?? this.description,
        photoUrls: photoUrls ?? this.photoUrls,
        qrToken: qrToken,
        qrExpiresAt: qrExpiresAt ?? this.qrExpiresAt,
        createdBy: createdBy,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [meetingId, clubId, title, qrToken];
}