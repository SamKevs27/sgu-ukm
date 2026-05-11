// lib/services/bem_service.dart
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/club_request_model.dart';
import 'package:campus_club/services/bod_validation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BemService {
  final _db = FirebaseFirestore.instance;

  // ─── Streams ───────────────────────────────────────────────

  Stream<List<ClubRequestModel>> watchAllRequests() {
    return _db
        .collection('clubRequests')
        .snapshots()
        .map((s) {
          final list = s.docs.map(ClubRequestModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<ClubModel>> watchAllClubs() {
    return _db.collection('clubs').snapshots().map((s) {
      final list = s.docs.map(ClubModel.fromFirestore).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  // ─── Single club fetch ──────────────────────────────────────

  Future<ClubModel?> fetchClub(String clubId) async {
    final doc = await _db.collection('clubs').doc(clubId).get();
    if (!doc.exists) return null;
    return ClubModel.fromFirestore(doc);
  }

  // ─── Request review ─────────────────────────────────────────

  /// BEM approves or rejects a club creation / renewal request.
  /// On approval:
  ///   - Sets the club status to [ClubStatus.active]
  ///   - Marks the request as approved
  /// On rejection:
  ///   - Marks the request as rejected
  ///   - Does NOT change the club status (stays pending)
  Future<void> reviewRequest({
    required String requestId,
    required String clubId,
    required bool approve,
    required String reviewedBy,
    String? reviewNote,
  }) async {
    final batch = _db.batch();

    // 1. Update the request document
    final requestRef = _db.collection('clubRequests').doc(requestId);
    batch.update(requestRef, {
      'status': approve
          ? RequestStatus.approved.name
          : RequestStatus.rejected.name,
      'reviewedBy': reviewedBy,
      'reviewNote': reviewNote,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });

    // 2. If approved, update the club status to active
    if (approve) {
      final clubRef = _db.collection('clubs').doc(clubId);
      batch.update(clubRef, {'status': ClubStatus.active.name});
    }

    await batch.commit();
  }

  // ─── Club management ────────────────────────────────────────

  /// BEM suspends an active club (blocks meeting creation).
  Future<void> suspendClub({
    required String clubId,
    String? reason,
  }) async {
    await _db.collection('clubs').doc(clubId).update({
      'status': ClubStatus.suspended.name,
      'suspendReason': reason,
    });
  }

  /// BEM reactivates a suspended club.
  Future<void> reactivateClub(String clubId) async {
    await _db.collection('clubs').doc(clubId).update({
      'status': ClubStatus.active.name,
      'suspendReason': null,
    });
  }

  /// BEM changes the BoD composition of a club.
  /// [newBod] must include at least a headId.
  Future<void> updateBod({
    required String clubId,
    required BodModel newBod,
  }) async {
    await ensureBodMembersAreStudents(_db, newBod);
    await _db.collection('clubs').doc(clubId).update({
      'bod': newBod.toMap(),
    });
  }
}