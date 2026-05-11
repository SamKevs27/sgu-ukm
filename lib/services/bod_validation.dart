import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Ensures every BoD user id maps to a [UserRole.student] profile.
Future<void> ensureBodMembersAreStudents(
  FirebaseFirestore db,
  BodModel bod,
) async {
  for (final uid in bod.allIds) {
    final doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('BoD user profile not found.');
    }
    final user = UserModel.fromFirestore(doc);
    if (user.role != UserRole.student) {
      throw Exception(
        'Only student accounts can hold BoD positions (head, vice, etc.).',
      );
    }
  }
}
