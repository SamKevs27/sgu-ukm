// lib/services/cycle_service.dart
import 'package:campus_club/models/cycle_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CycleService {
  final _db = FirebaseFirestore.instance;

  Stream<List<CycleModel>> watchAllCycles() {
    return _db.collection('cycles').snapshots().map((s) {
      final list = s.docs.map(CycleModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<CycleModel?> watchActiveCycle() {
    return _db
        .collection('cycles')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((s) =>
            s.docs.isEmpty ? null : CycleModel.fromFirestore(s.docs.first));
  }

  Future<CycleModel> createCycle({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
  }) async {
    final ref = _db.collection('cycles').doc();
    final cycle = CycleModel(
      cycleId: ref.id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isActive: false,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
    await ref.set(cycle.toFirestore());
    return cycle;
  }

  /// Sets a cycle as active. Deactivates all others first.
  Future<void> setActiveCycle({
    required String cycleId,
    required bool activate,
  }) async {
    final batch = _db.batch();

    if (activate) {
      final all = await _db
          .collection('cycles')
          .where('isActive', isEqualTo: true)
          .get();
      for (final doc in all.docs) {
        if (doc.id != cycleId) {
          batch.update(doc.reference, {'isActive': false});
        }
      }
    }

    batch.update(
      _db.collection('cycles').doc(cycleId),
      {'isActive': activate},
    );

    await batch.commit();
  }
}