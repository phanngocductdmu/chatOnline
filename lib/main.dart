import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LogIn.dart';
import 'package:chatonline/message/call/IncomingCallScreen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('vi', null);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DatabaseReference? userStatusRef;
  DatabaseReference? callRef;
  String? userId;

  // Khởi tạo navigatorKey
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
    });
  }

  Future<void> _initializeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');

      if (userId == null || userId!.isEmpty) {
        return;
      }
      userStatusRef = FirebaseDatabase.instance.ref('users/$userId/status');
      callRef = FirebaseDatabase.instance.ref("calls");
      _updateUserStatus(true);
      _listenForIncomingCalls();
    } catch (e) {
      // print("🔴 Lỗi khi khởi tạo user: $e");
    }
  }

  void _listenForIncomingCalls() {
    if (callRef == null) return;
    callRef!.onValue.listen((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return;
      try {
        final Map<String, dynamic> calls = Map<String, dynamic>.from(snapshot.value as Map);
        for (var entry in calls.entries) {
          final String callId = entry.key;
          final Map<String, dynamic> callData = Map<String, dynamic>.from(entry.value);
          if (callData['idFriend'] == userId &&
              callData['status'] == 'calling' &&
              callData['myID'] != userId) {
            _showIncomingCall(callId, callData);
          }
        }
      } catch (e) {
        // print("🔴 Lỗi khi xử lý cuộc gọi đến: $e");
      }
    }, onError: (error) {
      // print("🔴 Lỗi khi lắng nghe cuộc gọi: $error");
    });
  }

  void _showIncomingCall(String callKey ,Map<String, dynamic> callData) {
    if (callData.isNotEmpty) {
      final idFriend = callData['idFriend'] ?? '';
      final nameFriend = callData['nameFriend'] ?? '';
      final callerAVT = callData['callerAvatar'] ?? '';
      final channelId = callData['channelName'] ?? '';
      final myName = callData['myName'] ?? '';
      final myAVT = callData['myAVT'] ?? '';
      final myID = callData['myID'] ?? '';
      final status = callData['status'] ?? '';
      final typeCall = callData['typeCall'] ?? '';
      if (idFriend.isNotEmpty && channelId.isNotEmpty) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => IncomingCallScreen(
              callKey: callKey,
              idFriend: idFriend,
              nameFriend: nameFriend,
              callerAVT: callerAVT,
              channelId: channelId,
              myName: myName,
              myAVT: myAVT,
              myID: myID,
              status: status,
              typeCall: typeCall,
            ),
          ),
        );
      }
    }
  }

  void _updateUserStatus(bool isActive) {
    if (userStatusRef != null) {
      userStatusRef!.set({
        'online': isActive,
        'lastSeen': isActive ? null : ServerValue.timestamp,
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (userId != null) {
      if (state == AppLifecycleState.resumed) {
        _updateUserStatus(true);
      } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _updateUserStatus(false);
      }
    }
  }

  @override
  void dispose() {
    _updateUserStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _languageButton(),
          _backgroundImage(),
          _actionButtons(context),
        ],
      ),
    );
  }

  Widget _languageButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 65, right: 20),
      child: Align(
        alignment: Alignment.topRight,
        child: ElevatedButton(
          onPressed: null, // Add your language change logic here
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(134, 40), // Tránh lỗi overflow
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: Color(0xFFC2BABA), width: 1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Không chiếm toàn bộ không gian
            children: [
              Flexible(
                child: Text('Tiếng Việt', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 3),
              Image.asset('assets/image/morong.png', width: 18, height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backgroundImage() {
    return Expanded(
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/image/trangchinh1.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            const Text(
              'TEST',
              style: TextStyle(
                color: Color(0xFF38EF7D),
                fontSize: 58,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 10, 26, 20),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 49),
              backgroundColor: const Color(0xFF38EF7D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text('Đăng nhập', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 49),
              backgroundColor: const Color(0xFFE9EEF0),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text('Tạo tài khoản mới', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

