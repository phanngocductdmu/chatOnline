import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatonline/message/message.dart';
import 'package:chatonline/message/message_item.dart';
import 'package:chatonline/Search/TimKiem.dart';
import 'package:intl/intl.dart';

class Mess extends StatefulWidget {
  const Mess({super.key});

  @override
  State<Mess> createState() => _MessState();
}

class _MessState extends State<Mess> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? idUser;
  List<Map<String, dynamic>> chatRooms = [];
  List<String> _friends = [];

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

    if (idUser != null) {
      _fetchChatRooms();
      _loadFriends();
    }
  }

  Future<void> _loadFriends() async {
    if (idUser == null) return;
    _database.child("friends/$idUser").onValue.listen((event) {
      if (event.snapshot.value != null) {
        var data = event.snapshot.value as Map<dynamic, dynamic>;
        List<String> friendIds = data.keys.map((key) => key.toString().trim()).toList();

        setState(() {
          _friends = friendIds;
        });
      }
      // print("Danh sách bạn bè đã tải: $_friends");
    });
  }


  void _fetchChatRooms() {
    _database.child('chatRooms').onValue.listen((event) {
      if (event.snapshot.value == null) {
        return;
      }
      final Object? rawData = event.snapshot.value;
      if (rawData is! Map) {
        // print("❌ Dữ liệu chatRooms không hợp lệ: $rawData");
        return;
      }
      Map<dynamic, dynamic> data = rawData;
      List<Map<String, dynamic>> rooms = [];

      data.forEach((key, value) {
        if (value is! Map) {
          // print("⚠️ Bỏ qua phòng chat $key vì dữ liệu không hợp lệ: $value");
          return;
        }
        if (value['members'] is Map && value['members'].containsKey(idUser)) {
          String? nickname;
          final Map<dynamic, dynamic> members = value['members'];

          members.forEach((userId, _) {
            if (userId != idUser) {
              nickname = value['nicknames']?[userId];
            }
          });
          rooms.add({
            'roomId': key,
            'lastMessage': value['lastMessage'] ?? 'Hãy trò chuyện với người bạn mới',
            'timestamp': value['lastMessageTime'] ?? 0,
            'status': value['status'] ?? 'Đã gửi',
            'members': members.keys.toList(),
            'numMembers': members.length,
            'nickname': nickname,
            'typeRoom': value['typeRoom'] ?? false,
            'groupAvatar': value['groupAvatar'] ?? '',
            'groupName': value['groupName'] ?? '',
            'description': value['description'] ?? '',
          });
        }
      });
      rooms.sort((a, b) => (int.tryParse(b['timestamp'].toString()) ?? 0)
          .compareTo(int.tryParse(a['timestamp'].toString()) ?? 0));
      if (mounted) {
        setState(() {
          chatRooms = rooms;
        });
      }
    });
  }

  Future<Map<String, String>> _getFriendDetails(String friendId) async {
    final snapshot = await _database.child('users').child(friendId).get();
    if (snapshot.exists) {
      String idFriend = friendId;
      String fullName = snapshot.child('fullName').value.toString();
      String avatarUrl = snapshot.child('AVT').value?.toString() ?? "";
      return {'idFriend': idFriend ,'fullName': fullName, 'AVT': avatarUrl};
    }
    return {'fullName': 'Người bạn mới', 'AVT': ''};
  }

  String formatTimestamp(int timestamp) {
    DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(messageTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} giây trước';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'vi').format(messageTime);
    } else {
      return DateFormat('dd/MM', 'vi').format(messageTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Ẩn bàn phím
        setState(() {}); // Cập nhật lại giao diện khi ẩn bàn phím
      },
      child: Scaffold(
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
                'Tìm kiếm',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 19,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.qr_code),
                onPressed: () {

                },
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {

                },
              ),
            ],
            iconTheme: IconThemeData(color: Colors.white),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE1E1E1),
                      width: 1.0,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tất cả',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      Icons.filter_list,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  final chatRoom = chatRooms[index];
                  final friendId = (chatRoom['members'] as List).firstWhere((id) => id != idUser);
                  final lastMessageStatus = chatRoom['status'] ?? 'Đã gửi';

                  bool isFriend = false;

                  if (chatRoom['typeRoom'] == true) {
                    isFriend = true;
                  } else if (chatRoom['typeRoom'] == false){
                    final friendId = (chatRoom['members'] as List).firstWhere((id) => id != idUser);
                    isFriend = _friends.contains(friendId.trim());
                  }

                  return FutureBuilder<Map<String, String>>(
                    future: _getFriendDetails(friendId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return MessageItem(
                          userName: 'Đang tải...',
                          message: chatRoom['lastMessage'],
                          time: 'Gần đây',
                          avatarUrl: "",
                          senderId: chatRoom['senderId']?.toString() ?? '',
                          currentUserId: idUser ?? '',
                          status: lastMessageStatus,
                          typeRoom: chatRoom['typeRoom'],
                          groupAvatar: chatRoom['groupAvatar'],
                          groupName: chatRoom['groupName'],
                          onTap: () {},
                        );
                      }
                      if (snapshot.hasData) {
                        final friendName = snapshot.data!['fullName'] ?? 'Người dùng ẩn danh';
                        final avatarUrl = snapshot.data!['AVT'] ?? '';
                        return MessageItem(
                          userName: chatRoom['nickname'] ?? friendName,
                          message: chatRoom['lastMessage'] ?? 'Người bạn mới',
                          time: formatTimestamp(chatRoom['timestamp']),
                          avatarUrl: avatarUrl,
                          status: lastMessageStatus,
                          senderId: chatRoom['senderId']?.toString() ?? '',
                          currentUserId: idUser ?? '',
                          typeRoom: chatRoom['typeRoom'],
                          groupAvatar: chatRoom['groupAvatar'],
                          groupName: chatRoom['groupName'],
                          onTap: () {
                            if (idUser != null) {
                              _database.child('chatRooms/${chatRoom['roomId']}').update({
                                'status': 'Đã xem'
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Message(
                                    chatRoomId: chatRoom['roomId'],
                                    idFriend: friendId,
                                    avt: avatarUrl,
                                    fullName: chatRoom['nickname'] ?? friendName,
                                    userId: idUser!,
                                    typeRoom: chatRoom['typeRoom'],
                                    groupAvatar: chatRoom['groupAvatar'],
                                    groupName: chatRoom['groupName'],
                                    numMembers: chatRoom['numMembers'],
                                    description: chatRoom['description'],
                                    isFriend: isFriend,
                                    member: List<String>.from(chatRoom['members']),
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      } else {
                        return MessageItem(
                          userName: 'Lỗi tải dữ liệu',
                          message: chatRoom['lastMessage'] ?? 'Không có tin nhắn',
                          time: 'Gần đây',
                          avatarUrl: "",
                          status: lastMessageStatus,
                          senderId: chatRoom['senderId']?.toString() ?? '',
                          currentUserId: idUser ?? '',
                          typeRoom: chatRoom['typeRoom'],
                          groupAvatar: chatRoom['groupAvatar'],
                          groupName: chatRoom['groupName'],
                          onTap: () {},
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}