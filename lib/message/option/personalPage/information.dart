import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'changeNickname.dart';

class Information extends StatefulWidget {
  final String idFriend, idChatRoom, nickName;
  final bool isFriend;

  const Information({super.key, required this.idFriend, required this.idChatRoom, required this.nickName, required this.isFriend});

  @override
  State<Information> createState() => _InformationState();
}

class _InformationState extends State<Information> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? userData;
  TextEditingController nameController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() {
    _database.child('users').child(widget.idFriend).onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          userData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  // Hàm mở BottomSheet để chỉnh sửa tên
  void _openEditNameBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ChangeNickname(nickName: widget.nickName, idChatRoom: widget.idChatRoom, idFriend: widget.idFriend);
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6F8),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // Ảnh bìa
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: (userData!['Bia'] == null || userData!['Bia'].toString().isEmpty)
                    ? Colors.grey
                    : null, // Nếu có ảnh thì không cần màu nền
                image: (userData!['Bia'] != null && userData!['Bia'].toString().isNotEmpty)
                    ? DecorationImage(
                  image: NetworkImage(userData!['Bia']),
                  fit: BoxFit.cover,
                )
                    : null, // Nếu không có ảnh, bỏ luôn DecorationImage
              ),
            ),
          ),

          // AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: kToolbarHeight + 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: AppBar(
                leading: IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.white, size: 27),
                  onPressed: () => Navigator.pop(context),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
          ),
          // Nội dung chính
          Column(
            children: [
              const SizedBox(height: 170),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: (userData!['AVT'] != null && userData!['AVT'].toString().isNotEmpty)
                                ? NetworkImage(userData!['AVT'])
                                : null,
                            child: (userData!['AVT'] == null || userData!['AVT'].toString().isEmpty)
                                ? Icon(Icons.person, size: 30, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.nickName ?? userData!['fullName'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        widget.isFriend
                            ? GestureDetector(
                          onTap: _openEditNameBottomSheet,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mode_edit_outline_outlined,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        )
                            : SizedBox()
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thông tin cá nhân",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.person, "Giới tính", widget.isFriend ? userData!['gender'] ?? "Người dùng chưa cập nhật" : "***"),
                      _divider(),
                      _buildInfoRow(Icons.cake, "Ngày sinh", widget.isFriend ? userData!['namSinh'] ?? "Người dùng chưa cập nhật" : "*******"),
                      _divider(),
                      _buildInfoRow(Icons.email, "Email", widget.isFriend ? userData!['email'] ?? "Người dùng chưa cập nhật" : "************"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black, size: 24),
              const SizedBox(width: 10),
              Text(
                "$title:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      thickness: 1,
      height: 15,
      color: Color(0xFFF3F4F6),
    );
  }
}
