import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chatonline/message/option/personalPage/personalPageF.dart';
import 'package:chatonline/message/option/personalPage/changeNickname.dart';
import 'package:chatonline/message/option/chatMedia.dart';
import 'package:chatonline/message/option/CreateGroup.dart';
import 'package:chatonline/message/option/personalPage/ReportUser.dart';

class OptionMessage extends StatefulWidget {
  final String idFriend, idChatRoom, nickName, idUser, avt;
  final Function(bool) onSearchToggle;
  final bool isFriend;

  const OptionMessage({
    super.key,
    required this.idFriend,
    required this.idChatRoom,
    required this.onSearchToggle,
    required this.nickName,
    required this.idUser,
    required this.avt,
    required this.isFriend,
  });

  @override
  State<OptionMessage> createState() => _OptionMessageState();
}

class _OptionMessageState extends State<OptionMessage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? userData;
  bool isPinned = false;
  bool isHidden = false;
  bool isCallNotificationOn = true;
  bool isBestFriend = false;
  bool isChatPin = false;
  bool isHideChat = false;
  bool isIncomingCall = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    checkBestFriendStatus();
    checkChatPinStatus();
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

  void checkChatPinStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("ChatPin/${widget.idUser}/${widget.idFriend}");
    DatabaseEvent event = await ref.once();

    if (event.snapshot.exists && event.snapshot.value != null) {
      setState(() {
        isChatPin = event.snapshot.value as bool;
      });
    } else {
      setState(() {
        isChatPin = true;
      });
    }
  }

  void toggleChatPin(bool value) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("ChatPin/${widget.idUser}/${widget.idFriend}");

    if (value) {
      await ref.set(true);
    } else {
      await ref.set(false);
    }

    setState(() {
      isChatPin = value;
    });
  }

  void checkHideChatStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("HideChat/${widget.idUser}/${widget.idFriend}");
    DatabaseEvent event = await ref.once();

    if (event.snapshot.exists && event.snapshot.value != null) {
      setState(() {
        isHideChat = event.snapshot.value as bool;
      });
    } else {
      setState(() {
        isHideChat = true;
      });
    }
  }

  void toggleHideChat(bool value) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("HideChat/${widget.idUser}/${widget.idFriend}");

    if (value) {
      await ref.set(true);
    } else {
      await ref.set(false);
    }

    setState(() {
      isHideChat = value;
    });
  }

  void checkIncomingCallStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("IncomingCall/${widget.idUser}/${widget.idFriend}");
    DatabaseEvent event = await ref.once();

    if (event.snapshot.exists && event.snapshot.value != null) {
      setState(() {
        isIncomingCall = event.snapshot.value as bool;
      });
    } else {
      setState(() {
        isIncomingCall = true;
      });
    }
  }

  void toggleIncomingCall(bool value) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("IncomingCall/${widget.idUser}/${widget.idFriend}");

    if (value) {
      await ref.set(true);
    } else {
      await ref.set(false);
    }

    setState(() {
      isIncomingCall = value;
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

  Future<List<String>> fetchImageMessages() async {
    DatabaseReference messagesRef =
    FirebaseDatabase.instance.ref("chats/${widget.idChatRoom}/messages");
    DataSnapshot snapshot = await messagesRef.get();
    List<Map<String, dynamic>> messages = [];
    if (snapshot.exists) {
      for (var child in snapshot.children) {
        Map<dynamic, dynamic> data = child.value as Map<dynamic, dynamic>;
        if (
            data['typeChat'] == 'image'
        ) {
          if(data['urlFile'] != null && data.containsKey('timestamp')){
            messages.add({
              'urlFile': data['urlFile'],
              'timestamp': data['timestamp'] ?? 0,
            });
          }
        }
      }
    }
    messages.sort((a, b) => (b['timestamp']).compareTo(a['timestamp']));
    List<String> imageUrls = messages.map((e) => e['urlFile'] as String).toList();
    return imageUrls;
  }

  void showBlockBottomSheet(BuildContext context) {
    bool blockMessages = false;
    bool blockCalls = false;
    bool blockAndHideLogs = false;
    bool isLoading = true;

    // Thêm các biến để lưu trạng thái ban đầu từ Firebase
    bool initialBlockMessages = false;
    bool initialBlockCalls = false;
    bool initialBlockAndHideLogs = false;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (isLoading) {
              FirebaseDatabase.instance
                  .ref()
                  .child('blockList')
                  .child(widget.idUser)
                  .child(widget.idFriend)
                  .once()
                  .then((DatabaseEvent event) {
                final data = event.snapshot.value as Map?;
                if (data != null) {
                  initialBlockMessages = data['blockMessages'] ?? false;
                  initialBlockCalls = data['blockCalls'] ?? false;
                  initialBlockAndHideLogs = data['blockAndHideLogs'] ?? false;

                  blockMessages = initialBlockMessages;
                  blockCalls = initialBlockCalls;
                  blockAndHideLogs = initialBlockAndHideLogs;
                }
                setState(() {
                  isLoading = false;
                });
              });
            }

            // So sánh với trạng thái ban đầu
            bool hasChanged =
                blockMessages != initialBlockMessages ||
                    blockCalls != initialBlockCalls ||
                    blockAndHideLogs != initialBlockAndHideLogs;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Quản lý chặn ${widget.nickName}",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Divider(),
                  CheckboxListTile(
                    value: blockMessages,
                    onChanged: (value) {
                      setState(() {
                        blockMessages = value!;
                      });
                    },
                    activeColor: Colors.green,
                    title: Text('Chặn tin nhắn'),
                    secondary: Icon(Icons.message, color: Color(0xFF7B848D)),
                  ),
                  CheckboxListTile(
                    value: blockCalls,
                    onChanged: (value) {
                      setState(() {
                        blockCalls = value!;
                      });
                    },
                    activeColor: Colors.green,
                    title: Text('Chặn cuộc gọi'),
                    secondary: Icon(Icons.call, color: Color(0xFF7B848D)),
                  ),
                  CheckboxListTile(
                    value: blockAndHideLogs,
                    onChanged: (value) {
                      setState(() {
                        blockAndHideLogs = value!;
                      });
                    },
                    activeColor: Colors.green,
                    title: Text('Chặn và ẩn nhật ký'),
                    secondary: Icon(Icons.visibility_off, color: Color(0xFF7B848D)),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: hasChanged
                        ? () async {
                      Navigator.pop(context);
                      DatabaseReference blockRef =
                      FirebaseDatabase.instance
                          .ref()
                          .child('blockList')
                          .child(widget.idUser)
                          .child(widget.idFriend);

                      await blockRef.set({
                        'blockMessages': blockMessages,
                        'blockCalls': blockCalls,
                        'blockAndHideLogs': blockAndHideLogs,
                      });
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor:
                      hasChanged ? Colors.green : Colors.grey,
                    ),
                    child: Text(
                      'Áp dụng',
                      style: TextStyle(
                        color: hasChanged ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text('Tùy chọn', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 27),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: userData?['AVT'] != null && userData!['AVT'].isNotEmpty
                        ? NetworkImage(userData!['AVT'])
                        : null,
                    child: (userData?['AVT'] == null || userData!['AVT'].isEmpty)
                        ? Icon(Icons.person, size: 50, color: Colors.grey,)
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.nickName ?? userData!['fullName'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  userData?['bio'] != null && userData!['bio'].isNotEmpty
                      ? Text(
                    '${userData!['bio']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  )
                      : SizedBox.shrink(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIconText(Icons.search_outlined, "Tìm tin nhắn", () {
                        Navigator.pop(context, true);
                      }),
                      _buildIconText(Icons.person_outline_outlined, "Trang cá nhân", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              PersonalPage(
                                idFriend: widget.idFriend,
                                idChatRoom: widget.idChatRoom,
                                nickName: widget.nickName,
                                idUser: widget.idUser,
                                avt: widget.avt,
                                isFriend: widget.isFriend,
                              )),
                        );
                      }),
                      _buildIconText(Icons.image_outlined, "Đổi hình nền", () {
                        print("Nhấn vào Đổi hình nền");
                      }),
                      _buildIconText(Icons.notifications_outlined, "Tắt thông báo", () {
                        print("Nhấn vào Tắt thông báo");
                      }),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),

            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit, color: Color(0xFF7B848D)), // Màu mới
                    title: Text('Đổi tên gợi nhớ'),
                    onTap: () {
                      _openEditNameBottomSheet();
                    },
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  StatefulBuilder(
                    builder: (context, setState) {
                      return ListTile(
                        leading: Icon(Icons.favorite, color: Color(0xFF7B848D)), // Màu mới
                        title: Text('Đánh dấu bạn thân'),
                        trailing: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isBestFriend,
                            activeColor: const Color(0xFF11998E),
                            onChanged: (bool value) {
                              toggleBestFriend(value);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),

            GestureDetector(
              onTap: () async {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ChatMedia(idChatRoom: widget.idChatRoom, idUser: widget.idUser))
                );
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(Icons.insert_drive_file, color: Color(0xFF7B848D)),
                      title: Text('Ảnh, link, file'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    ),
                    FutureBuilder<List<String>>(
                      future: fetchImageMessages(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox();
                        }

                        List<String> imageUrls = snapshot.data!;
                        int totalImages = imageUrls.length;
                        int displayedImages = totalImages > 4 ? 4 : totalImages;

                        if (totalImages == 0) return SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(displayedImages, (index) {
                              return GestureDetector(
                                onTap: () => {
                                Navigator.push(
                                    context,
                                  MaterialPageRoute(builder: (context) => ChatMedia(idChatRoom: widget.idChatRoom, idUser: widget.idUser))
                                  )
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrls[index],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (index == 3 && totalImages > 4)
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "+${totalImages - 4}",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 8),

            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.group_add, color: Color(0xFF7B848D)), // Màu mới
                    title: Text('Tạo nhóm với ${userData!['fullName']}'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {
                      Navigator.push(context, 
                          MaterialPageRoute(builder: (context) => CreateGroupScreen(userId: widget.idUser, friendId: widget.idFriend,))
                      );
                    },
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.person_add, color: Color(0xFF7B848D)), // Màu mới
                    title: Text('Thêm ${userData!['fullName']} vào nhóm'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {
                      // Xử lý thêm widget.idFriend vào nhóm
                    },
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.group, color: Color(0xFF7B848D)), // Màu mới
                    title: Text('Xem nhóm chung'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {
                      // Xử lý xem nhóm chung với widget.idFriend
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),

            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.push_pin, color: Color(0xFF7B848D)), // Màu mới
                    title: Text('Ghim trò chuyện'),
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isChatPin,
                        activeColor: const Color(0xFF11998E),
                        onChanged: (bool value) {
                          toggleChatPin(value);
                        },
                      ),
                    ),
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.visibility_off, color: Color(0xFF7B848D)), // Màu mới
                    title: Text('Ẩn trò chuyện'),
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isHideChat,
                        activeColor: const Color(0xFF11998E),
                        onChanged: (bool value) {
                          toggleHideChat(value);
                        },
                      ),
                    ),
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.call, color: Color(0xFF7B848D)), // Màu mới
                    title: Text('Báo cuộc gọi đến'),
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isIncomingCall,
                        activeColor: const Color(0xFF11998E),
                        onChanged: (bool value) {
                          toggleIncomingCall(value);
                        },
                      ),
                    ),
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.settings, color: Color(0xFF7B848D)),
                    title: Text('Cài đặt cá nhân'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {
                      // Chuyển đến trang cài đặt cá nhân
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),

            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.report, color: Color(0xFF7B848D)),
                    title: Text('Báo xấu', style: TextStyle(color: Colors.black)),
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
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56), // Thụt vào ngang với text

                  ListTile(
                    leading: Icon(Icons.block, color: Color(0xFF7B848D)), // Màu mới
                    title: Text('Quản lý chặn'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {
                      showBlockBottomSheet(context);
                    },
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Color(0xFF7B848D)), // Màu mới
                    title: Text('Xóa lịch sử trò chuyện', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      // Xử lý xóa lịch sử trò chuyện
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

Widget _buildIconText(IconData icon, String label, VoidCallback onTap) {
  List<String> words = label.split(" ");
  String formattedLabel;
  if (words.length == 2) {
    formattedLabel = "${words[0]}\n${words[1]}";
  } else if (words.length == 3) {
    formattedLabel = "${words[0]}\n${words[1]} ${words[2]}";
  } else {
    formattedLabel = label;
  }
  return Column(
    children: [
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          splashColor: Colors.grey.withOpacity(0.3),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFFF7F7F7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 25, color: Colors.black),
            ),
          ),
        ),
      ),
      SizedBox(height: 5),
      Text(
        formattedLabel,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ],
  );
}