import 'package:chatonline/Contacts/all.dart';
import 'package:chatonline/Contacts/justVisited.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:chatonline/Contacts/LoiMoiKetBan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Friends extends StatefulWidget {
  const Friends({super.key});

  @override
  State<Friends> createState() => FriendsState();
}

class FriendsState extends State<Friends> with SingleTickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late TabController _tabController;
  int friendCount = 0;
  int friendOnlineCount = 0;
  String? idUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getString('userId');
    });

    if (idUser != null) {
      listenToFriendCount(idUser!);
      listenToOnlineFriendsCount(idUser!);
    }
  }

  void listenToFriendCount(String userId) {
    _database.child('friends/$userId').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? friendsData = event.snapshot.value as Map<dynamic, dynamic>?;
        int count = friendsData != null ? friendsData.length : 0;
        setState(() {
          friendCount = count;
        });
      } else {
        setState(() {
          friendCount = 0;
        });
      }
    });
  }

  void listenToOnlineFriendsCount(String userId) {
    _database.child('friends/$userId').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? friendsData = event.snapshot.value as Map<dynamic, dynamic>?;
        int onlineCount = 0; // Đếm số bạn bè online
        friendsData?.forEach((friendId, _) {
          _database.child('users/$friendId/status/online').onValue.listen((statusEvent) {
            bool isOnline = statusEvent.snapshot.value == true;
            if (isOnline) {
              onlineCount++;
            }
            setState(() {
              friendOnlineCount = onlineCount;
            });
          });
        });
      } else {
        setState(() {
          friendOnlineCount = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Widget> _views = [
    const LoiMoiKetBan(),
    // const DanhBaMayView(),
    // const LichSinhNhatView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      body: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  leading: const Icon(Icons.person_add, color: Colors.teal),
                  title: Text('friend_request'.tr()),
                  trailing: const Icon(Icons.navigate_next, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoiMoiKetBanScreen()),
                    );
                  },
                ),
              ),
              Container(
                color: Colors.white, // Đặt màu nền trắng
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  leading: const Icon(Icons.contacts, color: Colors.blue),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('phone_book'.tr()),
                      Text(
                        'Liên hệ có dùng Test',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.navigate_next, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoiMoiKetBanScreen()),
                    );
                  },
                ),
              ),
              Container(
                color: Colors.white, // Đặt màu nền trắng
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  leading: const Icon(Icons.cake, color: Colors.pink),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('birthday_calendar'.tr()),
                      Text(
                        'Theo dõi sinh nhật của bạn bè',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.navigate_next, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoiMoiKetBanScreen()),
                    );
                  },
                ),
              ),
              const Divider(
                thickness: 1,
                height: 1,
                color: Color(0xFFF3F4F6),
              ),
              Container(
                color: Colors.white, // Đặt màu nền trắng cho TabBar
                child: TabBar(
                  labelColor: Colors.green[700],
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.green[700],
                  tabs: [
                    Tab(text: 'all'.tr(namedArgs: {'count': friendCount.toString()})),
                    Tab(text: 'new_visit'.tr(namedArgs: {'count': friendOnlineCount.toString()})),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7, // Giới hạn chiều cao TabBarView
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(), // Không cho phép vuốt giữa các tab
                  children: [
                    All(),
                    JustVisited(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class LoiMoiKetBanScreen extends StatelessWidget {
  const LoiMoiKetBanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const LoiMoiKetBan(),
    );
  }
}

