import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatonline/Search/TimKiem.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> with SingleTickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? idUser;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getString('userId');
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> settings = [
      {
        "title": "Tài khoản và bảo mật",
        "icon": Icons.security,
        "action": () => print("Mở Tài khoản và bảo mật"),
      },
      {
        "title": "Quyền riêng tư",
        "icon": Icons.lock_outline,
        "action": () => print("Mở Quyền riêng tư"),
      },
      {
        "title": "Dữ liệu trên máy",
        "icon": Icons.storage,
        "action": () => print("Mở Dữ liệu trên máy"),
      },
      {
        "title": "Sao lưu và khôi phục",
        "icon": Icons.backup,
        "action": () => print("Mở Sao lưu và khôi phục"),
      },
      {
        "title": "Thông báo",
        "icon": Icons.notifications_outlined,
        "action": () => print("Mở Cài đặt thông báo"),
      },
      {
        "title": "Tin nhắn",
        "icon": Icons.message_outlined,
        "action": () => print("Mở Tin nhắn"),
      },
      {
        "title": "Cuộc gọi",
        "icon": Icons.call_outlined,
        "action": () => print("Mở Cuộc gọi"),
      },
      {
        "title": "Nhật ký",
        "icon": Icons.history,
        "action": () => print("Mở Nhật ký"),
      },
      {
        "title": "Danh bạ",
        "icon": Icons.contacts_outlined,
        "action": () => print("Mở Danh bạ"),
      },
      {
        "title": "Giao diện và ngôn ngữ",
        "icon": Icons.language,
        "action": () => print("Mở Giao diện và ngôn ngữ"),
      },
      {
        "title": "Chuyển tài khoản",
        "icon": Icons.swap_horiz,
        "action": () => print("Mở Chuyển tài khoản"),
      },
      {
        "title": "Đăng xuất",
        "icon": Icons.exit_to_app,
        "action": () => print("Đăng xuất"),
      },

    ];

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  Navigator.pop(context);
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
            title: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TimKiem()),
                );
              },
              child: Text(
                'Cài đặt',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 19,
                ),
              ),
            ),
            iconTheme: IconThemeData(color: Colors.white),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
        body: ListView.builder(
          itemCount: settings.length,
          itemBuilder: (context, index) {
            final settingData = settings[index];
            return Column(
              children: [
                setting(
                  title: settingData["title"],
                  icon: settingData["icon"],
                  onTap: settingData["action"],
                ),
                const Divider(
                  thickness: 1,
                  height: 1,
                  color: Color(0xFFF3F4F6),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget setting({required String title, required IconData icon, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 0),
        color: Colors.white,
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Icon(
                    icon,
                    color: Colors.grey,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
