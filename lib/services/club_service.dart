import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/club_request_model.dart';
import 'package:campus_club/models/member_model.dart';
import 'package:campus_club/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ClubService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Streams ───────────────────────────────────────────────

  /// All active clubs (for the browse screen)
  Stream<List<ClubModel>> watchActiveClubs() {
    return _db
        .collection('clubs')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((s) {
          final clubs = s.docs.map(ClubModel.fromFirestore).toList();
          clubs.sort((a, b) => a.name.compareTo(b.name));
          return clubs;
        });
  }

  /// Clubs where user is a member (for My Clubs tab)
  Stream<List<ClubModel>> watchMyMemberClubs(String userId) {
    return _db
        .collection('clubs')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
          final clubs = <ClubModel>[];
          for (final doc in snapshot.docs) {
            final memberDoc = await _db
                .collection('clubs')
                .doc(doc.id)
                .collection('members')
                .doc(userId)
                .get();
            if (memberDoc.exists) {
              clubs.add(ClubModel.fromFirestore(doc));
            }
          }
          return clubs;
        });
  }

  /// Clubs where user is BoD (for My BoD tab)
  Stream<List<ClubModel>> watchMyBodClubs(String userId) {
    return _db
        .collection('clubs')
        .where('bod.headId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          // Also fetch clubs where user is vice, treasurer, or secretary
          final byHead = snapshot.docs.map(ClubModel.fromFirestore).toList();

          final otherRoles = await Future.wait([
            _db
                .collection('clubs')
                .where('bod.viceId', isEqualTo: userId)
                .get(),
            _db
                .collection('clubs')
                .where('bod.treasurerId', isEqualTo: userId)
                .get(),
            _db
                .collection('clubs')
                .where('bod.secretaryId', isEqualTo: userId)
                .get(),
          ]);

          final allIds = {for (final c in byHead) c.clubId};
          final result = [...byHead];

          for (final snapshot in otherRoles) {
            for (final doc in snapshot.docs) {
              final club = ClubModel.fromFirestore(doc);
              if (!allIds.contains(club.clubId)) {
                allIds.add(club.clubId);
                result.add(club);
              }
            }
          }
          return result;
        });
  }

  /// All clubs for BEM
  Stream<List<ClubModel>> watchAllClubs() {
    return _db.collection('clubs').snapshots().map((s) {
      final clubs = s.docs.map(ClubModel.fromFirestore).toList();
      clubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return clubs;
    });
  }

  /// Members of a club
  Stream<List<MemberModel>> watchClubMembers(String clubId) {
    return _db
        .collection('clubs')
        .doc(clubId)
        .collection('members')
        .snapshots()
        .map((s) {
          final members = s.docs.map(MemberModel.fromFirestore).toList();
          members.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
          return members;
        });
  }

  /// Pending club requests for BEM
  Stream<List<ClubRequestModel>> watchPendingRequests() {
    return _db
        .collection('clubRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) {
          watchClubMembers;
          final requests = s.docs.map(ClubRequestModel.fromFirestore).toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // ─── Actions ───────────────────────────────────────────────

  /// Create a new club + submit for BEM approval
  Future<void> createClub({
    required String cycleId,
    required String name,
    required String description,
    required String meetingDay,
    required String meetingTime,
    required String roomNumber,
    required BodModel bod,
    required String createdBy,
    String? logoUrl,
  }) async {
    final clubRef = _db.collection('clubs').doc();
    final requestRef = _db.collection('clubRequests').doc();

    final club = ClubModel(
      clubId: clubRef.id,
      cycleId: cycleId,
      name: name,
      description: description,
      logoUrl: logoUrl,
      meetingDay: meetingDay,
      meetingTime: meetingTime,
      roomNumber: roomNumber,
      status: ClubStatus.pending,
      bod: bod,
      memberCount: 0,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    final request = ClubRequestModel(
      requestId: requestRef.id,
      clubId: clubRef.id,
      type: RequestType.create,
      status: RequestStatus.pending,
      requestedBy: createdBy,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(clubRef, club.toFirestore());
    batch.set(requestRef, request.toFirestore());
    await batch.commit();
  }

  /// Join a club as a member
  Future<void> joinClub({
    required String clubId,
    required UserModel user,
  }) async {
    final memberRef = _db
        .collection('clubs')
        .doc(clubId)
        .collection('members')
        .doc(user.uid);

    final batch = _db.batch();
    batch.set(memberRef, {
      'userId': user.uid,
      'name': user.name,
      'nim': user.nim,
      'joinedAt': Timestamp.fromDate(DateTime.now()),
    });
    batch.update(_db.collection('clubs').doc(clubId), {
      'memberCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Leave a club
  Future<void> leaveClub({
    required String clubId,
    required String userId,
  }) async {
    final batch = _db.batch();
    batch.delete(
      _db.collection('clubs').doc(clubId).collection('members').doc(userId),
    );
    batch.update(_db.collection('clubs').doc(clubId), {
      'memberCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  /// BoD removes a member
  Future<void> removeMember({required String clubId, required String userId}) =>
      leaveClub(clubId: clubId, userId: userId);

  /// Check if a user is already a member
  Future<bool> isMember({
    required String clubId,
    required String userId,
  }) async {
    final doc = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('members')
        .doc(userId)
        .get();
    return doc.exists;
  }

  /// BEM approves a club request
  Future<void> approveRequest({
    required String requestId,
    required String clubId,
    required String reviewedBy,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('clubRequests').doc(requestId), {
      'status': 'approved',
      'reviewedBy': reviewedBy,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });
    batch.update(_db.collection('clubs').doc(clubId), {'status': 'active'});
    await batch.commit();
  }

  /// BEM rejects a club request
  Future<void> rejectRequest({
    required String requestId,
    required String clubId,
    required String reviewedBy,
    required String note,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('clubRequests').doc(requestId), {
      'status': 'rejected',
      'reviewedBy': reviewedBy,
      'reviewNote': note,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });
    batch.update(_db.collection('clubs').doc(clubId), {'status': 'rejected'});
    await batch.commit();
  }

  /// BEM suspends a club
  Future<void> suspendClub(String clubId) =>
      _db.collection('clubs').doc(clubId).update({'status': 'suspended'});

  /// BEM reactivates a club
  Future<void> reactivateClub(String clubId) =>
      _db.collection('clubs').doc(clubId).update({'status': 'active'});

  /// BEM updates BoD
  Future<void> updateBod({required String clubId, required BodModel bod}) =>
      _db.collection('clubs').doc(clubId).update({'bod': bod.toMap()});

  /// Fetch a single club once
  Future<ClubModel?> getClub(String clubId) async {
    final doc = await _db.collection('clubs').doc(clubId).get();
    if (!doc.exists) return null;
    return ClubModel.fromFirestore(doc);
  }

  /// BEM edits club details
  Future<void> updateClubDetails({
    required String clubId,
    required String name,
    required String description,
    required String roomNumber,
    required String meetingDay,
    required String meetingTime,
  }) => _db.collection('clubs').doc(clubId).update({
    'name': name,
    'description': description,
    'roomNumber': roomNumber,
    'meetingDay': meetingDay,
    'meetingTime': meetingTime,
  });
}
