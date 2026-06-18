// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<String?> pickPostImageImpl(String userId) async {
  final uploadInput = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..style.position = 'fixed'
    ..style.left = '-10000px'
    ..style.top = '0'
    ..style.width = '1px'
    ..style.height = '1px'
    ..style.opacity = '0';

  html.document.body?.append(uploadInput);

  try {
    uploadInput.click();

    await uploadInput.onChange.first;

    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != userId) {
      return null;
    }

    final file = files.first;
    final bytes = await _readFileAsBytes(file);

    final storageRef = FirebaseStorage.instance.ref();
    final fileName = file.name.isEmpty
        ? '${DateTime.now().millisecondsSinceEpoch}.jpg'
        : file.name;
    final imagesRef = storageRef.child(
      'posts/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName',
    );

    final uploadTask = imagesRef.putData(bytes);
    final snapshot = await uploadTask.timeout(const Duration(seconds: 60));
    return snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 20));
  } finally {
    uploadInput.remove();
  }
}

Future<Uint8List> _readFileAsBytes(html.File file) {
  final reader = html.FileReader();
  final completer = Completer<Uint8List>();

  reader.onLoadEnd.listen((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      completer.complete(result.asUint8List());
      return;
    }
    if (result is List<int>) {
      completer.complete(Uint8List.fromList(result));
      return;
    }
    completer.completeError(StateError('Failed to read selected file'));
  });

  reader.onError.listen((_) {
    completer.completeError(StateError('Failed to read selected file'));
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
}
