import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatonline/Search/TimKiem.dart';
import 'personalPage.dart';
import 'setting/setting.dart';
import 'package:chatonline/User/chatBot/chatBot.dart';

class User extends StatefulWidget {
  const User({super.key});

  @override
  State<User> createState() => _UserState();
}

class _UserState extends State<User> {
  late String idUser;

  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, dynamic>?> fetchUserInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idUser = prefs.getString('userId');

      if (idUser == null) return null;

      DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$idUser");
      DataSnapshot snapshot = await userRef.get();

      if (!snapshot.exists) return null;

      Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
      return userData;
    } catch (e) {
      print("Lỗi khi lấy dữ liệu người dùng: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {});
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimKiem()),
                  );
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
                'search'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 19,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Setting()));
                },
              ),
            ],
            iconTheme: IconThemeData(color: Colors.white),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: fetchUserInfo(), // Gọi hàm fetchUserInfo()
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Center(child: Text("Không thể tải thông tin"));
            }

            Map<String, dynamic> user = snapshot.data!;

            return Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => PersonalPage())
                        );
                      },
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              backgroundImage: user["AVT"] != null && user["AVT"].isNotEmpty
                                  ? NetworkImage(user["AVT"])
                                  : null,
                              backgroundColor: Colors.grey[300],
                              radius: 30,
                              child: user["AVT"] == null || user["AVT"].isEmpty
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 15),
                            // Tên và email
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user["fullName"] ?? "",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  "view_profile".tr(),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Icon nhỏ nằm giữa dọc theo cạnh phải
                    Positioned(
                      right: 16, // Căn sát lề phải
                      top: 0,
                      bottom: 0, // Trải dài toàn bộ chiều cao Container
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            print("Đã nhấn vào icon");
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.grey[400], // Nền xám
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white, // Màu icon trắng
                              size: 15, // Kích thước nhỏ
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                //chat bot
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatBotScreen()));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 5),
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Icon Cloud
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.smart_toy_outlined,
                                color: Colors.grey,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 3),
                            // Tên và trạng thái
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Chat bot",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  "title_chatbot".tr(),
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
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
                ),

                const Divider(
                  thickness: 1,
                  height: 1,
                  color: Color(0xFFF3F4F6),
                ),

                GestureDetector(
                  onTap: () {
                    print("Đã nhấn vào mục Cloud của tôi");
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 0),
                    color: Colors.white, // Nền trắng
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Icon Cloud
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.cloud_outlined,
                                color: Colors.grey,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 3),
                            // Tên và trạng thái
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "my_cloud".tr(),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  "title_cloud".tr(),
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
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
                ),

                const Divider(
                  thickness: 1,
                  height: 1,
                  color: Color(0xFFF3F4F6),
                ),

                GestureDetector(
                  onTap: () {
                    print("Đã nhấn vào Dữ liệu đám mây");
                    // Thêm xử lý khi nhấn vào mục này
                  },
                  child: Container(
                    color: Colors.white, // Nền trắng
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn giữa nội dung và nút next
                      children: [
                        Row(
                          children: [
                            // Icon Cloud
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.data_saver_off,
                                color: Colors.grey, // Icon màu xám đậm
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 3),
                            // Tên và trạng thái
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "cloud_data".tr(),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  "title_cloud_data".tr(),
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Nút Next
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
                ),

                const Divider(
                  thickness: 1,
                  height: 1,
                  color: Color(0xFFF3F4F6),
                ),

                GestureDetector(
                  onTap: () {
                    print("Đã nhấn vào Tài khoản và bảo mật");
                    // Thêm xử lý khi nhấn vào đây
                  },
                  child: Container(
                    color: Colors.white, // Nền trắng
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn giữa nội dung và nút next
                      children: [
                        Row(
                          children: [
                            // Icon Privacy
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.privacy_tip_outlined,
                                color: Colors.grey,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 3),
                            // Tên và trạng thái
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "account_and_password".tr(),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Nút Next
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
                ),

                const Divider(
                  thickness: 1,
                  height: 1,
                  color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
                ),

                GestureDetector(
                  onTap: () {
                    print("Đã nhấn vào Quyền riêng tư");
                    // Thêm xử lý khi nhấn vào đây, ví dụ: chuyển màn hình
                  },
                  child: Container(
                    color: Colors.white, // Nền trắng
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Icon Lock
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.grey,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 3),
                            // Tên và trạng thái
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "privacy".tr(),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Nút Next
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
