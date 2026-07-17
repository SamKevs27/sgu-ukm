// lib/models/club_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ClubStatus { pending, active, expired, suspended }

class BodModel extends Equatable {
  final String headId;
  final String? viceId;
  final String? treasurerId;
  final String? secretaryId;

  const BodModel({
    required this.headId,
    this.viceId,
    this.treasurerId,
    this.secretaryId,
  });

  factory BodModel.fromMap(Map<String, dynamic> map) => BodModel(
        headId: map['headId'] ?? '',
        viceId: map['viceId'],
        treasurerId: map['treasurerId'],
        secretaryId: map['secretaryId'],
      );

  Map<String, dynamic> toMap() => {
        'headId': headId,
        'viceId': viceId,
        'treasurerId': treasurerId,
        'secretaryId': secretaryId,
      };

  /// Returns all non-null BoD user IDs
  List<String> get allIds => [
        headId,
        if (viceId != null) viceId!,
        if (treasurerId != null) treasurerId!,
        if (secretaryId != null) secretaryId!,
      ];

  bool isBod(String userId) => allIds.contains(userId);

  BodModel copyWith({
    String? headId,
    String? viceId,
    String? treasurerId,
    String? secretaryId,
  }) =>
      BodModel(
        headId: headId ?? this.headId,
        viceId: viceId ?? this.viceId,
        treasurerId: treasurerId ?? this.treasurerId,
        secretaryId: secretaryId ?? this.secretaryId,
      );

  @override
  List<Object?> get props => [headId, viceId, treasurerId, secretaryId];
}

class ClubModel extends Equatable {
  final String clubId;
  final String cycleId;
  final String name;
  final String description;
  final String? logoUrl;
  final String meetingDay;
  final String meetingTime;
  final String roomNumber;
  final ClubStatus status;
  final BodModel bod;
  final int memberCount;
  final String createdBy;
  final DateTime createdAt;

  const ClubModel({
    required this.clubId,
    required this.cycleId,
    required this.name,
    required this.description,
    this.logoUrl,
    required this.meetingDay,
    required this.meetingTime,
    required this.roomNumber,
    required this.status,
    required this.bod,
    required this.memberCount,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isActive => status == ClubStatus.active;
  bool get isPending => status == ClubStatus.pending;

  factory ClubModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClubModel(
      clubId: doc.id,
      cycleId: data['cycleId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      meetingDay: data['meetingDay'] ?? '',
      meetingTime: data['meetingTime'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      status: ClubStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ClubStatus.pending,
      ),
      bod: BodModel.fromMap(data['bod'] ?? {}),
      memberCount: data['memberCount'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'cycleId': cycleId,
        'name': name,
        'description': description,
        'logoUrl': logoUrl,
        'meetingDay': meetingDay,
        'meetingTime': meetingTime,
        'roomNumber': roomNumber,
        'status': status.name,
        'bod': bod.toMap(),
        'memberCount': memberCount,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  ClubModel copyWith({
    String? name,
    String? description,
    String? logoUrl,
    String? meetingDay,
    String? meetingTime,
    String? roomNumber,
    ClubStatus? status,
    BodModel? bod,
    int? memberCount,
  }) =>
      ClubModel(
        clubId: clubId,
        cycleId: cycleId,
        name: name ?? this.name,
        description: description ?? this.description,
        logoUrl: logoUrl ?? this.logoUrl,
        meetingDay: meetingDay ?? this.meetingDay,
        meetingTime: meetingTime ?? this.meetingTime,
        roomNumber: roomNumber ?? this.roomNumber,
        status: status ?? this.status,
        bod: bod ?? this.bod,
        memberCount: memberCount ?? this.memberCount,
        createdBy: createdBy,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [clubId, cycleId, name, status, memberCount];
}