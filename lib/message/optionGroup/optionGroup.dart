import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chatonline/message/option/chatMedia.dart';
import 'package:chatonline/message/option/CreateGroup.dart';
import 'package:image_picker/image_picker.dart';
import 'addGroup.dart';
import 'groupDescription.dart';
import 'package:chatonline/HomePage.dart';
import 'groupMembers.dart';
import 'groupCalendar.dart';

class OptionGroup extends StatefulWidget {
  final String idFriend, idChatRoom, groupName, idUser, groupAvatar, description;
  final Function(bool) onSearchToggle;
  final List<String> member;
  final int numMembers;

  const OptionGroup({
    super.key,
    required this.idFriend,
    required this.idChatRoom,
    required this.onSearchToggle,
    required this.groupName,
    required this.idUser,
    required this.groupAvatar,
    required this.member,
    required this.description,
    required this.numMembers,
  });

  @override
  State<OptionGroup> createState() => OptionGroupState();
}

class OptionGroupState extends State<OptionGroup> {
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

  Future<void> handleChangeAvatar(BuildContext context, String idChatRoom) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        String fileName = "group_avatars/$idChatRoom.jpg";

        // Upload ảnh lên Firebase Storage
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        await storageRef.putFile(imageFile);

        // Lấy URL mới của ảnh
        String newAvatarUrl = await storageRef.getDownloadURL();

        // Cập nhật vào Realtime Database
        await FirebaseDatabase.instance.ref("chatRooms/$idChatRoom").update({
          'groupAvatar': newAvatarUrl
        });

        // Hiển thị thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ảnh nhóm đã được cập nhật!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi cập nhật ảnh nhóm: $error"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> handleChangeGroupName(BuildContext context, String idChatRoom, String currentName) async {
    TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi tên nhóm'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: "Nhập tên mới"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              String newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await FirebaseDatabase.instance.ref("chatRooms/$idChatRoom").update({
                  'groupName': newName
                });
                // Hiển thị thông báo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Tên nhóm đã được cập nhật!"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> leaveGroup({required String chatRoomId, required String userId, required bool silent,}) async {
    final database = FirebaseDatabase.instance.ref();
    final membersRef = database.child('chatRooms/$chatRoomId/members/$userId');
    await membersRef.remove();

    if (!silent) {
      final messagePath = 'chats/$chatRoomId/messages';
      final messagesRef = database.child(messagePath);

      final newMessageRef = messagesRef.push();
      await newMessageRef.set({
        'senderId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'typeChat': 'outGroup',
      });
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
          (route) => route.isFirst,
    );
  }

  void showLeaveGroupSheet(BuildContext context, String chatRoomId, String userId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: EdgeInsets.only(bottom: 16),
              ),
              // Title
              Text(
                "Tuỳ chọn rời nhóm",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),

              Divider(),

              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.exit_to_app, color: Colors.red),
                ),
                title: Text('Rời nhóm', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmLeave(context, chatRoomId, userId, silent: false);
                },
              ),

              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.exit_to_app_outlined, color: Colors.red),
                ),
                title: Text('Rời nhóm trong im lặng', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmLeave(context, chatRoomId, userId, silent: true);
                },
              ),

              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _confirmLeave(BuildContext context, String chatRoomId, String userId, {required bool silent}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận"),
        content: Text(silent
            ? "Bạn có chắc muốn rời nhóm trong im lặng không?"
            : "Bạn có chắc muốn rời nhóm không?"),
        actions: [
          TextButton(
            child: Text("Huỷ", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Xác nhận", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(context);
              await leaveGroup(
                chatRoomId: chatRoomId,
                userId: userId,
                silent: silent,
              );
            },
          ),
        ],
      ),
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
                  Stack(
                    children: [
                      widget.groupAvatar.isEmpty
                          ? SizedBox(
                        width: 50,
                        height: 50,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.group, color: Colors.white, size: 30),
                        ),
                      )
                          : CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(widget.groupAvatar),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            handleChangeAvatar(context ,widget.idChatRoom);
                          },
                          child: Container(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Baseline(
                        baseline: 18,
                        baselineType: TextBaseline.alphabetic,
                        child: Text(
                          widget.groupName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          handleChangeGroupName(context, widget.idChatRoom, widget.groupName);
                        },
                        child: Icon(Icons.edit_outlined, size: 17, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIconText(Icons.search_outlined, "Tìm tin nhắn", () {
                        Navigator.pop(context, true);
                      }),
                      _buildIconText(Icons.person_add_alt_1_outlined, "Thêm thành viên", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AddGroup(userId: widget.idUser, chatRoomId: widget.idChatRoom,member: List<String>.from(widget.member)),));
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

            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Icon(Icons.edit_note_outlined, color: Color(0xFF7B848D)),
                    title: Text('Thêm mô tả nhóm'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDescription(
                            groupAvatar: widget.groupAvatar,
                            groupName: widget.groupName,
                            groupID: widget.idChatRoom,
                          ),
                        ),
                      );
                    },
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  ),
                  if (widget.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 58, right: 0, top: 0),
                      child: Text(
                        widget.description,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
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
                    leading: Icon(Icons.event, color: Color(0xFF7B848D)), // Icon lịch
                    title: Text('Lịch nhóm'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupCalendar(userId: widget.idUser, chatRoomId: widget.idChatRoom)
                        ),
                      );
                    },
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.push_pin, color: Color(0xFF7B848D)), // Icon ghim
                    title: Text('Tin nhắn đã ghim'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {
                      // Xử lý thêm widget.idFriend vào nhóm
                    },
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.how_to_vote, color: Color(0xFF7B848D)), // Icon bình chọn
                    title: Text('Bình chọn'),
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
                    leading: Icon(Icons.group, color: Color(0xFF7B848D)),
                    title: Text('Xem thành viên (${widget.numMembers})'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupMembers(
                            numMembers: widget.numMembers,
                            member: widget.member,
                            chatRoomId: widget.idChatRoom,
                            userId: widget.idUser,
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.link, color: Color(0xFF7B848D)), // Icon link nhóm
                    title: Text('Link nhóm'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onTap: () {

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

                    },
                  ),

                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Color(0xFF7B848D)),
                    title: Text('Xóa lịch sử trò chuyện', style: TextStyle(color: Colors.black)),
                    onTap: () {

                    },
                  ),

                  Divider(thickness: 1, color: Colors.black12, indent: 56),

                  ListTile(
                    leading: Icon(Icons.exit_to_app, color: Colors.red),
                    title: Text('Rời nhóm', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      showLeaveGroupSheet(context, widget.idChatRoom, widget.idUser);
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