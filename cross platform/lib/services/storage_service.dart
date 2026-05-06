import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadClubLogo(File file, String clubId) async {
    final ref = _storage.ref().child('clubs/$clubId/logo.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadMeetingPhoto(File file, String clubId, String meetingId) async {
    final fileName = _uuid.v4();
    final ref = _storage.ref().child('clubs/$clubId/meetings/$meetingId/$fileName.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}