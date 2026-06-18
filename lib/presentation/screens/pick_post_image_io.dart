import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> pickPostImageImpl(String userId) async {
  final imagePicker = ImagePicker();
  final image = await imagePicker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1080,
    imageQuality: 85,
  );

  if (image == null) {
    return null;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.uid != userId) {
    return null;
  }

  final storageRef = FirebaseStorage.instance.ref();
  final fileName = image.name.isEmpty
      ? '${DateTime.now().millisecondsSinceEpoch}.jpg'
      : image.name;
  final imagesRef = storageRef.child(
    'posts/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName',
  );
  final bytes = await image.readAsBytes();
  final uploadTask = imagesRef.putData(bytes);
  final snapshot = await uploadTask.timeout(const Duration(seconds: 60));
  return snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 20));
}
