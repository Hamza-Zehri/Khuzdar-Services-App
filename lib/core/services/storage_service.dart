import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfilePic({
    required String uid,
    required File imageFile,
  }) async {
    try {
      // Compress to keep APK-friendly sizes
      final compressed = await _compress(imageFile);
      if (compressed == null) return null;

      final ref = _storage.ref('profiles/$uid/avatar.jpg');
      await ref.putFile(compressed, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<File?> _compress(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg');

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 400,
      minHeight: 400,
    );

    return result != null ? File(result.path) : null;
  }
}
