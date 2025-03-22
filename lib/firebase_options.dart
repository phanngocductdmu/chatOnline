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
        return windows;
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
    apiKey: 'AIzaSyB04GpLloAQij2Y8jl1FdeLRycrWTbsILE',
    appId: '1:931006144509:web:c3ed8c52ffa83db8058394',
    messagingSenderId: '931006144509',
    projectId: 'b5lab1',
    authDomain: 'b5lab1.firebaseapp.com',
    databaseURL: 'https://b5lab1-default-rtdb.firebaseio.com',
    storageBucket: 'b5lab1.appspot.com',
    measurementId: 'G-420FV0NWMV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAGeBVzUr7OgkcCnD448pH6UOoLBMR6Bgo',
    appId: '1:931006144509:android:09f3403fbe895229058394',
    messagingSenderId: '931006144509',
    projectId: 'b5lab1',
    databaseURL: 'https://b5lab1-default-rtdb.firebaseio.com',
    storageBucket: 'b5lab1.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDZb2I0YbOM1DzJV4rkOTw0OTYl-5QfI1U',
    appId: '1:931006144509:ios:5b5c17ce5091d6b2058394',
    messagingSenderId: '931006144509',
    projectId: 'b5lab1',
    databaseURL: 'https://b5lab1-default-rtdb.firebaseio.com',
    storageBucket: 'b5lab1.appspot.com',
    iosBundleId: 'com.example.chatonline',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDZb2I0YbOM1DzJV4rkOTw0OTYl-5QfI1U',
    appId: '1:931006144509:ios:5b5c17ce5091d6b2058394',
    messagingSenderId: '931006144509',
    projectId: 'b5lab1',
    databaseURL: 'https://b5lab1-default-rtdb.firebaseio.com',
    storageBucket: 'b5lab1.appspot.com',
    iosBundleId: 'com.example.chatonline',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB04GpLloAQij2Y8jl1FdeLRycrWTbsILE',
    appId: '1:931006144509:web:c3ed8c52ffa83db8058394',
    messagingSenderId: '931006144509',
    projectId: 'b5lab1',
    authDomain: 'b5lab1.firebaseapp.com',
    databaseURL: 'https://b5lab1-default-rtdb.firebaseio.com',
    storageBucket: 'b5lab1.appspot.com',
    measurementId: 'G-420FV0NWMV',
  );

}