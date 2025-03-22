import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DaNhanView extends StatefulWidget {
  final String userId;
  const DaNhanView({super.key, required this.userId});

  @override
  State<DaNhanView> createState() => _DaNhanViewState();
}

class _DaNhanViewState extends State<DaNhanView> {
  final DatabaseReference _database =
  FirebaseDatabase.instance.ref("friendInvitation");
  final DatabaseReference _usersDatabase =
  FirebaseDatabase.instance.ref("users");

  List<Map<String, dynamic>> receivedInvitations = [];

  @override
  void initState() {
    super.initState();
    _fetchReceivedInvitations();
  }

  void _fetchReceivedInvitations() {
    _database.onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, dynamic>> tempInvitations = data.entries
            .where((entry) => entry.value["to"] == widget.userId)
            .map((entry) => {
          "id": entry.key,
          "from": entry.value["from"],
          "timestamp": entry.value["timestamp"],
          "to": entry.value["to"],
        })
            .toList();
        for (var invitation in tempInvitations) {
          String userIdFrom = invitation["from"];
          final snapshot = await _usersDatabase.child(userIdFrom).get();
          if (snapshot.exists) {
            var userMap = snapshot.value as Map<dynamic, dynamic>;
            var userName = userMap["fullName"];
            var AVT = userMap["AVT"];

            invitation["fromName"] = userName;
            invitation["fromAVT"] = AVT;
          }
        }
        setState(() {
          receivedInvitations = tempInvitations;
        });
      }
    });
  }

  void _acceptInvitation(String id, String idUser, String idFriend) {
    final DatabaseReference _database = FirebaseDatabase.instance.ref();
    _database.child("friendInvitation").child(id).remove().then((_) {
      _database.child("friends").child(idUser).child(idFriend).set(true);
      _database.child("friends").child(idFriend).child(idUser).set(true);
      String chatRoomId = idUser.hashCode <= idFriend.hashCode
          ? "${idUser}_$idFriend"
          : "${idFriend}_$idUser";
      _database.child("chatRooms").child(chatRoomId).once().then((snapshot) {
        if (snapshot.snapshot.value == null) {
          _database.child("chatRooms").child(chatRoomId).set({
            "members": {idUser: true, idFriend: true},
            "createdAt": DateTime.now().millisecondsSinceEpoch,
            "lastMessageTime" : DateTime.now().millisecondsSinceEpoch,
          });

          _database.child("messages").child(chatRoomId).push().set({
            "senderId": "system",
            "message": "Hãy trò chuyện với người bạn mới",
            "timestamp": DateTime.now().millisecondsSinceEpoch,
            "typeRoom": false,
          });
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chấp nhận lời mời và tạo phòng chat')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error')),
      );
    });
  }


  // Hàm từ chối lời mời
  void _rejectInvitation(String invitationId) {
    _database.child(invitationId).remove();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã từ chối lời mời')),
    );
  }

  String _formatTime(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ngày trước';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} giờ trước';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} phút trước';
    } else {
      return '${duration.inSeconds} giây trước';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: receivedInvitations.isEmpty
          ? const Center(child: Text("Không có lời mời nào."))
          : ListView.builder(
        itemCount: receivedInvitations.length,
        itemBuilder: (context, index) {
          var invitation = receivedInvitations[index];

          // Lấy tên và ảnh người gửi, nếu có
          String fromName = invitation["fromName"] ?? "Người dùng chưa xác định";
          String fromAVT = invitation["fromAVT"] ?? ""; // URL mặc định

          // Chuyển timestamp thành thời gian
          DateTime time = DateTime.fromMillisecondsSinceEpoch(invitation["timestamp"]);
          Duration difference = DateTime.now().difference(time);  // Tính sự khác biệt

          // Sử dụng hàm _formatTime để hiển thị thời gian
          String timeString = _formatTime(difference);

          return ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            title: Row(
              children: [
                // Hình ảnh avatar nằm bên trái
                fromAVT.isNotEmpty
                    ? CircleAvatar(
                  backgroundImage: NetworkImage(fromAVT), // Hiển thị ảnh đại diện từ URL
                )
                    : const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                // Khoảng cách giữa avatar và tên
                SizedBox(width: 10),
                // Tên người gửi và dòng "Muốn kết bạn" nằm cùng một row
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fromName), // Hiển thị tên người gửi
                      Text(
                        'Muốn kết bạn',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị thời gian nếu chưa quá 24h
                if (difference.inDays <= 1)
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            timeString, // Hiển thị thời gian tính được từ timeString
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                // Các nút "Thu hồi" và "Xác nhận"
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Thu hồi (Từ chối)
                    TextButton(
                      onPressed: () {
                        _rejectInvitation(invitation["id"]);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xffF3F4F8), // Màu nền cho nút Thu hồi
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 30), // Điều chỉnh chiều cao và chiều rộng
                        minimumSize: Size(1, 1), // Kích thước tối thiểu cho nút
                      ),
                      child: const Text(
                        'Thu hồi',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    // Khoảng cách giữa hai nút
                    SizedBox(width: 10),  // Khoảng cách giữa nút Thu hồi và Xác nhận
                    // Xác nhận
                    TextButton(
                      onPressed: () {
                        _acceptInvitation(invitation["id"], invitation["to"], invitation["from"]);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xff38EF7D), // Màu nền cho nút Xác nhận
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 25), // Điều chỉnh chiều cao và chiều rộng
                        minimumSize: Size(1, 1), // Kích thước tối thiểu cho nút
                      ),
                      child: Text(
                        'Xác nhận',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    // Thêm khoảng cách 10 đơn vị từ bên phải
                    SizedBox(width: 20),  // Khoảng cách từ cạnh phải của Row
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
