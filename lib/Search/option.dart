import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chatonline/message/Option/personalPage/information.dart';
import 'package:chatonline/message/Option/personalPage/ReportUser.dart';

class OptionSearch extends StatefulWidget {
  final String idFriend;
  final String nickName;
  final String idUser;
  final bool isFriend;


  const OptionSearch({
    super.key,
    required this.idFriend,
    required this.nickName,
    required this.idUser,
    required this.isFriend,
  });

  @override
  State<OptionSearch> createState() => _OptionSearchState();
}

class _OptionSearchState extends State<OptionSearch> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _sendFriendRequest(BuildContext context) {
    final DatabaseReference friendRequestRef = FirebaseDatabase.instance.ref("friendInvitation");

    final Map<String, dynamic> friendRequestData = {
      "from": widget.idUser,
      "to": widget.idFriend,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    friendRequestRef.push().set(friendRequestData).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lời mời kết bạn đã được gửi')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi khi gửi lời mời')),
      );
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(
          widget.nickName ?? userData?['fullName'],
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 27),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Colors.white,
              child: Column(
                children: [

                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Xác nhận"),
                            content: Text("Bạn có chắc chắn muốn gửi lời mời kết bạn không?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Đóng dialog
                                },
                                child: Text("Hủy"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Đóng dialog
                                  _sendFriendRequest(context); // Gửi lời mời kết bạn
                                },
                                child: Text("Đồng ý"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Kết bạn",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Information(
                            idFriend: widget.idFriend,
                            idChatRoom: '',
                            nickName: widget.nickName,
                            isFriend: widget.isFriend,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Thông tin",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportUserScreen(
                            idUser: widget.idUser,
                            idFriend: widget.idFriend,
                            type: "account report",
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Báo xấu",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),


                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
                  ),

                  InkWell(
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => ReportUserScreen(
                      //       idUser: widget.idUser,
                      //       idFriend: widget.idFriend,
                      //       type: "account report",
                      //     ),
                      //   ),
                      // );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Quản lý chặn",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}