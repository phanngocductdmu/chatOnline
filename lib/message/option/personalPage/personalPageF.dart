import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chatonline/message/option/personalPage/option.dart';
import 'package:chatonline/message/call/call.dart';
import 'package:chatonline/User/postItem.dart';
import 'SeePhotos.dart';
import 'package:chatonline/Search/option.dart';
import 'package:chatonline/message/nhan_tin.dart';

class PersonalPage extends StatefulWidget {
  final String idFriend, idChatRoom, nickName, idUser, avt;
  final bool isFriend;

  const PersonalPage({
    super.key,
    required this.idFriend,
    required this.idChatRoom,
    required this.nickName,
    required this.idUser,
    required this.avt,
    required this.isFriend
  });

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? userData;
  bool isBlockLogs = false;
  bool isHideDiary = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    checkBlockLogsStatus();
  }

  Stream<Map<String, dynamic>> fetchUserPosts() {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref("posts");

    return dbRef.onValue.map((event) {
      if (event.snapshot.value == null) return {"posts": [], "imageCount": 0, "videoCount": 0};

      Map<dynamic, dynamic> posts = event.snapshot.value as Map<dynamic, dynamic>;

      List<Map<String, dynamic>> userPosts = posts.entries
          .where((entry) => entry.value["userId"] == widget.idFriend)
          .where((entry) => entry.value["privacy"] != "Chỉ mình tôi")
          .map((entry) {
        Map<dynamic, dynamic>? likes = entry.value["likes"] as Map<dynamic, dynamic>?;

        return {
          "id": entry.key,
          "fileUrl": entry.value["fileUrl"],
          "text": entry.value["text"],
          "timestamp": entry.value["timestamp"],
          "type": entry.value["type"],
          "userId": entry.value["userId"],
          "privacy": entry.value["privacy"],
          "likes": likes != null ? likes.keys.toList() : [],
          "likeCount": likes?.length ?? 0,
        };
      }).toList()
        ..sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

      int imageCount = userPosts.where((post) => post["type"] == "image").length;
      int videoCount = userPosts.where((post) => post["type"] == "video").length;

      return {"posts": userPosts, "imageCount": imageCount, "videoCount": videoCount};
    });
  }


  Future<int> fetchUserImageCount() async {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref("posts");

    try {
      DatabaseEvent event = await dbRef.once();
      if (event.snapshot.value == null) return 0;
      Map<dynamic, dynamic> posts = event.snapshot.value as Map<dynamic, dynamic>;

      int imageCount = posts.entries
          .where((entry) => entry.value["userId"] == widget.idFriend && entry.value["type"] == "image")
          .length;

      return imageCount;
    } catch (e) {
      print("Lỗi khi lấy số lượng ảnh: $e");
      return 0;
    }
  }

  Future<int> fetchUserVideoCount() async {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref("posts");
    try {
      DatabaseEvent event = await dbRef.once();
      if (event.snapshot.value == null) return 0;

      Map<dynamic, dynamic> posts = event.snapshot.value as Map<dynamic, dynamic>;

      int imageCount = posts.entries
          .where((entry) => entry.value["userId"] == widget.idFriend && entry.value["type"] == "video")
          .length;

      return imageCount;
    } catch (e) {
      print("Lỗi khi lấy số lượng ảnh: $e");
      return 0;
    }
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

  void checkBlockLogsStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("BlockLogs/${widget.idUser}/${widget.idFriend}");
    ref.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        setState(() {
          isBlockLogs = event.snapshot.value as bool;
        });
      } else {
        setState(() {
          isBlockLogs = false;
        });
      }
    });
  }

  void checkHideDiaryStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("HideDiary/${widget.idUser}/${widget.idFriend}");
    ref.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        setState(() {
          isHideDiary = event.snapshot.value as bool;
        });
      } else {
        setState(() {
          isHideDiary = false;
        });
      }
    });
  }

  void toggleBlockLogs(bool value) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("BlockLogs/${widget.idUser}/${widget.idFriend}");
    await ref.set(value);
  }

  void toggleHideDiary(bool value) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("HideDiary/${widget.idUser}/${widget.idFriend}");
    await ref.set(value);
  }

  void _openUserSettingsBottomSheet(BuildContext context) {
    checkBlockLogsStatus();
    checkHideDiaryStatus();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tiêu đề "Cài đặt riêng tư"
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text(
                          "Cài đặt riêng tư",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(), // Đường kẻ ngăn cách

                  // Chặn xem nhật ký của tôi
                  ListTile(
                    leading: const Icon(Icons.block, color: Colors.grey),
                    title: const Text("Chặn xem nhật ký của tôi"),
                    trailing: Transform.scale(
                      scale: 0.8, // Giảm kích thước switch
                      child: Switch(
                        value: isBlockLogs,
                        activeColor: const Color(0xFF11998E), // Màu xanh gradient
                        onChanged: (value) {
                          setState(() {
                            toggleBlockLogs(value);
                          });
                        },
                      ),
                    ),
                  ),

                  // Ẩn nhật ký của người này
                  ListTile(
                    leading: const Icon(Icons.visibility_off, color: Colors.grey),
                    title: const Text("Ẩn nhật ký của người này"),
                    trailing: Transform.scale(
                      scale: 0.8, // Giảm kích thước switch
                      child: Switch(
                        value: isHideDiary,
                        activeColor: const Color(0xFF11998E),
                        onChanged: (value) {
                          setState(() {
                            toggleHideDiary(value);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> fetchUserInfo() async {
    try {
      DatabaseReference userRef = FirebaseDatabase.instance.ref("users/${widget.idFriend}");
      DataSnapshot snapshot = await userRef.get();
      if (!snapshot.exists) return null;
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      print("Lỗi khi lấy dữ liệu người dùng: $e");
      return null;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6F8),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text("Không thể tải thông tin"));
          }
          Map<String, dynamic> userData = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildCoverImage(userData),
                    _buildHeader(),
                    Positioned(
                      bottom: -30,
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      child: IgnorePointer(
                        ignoring: false,
                        child: _buildAvatar(userData),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _buildUserInfo(userData),
                const SizedBox(height: 10),
                !(widget.isFriend ?? false) ? _buildAction() : _buildActionButtons(),
                const SizedBox(height: 10),
                !(widget.isFriend ?? false) ? SizedBox() : _buildUserPosts(userData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoverImage(Map<String, dynamic> userData) {
    return GestureDetector(
      onTap: () {
        if (userData['Bia'] != null && userData['Bia'].isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeePhotos(idFriend: widget.idFriend, avt: userData['Bia']),
            ),
          );
        }
      },
      child: SizedBox(
        width: double.infinity,
        height: 250,
        child: userData['Bia'] != null && userData['Bia'].isNotEmpty
            ? Image.network(
          userData['Bia'],
          fit: BoxFit.cover,
        )
            : Container(
          color: Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> userData) {
    String? avatarUrl = userData['AVT'];
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeePhotos(idFriend: widget.idFriend, avt: avatarUrl),
              ),
            );
          }
        },
        child: CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFFF5F6F8),
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? CircleAvatar(
            radius: 48,
            backgroundImage: NetworkImage(avatarUrl),
          )
              : CircleAvatar(
            radius: 48,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, color: Colors.white, size: 50),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(Map<String, dynamic> userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          userData['fullName'] ?? "",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: !widget.isFriend
              ? Text(
            'Bạn chưa thể xem nhật ký của ${userData['fullName']} khi chưa là bạn bè',
            style: TextStyle(fontSize: 14, color: Colors.black),
            textAlign: TextAlign.center,
            softWrap: true,
          )
              : (userData['bio'] == null || userData['bio'].toString().isEmpty)
              ? SizedBox()
              : Text(
            userData['bio'],
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 27),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Call(
                    chatRoomId: widget.idChatRoom,
                    idFriend: widget.idFriend,
                    avt: widget.avt,
                    fullName: widget.nickName,
                    userId: widget.idUser
                )),
              );
            },
          ),
          widget.isFriend
              ? IconButton(
            icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white),
            onPressed: () => _openUserSettingsBottomSheet(context),
          )
              : SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.more_horiz_outlined, color: Colors.white),
            onPressed: () {
              if(widget.isFriend){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Option(
                      idFriend: widget.idFriend,
                      idChatRoom: widget.idChatRoom,
                      nickName: widget.nickName,
                      idUser: widget.idUser,
                    ),
                  ),
                );
              }else{
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OptionSearch(
                      idFriend: widget.idFriend,
                      nickName: widget.nickName,
                      idUser: widget.idUser,
                      isFriend: widget.isFriend,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserPosts(Map<String, dynamic> userData) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: fetchUserPosts(),
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox();
        }
        if (postSnapshot.hasError || postSnapshot.data == null || postSnapshot.data!["posts"] == null || postSnapshot.data!["posts"].isEmpty) {
          return SizedBox();
        }

        List<Map<String, dynamic>> posts = List<Map<String, dynamic>>.from(postSnapshot.data!["posts"]);

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return PostItem(
              post: posts[index],
              avt: userData['AVT'],
              fullName: userData['fullName'],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: StreamBuilder<Map<String, dynamic>>(
          stream: fetchUserPosts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            int imageCount = snapshot.data?["imageCount"] ?? 0;
            int videoCount = snapshot.data?["videoCount"] ?? 0;

            return Row(
              children: [
                Expanded(child: _buildButton(Icons.photo_library, "Ảnh", imageCount, Colors.blueAccent)),
                SizedBox(width: 10),
                Expanded(child: _buildButton(Icons.video_library, "Video", videoCount, Colors.green)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAction() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: Row(
          children: [
            // Nhắn tin (80%)
            Expanded(
              flex: 5,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context,
                    MaterialPageRoute(builder:
                      (context) => NhanTin(
                        chatRoomId: '',
                        idFriend: widget.idFriend,
                        avt: widget.avt,
                        fullName: widget.nickName,
                        userId: widget.idUser,
                        typeRoom: false,
                        groupAvatar: '',
                        groupName: '',
                        numMembers: 0,
                        member: [],
                        description: "",
                        isFriend: widget.isFriend,
                      ),
                    )
                  );
                },
                icon: Icon(Icons.chat_outlined, color: Color(0xFF11998e)),
                label: Text("Nhắn tin", style: TextStyle(color: Color(0xFF11998e))),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xff97d6c4)),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: Icon(Icons.person_add_alt, color: Colors.grey[700], size: 23),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, int quantity, Color color) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              quantity > 0 ? "$label $quantity" : label,
              style: TextStyle(color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}