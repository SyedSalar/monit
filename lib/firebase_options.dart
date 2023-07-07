// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
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
    apiKey: 'AIzaSyCuXGU60lBatqd8sf8fAM6Kdfsn5NSW58I',
    appId: '1:305403791246:web:05c5d542406b029badc6df',
    messagingSenderId: '305403791246',
    projectId: 'monit-8e5f9',
    authDomain: 'monit-8e5f9.firebaseapp.com',
    storageBucket: 'monit-8e5f9.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyACslFL-bxg-1FVY-PjG8JdVr708IDq3TQ',
    appId: '1:305403791246:android:f7474c7971875129adc6df',
    messagingSenderId: '305403791246',
    projectId: 'monit-8e5f9',
    storageBucket: 'monit-8e5f9.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyABan2kGCD4eDROcagq_2Ch4VJ6u_XnE8s',
    appId: '1:305403791246:ios:c09b4a340f6b1360adc6df',
    messagingSenderId: '305403791246',
    projectId: 'monit-8e5f9',
    storageBucket: 'monit-8e5f9.appspot.com',
    iosClientId: '305403791246-3127qscr0f4iunt4cesfe8fpvpdk7aed.apps.googleusercontent.com',
    iosBundleId: 'com.example.monit',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyABan2kGCD4eDROcagq_2Ch4VJ6u_XnE8s',
    appId: '1:305403791246:ios:cc49748e3b7bef07adc6df',
    messagingSenderId: '305403791246',
    projectId: 'monit-8e5f9',
    storageBucket: 'monit-8e5f9.appspot.com',
    iosClientId: '305403791246-6gbvumjjdgn3auhjpuodckrdtng7raq2.apps.googleusercontent.com',
    iosBundleId: 'com.example.monit.RunnerTests',
  );
}