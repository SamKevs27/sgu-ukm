import 'package:campus_club/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Sign up — students only, enforces @student.sgu.ac.id
  Future<UserModel> signUpStudent({
    required String email,
    required String password,
    required String name,
    required String nim,
  }) async {
    if (!email.endsWith('@student.sgu.ac.id')) {
      throw Exception('Only @student.sgu.ac.id emails are allowed.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      nim: nim,
      role: UserRole.student,
      createdAt: DateTime.now(),
    );

    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore());

    return user;
  }

  /// Sign in for both students and BEM
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc = await _db
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    if (!doc.exists) throw Exception('User profile not found.');

    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() => _auth.signOut();

  /// Fetch user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // 
  Future<List<UserModel>> searchStudents(String query) async {
  final q = query.toLowerCase().trim();

  // Search by name prefix — no composite index needed
  final byName = await _db
      .collection('users')
      .where('nameLower', isGreaterThanOrEqualTo: q)
      .where('nameLower', isLessThan: '${q}z')
      .limit(20)
      .get();

  // Search by email prefix — no composite index needed
  final byEmail = await _db
      .collection('users')
      .where('email', isGreaterThanOrEqualTo: q)
      .where('email', isLessThan: '${q}z')
      .limit(20)
      .get();

  // Merge, deduplicate, then filter role client-side
  final seen = <String>{};
  final results = <UserModel>[];
  for (final doc in [...byName.docs, ...byEmail.docs]) {
    if (seen.add(doc.id)) {
      final user = UserModel.fromFirestore(doc);
      if (user.role == UserRole.student) results.add(user); // 👈 filter here
    }
  }
  return results;
}
}

// security features:
// - firebase auth for authentication (encrypted)
// - Firestore rules to restrict data access based on auth state and user role
// - No sensitive data stored in plaintext in Firestore (e.g. passwords)
// - Client-side checks for email domain on sign-up, but also enforce this in Firestore
// - satpam hardware server Google Jakarta @scbd