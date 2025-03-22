import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chatonline/message/option/personalPage/information.dart';
import 'changeNickname.dart';
import 'ReportUser.dart';

class Option extends StatefulWidget {
  final String idFriend;
  final String idChatRoom;
  final String nickName;
  final String idUser;

  const Option({
    super.key,
    required this.idFriend,
    required this.idChatRoom,
    required this.nickName,
    required this.idUser,
  });

  @override
  State<Option> createState() => _OptionState();
}

class _OptionState extends State<Option> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? userData;
  bool isBestFriend = false;
  bool isNotification = true;
  bool isBlockLogs = false;
  bool isHideDiary = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    checkBestFriendStatus();
    checkNotificationStatus();
    checkBlockLogsStatus();
    checkHideDiaryStatus();
  }

  void checkBlockLogsStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("BlockLogs/${widget.idUser}/${widget.idFriend}");
    DatabaseEvent event = await ref.once();

    if (event.snapshot.exists && event.snapshot.value != null) {
      setState(() {
        isBlockLogs = event.snapshot.value as bool;
      });
    } else {
      setState(() {
        isBlockLogs = false;
      });
    }
  }

  void toggleBlockLogs(bool value) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("BlockLogs/${widget.idUser}/${widget.idFriend}");

    if (value) {
      await ref.set(true);
    } else {
      await ref.set(false);
    }

    setState(() {
      isBlockLogs = value;
    });
  }

  void checkHideDiaryStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("HideDiary/${widget.idUser}/${widget.idFriend}");
    DatabaseEvent event = await ref.once();

    if (event.snapshot.exists && event.snapshot.value != null) {
      setState(() {
        isHideDiary = event.snapshot.value as bool;
      });
    } else {
      setState(() {
        isHideDiary = false;
      });
    }
  }

  void toggleHideDiary(bool value) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("HideDiary/${widget.idUser}/${widget.idFriend}");

    if (value) {
      await ref.set(true);
    } else {
      await ref.set(false);
    }

    setState(() {
      isHideDiary = value;
    });
  }

  void checkNotificationStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("Notification/${widget.idUser}/${widget.idFriend}");
    DatabaseEvent event = await ref.once();
    setState(() {
      isNotification = event.snapshot.exists;
    });
  }

  void toggleNotification(bool value) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("Notification/${widget.idUser}/${widget.idFriend}");

    if (value) {
      await ref.set(true);
    } else {
      await ref.set(false);
    }

    setState(() {
      isNotification = value;
    });
  }

  void checkBestFriendStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("bestFriends/${widget.idUser}/${widget.idFriend}");
    DatabaseEvent event = await ref.once();

    if (event.snapshot.exists && event.snapshot.value != null) {
      setState(() {
        isBestFriend = event.snapshot.value as bool;
      });
    } else {
      setState(() {
        isBestFriend = false;
      });
    }
  }

  void toggleBestFriend(bool value) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("bestFriends/${widget.idUser}/${widget.idFriend}");

    if (value) {
      await ref.set(true);
    } else {
      await ref.set(false);
    }

    setState(() {
      isBestFriend = value;
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Information(
                            idFriend: widget.idFriend,
                            idChatRoom: widget.idChatRoom,
                            nickName: widget.nickName,
                            isFriend: true,
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
                      _openEditNameBottomSheet();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Đổi tên gợi nhớ",
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
                      print("Nhấn Đánh dấu bạn thân");
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Đánh dấu bạn thân",
                            style: TextStyle(color: Colors.black),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: isBestFriend,
                                  activeColor: const Color(0xFF11998E),
                                  onChanged: (bool value) {
                                    toggleBestFriend(value);
                                  },
                                ),
                              ),
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


                  // Giới thiệu bạn thân
                  InkWell(
                    onTap: () {
                      print("Nhấn Giới thiệu cho bạn");
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Giới thiệu cho bạn",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Thông báo",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF11998E),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 4,
                        child: const Text(
                          "Nhận thông báo về hoạt động mới của người này",
                          softWrap: true, // Cho phép xuống dòng
                          overflow: TextOverflow.visible, // Hiển thị đầy đủ văn bản
                        ),
                      ),
                      Expanded(
                        flex: 1, // 20% tổng chiều rộng
                        child: Align(
                          alignment: Alignment.centerRight, // Căn phải switch
                          child: Transform.scale(
                            scale: 0.8, // Giảm kích thước switch
                            child: Switch(
                              value: isNotification,
                              activeColor: const Color(0xFF11998E), // Đổi màu switch
                              onChanged: (bool value) {
                                toggleNotification(value);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Cài đặt riêng tư",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF11998E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 4,
                        child: const Text(
                          "Chặn xem nhật ký của tôi",
                          softWrap: true, // Cho phép xuống dòng
                          overflow: TextOverflow.visible, // Hiển thị đầy đủ văn bản
                        ),
                      ),
                      Expanded(
                        flex: 1, // 20% tổng chiều rộng
                        child: Align(
                          alignment: Alignment.centerRight, // Căn phải switch
                          child: Transform.scale(
                            scale: 0.8, // Giảm kích thước switch
                            child: Switch(
                              value: isBlockLogs,
                              activeColor: const Color(0xFF11998E), // Đổi màu switch
                              onChanged: (bool value) {
                                toggleBlockLogs(value);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 4, // 80% tổng chiều rộng
                        child: const Text(
                          "Ẩn nhật ký của người này",
                          softWrap: true, // Cho phép xuống dòng nếu vượt quá giới hạn
                          overflow: TextOverflow.visible, // Hiển thị đầy đủ văn bản
                        ),
                      ),
                      Expanded(
                        flex: 1, // 20% tổng chiều rộng
                        child: Align(
                          alignment: Alignment.centerRight, // Căn phải switch
                          child: Transform.scale(
                            scale: 0.8, // Giảm kích thước switch
                            child: Switch(
                              value: isHideDiary,
                              activeColor: const Color(0xFF11998E), // Đổi màu switch
                              onChanged: (bool value) {
                                toggleHideDiary(value);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Colors.white,
              child: Column(
                children: [
                  // Thông tin (Sửa lại từ Expanded thành ElevatedButton)
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

                  // Đổi tên gợi nhớ
                  InkWell(
                    onTap: () {
                      print("Nhấn Báo xấu");
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Xóa bạn",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
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