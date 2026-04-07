enum UserRole { admin, operator, user }

class Club {
  Club({required this.id, required this.name, required this.description});

  final String id;
  String name;
  String description;
}

class BoardMember {
  BoardMember({required this.id, required this.clubId, required this.name, required this.position});

  final String id;
  final String clubId;
  String name;
  String position;
}

class FeedPost {
  FeedPost({
    required this.id,
    required this.clubId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String clubId;
  final String author;
  final String content;
  final DateTime createdAt;
}

enum ApplicationStatus { pending, approved, rejected }

class JoinRequest {
  JoinRequest({
    required this.id,
    required this.clubId,
    required this.studentName,
    required this.status,
  });

  final String id;
  final String clubId;
  final String studentName;
  ApplicationStatus status;
}

class ClubStats {
  ClubStats({required this.clubId, required this.attendance, required this.certificates, required this.activities});

  final String clubId;
  final int attendance;
  final int certificates;
  final int activities;
}
