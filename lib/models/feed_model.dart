import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class FeedModel extends Equatable {
  final String feedId;
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;
  final String meetingId;
  final String description;
  final List<String> photoUrls;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  const FeedModel({
    required this.feedId,
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    required this.meetingId,
    required this.description,
    required this.photoUrls,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  factory FeedModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedModel(
      feedId: doc.id,
      clubId: data['clubId'] ?? '',
      clubName: data['clubName'] ?? '',
      clubLogoUrl: data['clubLogoUrl'],
      meetingId: data['meetingId'] ?? '',
      description: data['description'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clubId': clubId,
        'clubName': clubName,
        'clubLogoUrl': clubLogoUrl,
        'meetingId': meetingId,
        'description': description,
        'photoUrls': photoUrls,
        'createdAt': Timestamp.fromDate(createdAt),
        'likeCount': likeCount,
        'commentCount': commentCount,
      };

  FeedModel copyWith({
    int? likeCount,
    int? commentCount,
  }) =>
      FeedModel(
        feedId: feedId,
        clubId: clubId,
        clubName: clubName,
        clubLogoUrl: clubLogoUrl,
        meetingId: meetingId,
        description: description,
        photoUrls: photoUrls,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
      );

  @override
  List<Object?> get props => [feedId, clubId, meetingId];
}