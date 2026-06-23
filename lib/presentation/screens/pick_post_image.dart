// ignore_for_file: avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Picks an image from the gallery and uploads it to Firebase Storage.
/// Returns the public download URL, or null if the user cancelled.
Future<String?> pickPostImage(String userId) async {
  print('[picker] pickImage starting');
  final image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1080,
    imageQuality: 85,
  );
  print('[picker] pickImage returned: ${image?.name ?? "null (cancelled)"}');

  if (image == null) return null;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.uid != userId) {
    print('[picker] auth check failed');
    return null;
  }

  // On web, image_picker_for_web returns a blob: URL.
  // readAsBytes() can throw an uncaught zone error in dart2js release builds,
  // so we fetch the bytes via package:http (XHR) which is reliable on all
  // platforms including web release.
  print('[picker] fetching bytes from: ${image.path}');
  final response = await http.get(Uri.parse(image.path));
  print('[picker] bytes: ${response.bodyBytes.length}');
  final bytes = response.bodyBytes;

  final fileName = image.name.isEmpty
      ? '${DateTime.now().millisecondsSinceEpoch}.jpg'
      : image.name;
  final path =
      'posts/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
  print('[picker] uploading to $path');

  try {
    final uploadTask = FirebaseStorage.instance
        .ref()
        .child(path)
        .putData(bytes);

    uploadTask.snapshotEvents.listen(
      (s) => print(
        '[picker] ${s.state.name} ${s.bytesTransferred}/${s.totalBytes}',
      ),
      onError: (e) => print('[picker] upload stream error: $e'),
      cancelOnError: false,
    );

    final snapshot = await uploadTask.timeout(const Duration(seconds: 90));
    print('[picker] upload complete, fetching URL');
    final url = await snapshot.ref.getDownloadURL().timeout(
      const Duration(seconds: 20),
    );
    print('[picker] done: $url');
    return url;
  } catch (e, st) {
    print('[picker] upload error: $e\n$st');
    rethrow;
  }
}
