import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DaGuiView extends StatefulWidget {
  final String userId;  // Thêm tham số userId vào constructor
  const DaGuiView({super.key, required this.userId});  // Nhận userId qua constructor

  @override
  State<DaGuiView> createState() => _DaGuiViewState();
}

class _DaGuiViewState extends State<DaGuiView> {
  final DatabaseReference _database =
  FirebaseDatabase.instance.ref("friendInvitation");

  final DatabaseReference _usersDatabase =
  FirebaseDatabase.instance.ref("users");  // Reference to 'users' node

  List<Map<String, dynamic>> sentInvitations = [];

  @override
  void initState() {
    super.initState();
    _fetchSentInvitations();  // Lấy lời mời đã gửi từ Firebase
  }

  // Hàm lấy lời mời đã gửi từ Firebase
  void _fetchSentInvitations() {
    _database.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          sentInvitations = data.entries
              .where((entry) => entry.value["from"] == widget.userId) // Lọc theo userId đã đăng nhập
              .map((entry) => {
            "id": entry.key,
            "to": entry.value["to"],
            "timestamp": entry.value["timestamp"],
          })
              .toList();
        });

        // Fetch names for each "to" user
        _fetchUserNames();
      }
    });
  }

  void _fetchUserNames() async {
    for (var invitation in sentInvitations) {
      String userIdTo = invitation["to"];

      // Truy vấn để lấy thông tin người dùng cho 'to' userId
      final snapshot = await _usersDatabase.child(userIdTo).get();
      if (snapshot.exists) {
        setState(() {
          // Ép kiểu snapshot.value thành Map và truy cập 'fullName'
          var userMap = snapshot.value as Map<dynamic, dynamic>;
          var userName = userMap["fullName"];  // Thay đổi từ "name" thành "fullName"
          var AVT = userMap["AVT"];  // Lấy URL của ảnh đại diện
          // Cập nhật danh sách sentInvitations với tên người dùng và ảnh đại diện
          invitation["toName"] = userName;
          invitation["toAVT"] = AVT;
        });
      }
    }
  }

  // Hàm hủy lời mời kết bạn
  void _cancelInvitation(String invitationId) {
    _database.child(invitationId).remove(); // Xóa lời mời từ Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã hủy lời mời')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Hiển thị danh sách lời mời đã gửi
          sentInvitations.isEmpty
              ? const Center(child: Text("Không có lời mời nào."))
              : Expanded(
            child: ListView.builder(
              itemCount: sentInvitations.length,
              itemBuilder: (context, index) {
                var invitation = sentInvitations[index];
                // Safely access toName, providing a fallback if it's null
                String userName = invitation["toName"] ?? "Unknown User";
                String avatarUrl = invitation["toAVT"] ?? '';  // Lấy URL ảnh đại diện
                String timestamp = invitation["timestamp"] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                    invitation["timestamp"])
                    .toString()
                    : "Unknown Time";
                return ListTile(
                  leading: avatarUrl.isNotEmpty
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(avatarUrl),  // Hiển thị ảnh đại diện từ URL
                  )
                      : const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text('$userName'),
                  subtitle: Text(timestamp),
                  trailing: GestureDetector(
                    onTap: () => _cancelInvitation(invitation["id"]),  // Hành động hủy lời mời
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                      decoration: BoxDecoration(
                        color: Color(0xffF3F4F8),  // Màu xanh mà bạn yêu cầu giữ
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Thu hồi',  // Văn bản hiển thị là 'Hủy'
                        style: TextStyle(
                          color: Colors.black, // Màu chữ của nút giữ nguyên màu xanh như yêu cầu
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
