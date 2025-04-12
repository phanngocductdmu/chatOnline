import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'requestFriend.dart';
import 'ReceivedFriend.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoiMoiKetBan(),
    );
  }
}

class LoiMoiKetBan extends StatefulWidget {
  const LoiMoiKetBan({super.key});

  @override
  State<LoiMoiKetBan> createState() => _LoiMoiKetBanState();
}

class _LoiMoiKetBanState extends State<LoiMoiKetBan> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  // Lấy userId từ SharedPreferences
  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');  // Lấy userId từ SharedPreferences
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_outlined),
              onPressed: () {
                Navigator.pop(context); // Back action
              },
            ),
          ),
          leadingWidth: 40,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            'friend_request'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 19,
            ),
          ),
          actions: [
            IconButton(
              icon: Image.asset(
                'assets/image/addfriend.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
              onPressed: () {
                // Handle add friend action
              },
            ),
          ],
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Column(
          children: [
            // TabBar placed outside AppBar and set background color to white
            Container(
              color: Color(0xffFAFAFA),
              child: TabBar(
                indicatorColor: Color(0xff11998E),
                indicatorWeight: 1,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black,
                unselectedLabelColor: Color(0xff707070),
                tabs: [
                  Tab(text: 'received'.tr()),
                  Tab(text: 'sent'.tr()),
                ],
              ),
            ),
            // TabBarView with white background color
            Expanded(
              child: userId == null
                  ? const Center(child: CircularProgressIndicator()) // Nếu chưa có userId
                  : TabBarView(
                children: [
                  DaNhanView(userId: userId!), // Truyền userId vào (đảm bảo không null)
                  DaGuiView(userId: userId!), // Truyền userId vào (đảm bảo không null)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




