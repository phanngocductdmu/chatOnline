// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class MyFirebaseMessagingService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
//
//   Future<void> initialize() async {
//     // 1️⃣ Yêu cầu quyền thông báo
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print("User granted permission for notifications");
//     } else {
//       print("User declined or has not accepted permission");
//       return;
//     }
//
//     // 2️⃣ Cấu hình thông báo cục bộ
//     const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const InitializationSettings initializationSettings = InitializationSettings(android: androidSettings);
//
//     await _localNotifications.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         print("User tapped on notification: ${response.payload}");
//       },
//     );
//
//     // 3️⃣ Xử lý thông báo khi ứng dụng đang mở
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print("Received message: ${message.notification?.title} - ${message.notification?.body}");
//       _showLocalNotification(message);
//     });
//
//     // 4️⃣ Xử lý khi app mở từ trạng thái đóng hoàn toàn
//     FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
//       if (message != null) {
//         print("App opened from terminated state by message: ${message.notification?.title}");
//       }
//     });
//
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print("App opened from background by message: ${message.notification?.title}");
//     });
//   }
//
//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'high_importance_channel',
//       'Thông báo từ Firebase',
//       importance: Importance.high,
//     );
//
//     await _localNotifications
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//
//     AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       channel.id,
//       channel.name,
//       channelDescription: 'Kênh thông báo quan trọng',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//
//     NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
//
//     await _localNotifications.show(
//       0, // ID thông báo
//       message.notification?.title ?? 'Không có tiêu đề',
//       message.notification?.body ?? 'Không có nội dung',
//       notificationDetails,
//     );
//   }
//
//   Future<String?> getToken() async {
//     return await _firebaseMessaging.getToken();
//   }
// }
