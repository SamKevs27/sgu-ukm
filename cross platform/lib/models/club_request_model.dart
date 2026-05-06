// lib/models/club_request_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RequestType { create, renew, update }
enum RequestStatus { pending, approved, rejected }

class ClubRequestModel extends Equatable {
  final String requestId;
  final String clubId;
  final RequestType type;
  final RequestStatus status;
  final String requestedBy;
  final String? reviewedBy;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const ClubRequestModel({
    required this.requestId,
    required this.clubId,
    required this.type,
    required this.status,
    required this.requestedBy,
    this.reviewedBy,
    this.reviewNote,
    required this.createdAt,
    this.reviewedAt,
  });

  factory ClubRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClubRequestModel(
      requestId: doc.id,
      clubId: data['clubId'] ?? '',
      type: RequestType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RequestType.create,
      ),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      requestedBy: data['requestedBy'] ?? '',
      reviewedBy: data['reviewedBy'],
      reviewNote: data['reviewNote'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clubId': clubId,
        'type': type.name,
        'status': status.name,
        'requestedBy': requestedBy,
        'reviewedBy': reviewedBy,
        'reviewNote': reviewNote,
        'createdAt': Timestamp.fromDate(createdAt),
        'reviewedAt':
            reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      };

  @override
  List<Object?> get props => [requestId, clubId, type, status];
}