import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<bool> signInWithUsernameAndPassword(String username, String password) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      DatabaseReference usersRef = _database.ref('users');
      DataSnapshot snapshot = await usersRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;

        for (var userId in users.keys) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(users[userId]);

          if (userData['username'] == username) {
            if (password == userData['password']) {
              // ✅ Lưu userId vào SharedPreferences
              await prefs.setString('userId', userId);

              // ✅ Lấy FCM Token
              // String? fcmToken = await FirebaseMessaging.instance.getToken();

              // if (fcmToken != null) {
              //   // ✅ Lưu token vào Realtime Database
              //   await usersRef.child(userId).update({'fcmToken': fcmToken});
              // }

              return true; // Đăng nhập thành công
            } else {
              return false; // Sai mật khẩu
            }
          }
        }
        return false; // Không tìm thấy username
      } else {
        return false; // Database rỗng
      }
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      return false;
    }
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Xóa userId khi đăng xuất
  Future<void> signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }
}
