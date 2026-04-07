import 'package:flutter/material.dart';

import '../models/app_models.dart';

class AppState extends ChangeNotifier {
  final List<Club> clubs = [
    Club(id: 'club_1', name: 'Modern Dance Club', description: 'Contemporary and K-Pop choreography practice every week.'),
    Club(id: 'club_2', name: 'Choir Club', description: 'Vocal harmony training for campus and external performances.'),
    Club(id: 'club_3', name: 'Debate Society', description: 'English and Bahasa debate training with tournaments.'),
  ];

  final List<BoardMember> bodMembers = [
    BoardMember(id: 'bod_1', clubId: 'club_1', name: 'Alya Santoso', position: 'President'),
    BoardMember(id: 'bod_2', clubId: 'club_1', name: 'Rafi Pratama', position: 'Vice President'),
    BoardMember(id: 'bod_3', clubId: 'club_2', name: 'Nadia Kristina', position: 'Conductor'),
  ];

  final List<FeedPost> feeds = [
    FeedPost(
      id: 'feed_1',
      clubId: 'club_1',
      author: 'Modern Dance BoD',
      content: 'Audition week starts Monday at Hall A. Bring your own playlist snippet.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    FeedPost(
      id: 'feed_2',
      clubId: 'club_2',
      author: 'Choir BoD',
      content: 'Warm-up clinic this Friday 17:00. Open for all SGU students.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<JoinRequest> joinRequests = [
    JoinRequest(id: 'req_1', clubId: 'club_1', studentName: 'Kevin', status: ApplicationStatus.pending),
    JoinRequest(id: 'req_2', clubId: 'club_2', studentName: 'Michelle', status: ApplicationStatus.pending),
    JoinRequest(id: 'req_3', clubId: 'club_3', studentName: 'Kevin', status: ApplicationStatus.approved),
  ];

  final List<ClubStats> userStats = [
    ClubStats(clubId: 'club_3', attendance: 16, certificates: 2, activities: 5),
  ];

  final Set<String> operatorClubIds = {'club_1', 'club_2'};

  String clubName(String id) => clubs.firstWhere((club) => club.id == id).name;

  void addClub(String name, String description) {
    clubs.add(Club(id: 'club_${clubs.length + 1}_${DateTime.now().millisecondsSinceEpoch}', name: name, description: description));
    notifyListeners();
  }

  void updateClub(String id, String name, String description) {
    final club = clubs.firstWhere((c) => c.id == id);
    club.name = name;
    club.description = description;
    notifyListeners();
  }

  void deleteClub(String id) {
    clubs.removeWhere((c) => c.id == id);
    bodMembers.removeWhere((m) => m.clubId == id);
    feeds.removeWhere((f) => f.clubId == id);
    joinRequests.removeWhere((r) => r.clubId == id);
    userStats.removeWhere((s) => s.clubId == id);
    operatorClubIds.remove(id);
    notifyListeners();
  }

  void addBodMember(String clubId, String name, String position) {
    bodMembers.add(
      BoardMember(
        id: 'bod_${bodMembers.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
        clubId: clubId,
        name: name,
        position: position,
      ),
    );
    notifyListeners();
  }

  void updateBodMember(String id, String name, String position) {
    final member = bodMembers.firstWhere((m) => m.id == id);
    member.name = name;
    member.position = position;
    notifyListeners();
  }

  void deleteBodMember(String id) {
    bodMembers.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void postFeed({required String clubId, required String author, required String content}) {
    feeds.insert(
      0,
      FeedPost(
        id: 'feed_${feeds.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
        clubId: clubId,
        author: author,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void applyToClub({required String studentName, required String clubId}) {
    final exists = joinRequests.any((r) => r.studentName == studentName && r.clubId == clubId);
    if (exists) {
      return;
    }
    joinRequests.add(
      JoinRequest(
        id: 'req_${joinRequests.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
        clubId: clubId,
        studentName: studentName,
        status: ApplicationStatus.pending,
      ),
    );
    notifyListeners();
  }

  void updateRequestStatus(String requestId, ApplicationStatus status) {
    final request = joinRequests.firstWhere((r) => r.id == requestId);
    request.status = status;
    final alreadyInStats = userStats.any((s) => s.clubId == request.clubId);
    if (status == ApplicationStatus.approved && !alreadyInStats) {
      userStats.add(ClubStats(clubId: request.clubId, attendance: 0, certificates: 0, activities: 0));
    }
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState notifier, required super.child}) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }
}
