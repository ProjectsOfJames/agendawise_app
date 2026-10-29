import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Chooses and stores the profile picture. The picture is copied into app
/// storage and is never uploaded.
class AvatarStore {
  const AvatarStore();

  /// Returns the stored file's path, or null if nothing was chosen.
  Future<String?> pick({required String uid, String? replacing}) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final documents = await getApplicationDocumentsDirectory();
    final folder =
        Directory('${documents.path}${Platform.pathSeparator}avatars');
    await folder.create(recursive: true);
    // A new name each time so image caches never show the old picture.
    final target = '${folder.path}${Platform.pathSeparator}'
        '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(target);
    await remove(replacing);
    return target;
  }

  Future<void> remove(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

final avatarStoreProvider = Provider<AvatarStore>((ref) => const AvatarStore());
