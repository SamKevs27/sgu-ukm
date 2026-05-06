import 'package:campus_club/models/cycle_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CycleService {
  final _db = FirebaseFirestore.instance;

  Stream<List<CycleModel>> watchAllCycles() {
    return _db
        .collection('cycles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(CycleModel.fromFirestore).toList());
  }

  Stream<CycleModel?> watchActiveCycle() {
    return _db
        .collection('cycles')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : CycleModel.fromFirestore(s.docs.first));
  }

  Future<void> createCycle({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
  }) async {
    // Deactivate all existing cycles first
    final batch = _db.batch();
    final existing = await _db
        .collection('cycles')
        .where('isActive', isEqualTo: true)
        .get();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {'isActive': false});
    }

    final ref = _db.collection('cycles').doc();
    batch.set(ref, {
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': true,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    await batch.commit();
  }
}