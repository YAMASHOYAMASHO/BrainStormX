// File generated based on Firebase configuration
// flutterfire-cli
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCNtVKfCW5hFy-LVpzScykMu8G75WwVyVY',
    appId: '1:591961453741:web:ce904f61ac11f418880224',
    messagingSenderId: '591961453741',
    projectId: 'thinker-ai-app',
    authDomain: 'thinker-ai-app.firebaseapp.com',
    storageBucket: 'thinker-ai-app.firebasestorage.app',
    measurementId: 'G-8WQZPTLTS1',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJuXsptf8k7glGbduYObY7lKezMLKFgy8',
    appId: '1:591961453741:ios:1b4ae8e84979b187880224',
    messagingSenderId: '591961453741',
    projectId: 'thinker-ai-app',
    storageBucket: 'thinker-ai-app.firebasestorage.app',
    iosBundleId: 'com.ichihos.thinker',
  );

  // Android設定はflutterfire configureで追加してください
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBJuXsptf8k7glGbduYObY7lKezMLKFgy8',
    appId: '1:591961453741:android:placeholder880224',
    messagingSenderId: '591961453741',
    projectId: 'thinker-ai-app',
    storageBucket: 'thinker-ai-app.firebasestorage.app',
  );
}
