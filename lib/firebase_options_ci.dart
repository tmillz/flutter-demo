// Stub Firebase options for CI/CD analysis
// This file contains placeholder values for static analysis only
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'placeholder-api-key',
      appId: 'placeholder-app-id',
      messagingSenderId: 'placeholder-sender-id',
      projectId: 'tmillz',
      authDomain: 'tmillz.firebaseapp.com',
      storageBucket: 'tmillz.appspot.com',
    );
  }
}
