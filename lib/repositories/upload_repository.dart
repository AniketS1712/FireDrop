import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class UploadRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAvatar(String userId, File file) async {
    final ref = _storage.ref().child('avatars/$userId.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
