import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../message/call/call.dart';
import '../message/message.dart';

class JustVisited extends StatefulWidget {
  const JustVisited({super.key});
  @override
  State<JustVisited> createState() => JustVisitedState();
}

class JustVisitedState extends State<JustVisited> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> friendsList = [];
  String? idUser;

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
      _loadCachedFriends(); // Tải từ cache trước
      listenToOnlineFriends(idUser!); // Cập nhật dữ liệu mới
    }
  }

  Future<void> _loadCachedFriends() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cachedFriendsList');

    if (cachedData != null) {
      List<dynamic> cachedList = jsonDecode(cachedData);
      setState(() {
        friendsList = List<Map<String, dynamic>>.from(cachedList);
      });
    }
  }

  Future<void> _cacheFriendsList(List<Map<String, dynamic>> allFriend) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(allFriend);
    await prefs.setString('cachedFriendsList', encodedData);
  }

  Future<void> listenToOnlineFriends(String idUser) async {
    _database.child('chatRooms').once().then((DatabaseEvent event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> allFriend = [];

        for (var entry in data.entries) {
          String groupId = entry.key;
          var value = entry.value;

          if (value['members'] != null && value['members'].length == 2) {
            Map<dynamic, dynamic> members = value['members'];

            if (members.containsKey(idUser)) {
              String friendId = members.keys.firstWhere((key) => key != idUser, orElse: () => "");

              if (friendId.isNotEmpty) {
                DatabaseEvent friendEvent = await _database.child('users/$friendId').once();

                if (friendEvent.snapshot.value != null) {
                  Map<dynamic, dynamic> friendData = friendEvent.snapshot.value as Map<dynamic, dynamic>;
                  if (friendData['status'] != null && friendData['status']['online'] == true) {
                    allFriend.add({
                      'friendId': friendId,
                      'fullName': friendData['fullName'],
                      'avatar': friendData['AVT'] ?? '',
                      'groupId': groupId,
                      'lastMessage': value['lastMessage'] ?? "Chưa có tin nhắn",
                      'lastMessageTime': value['lastMessageTime'] ?? 0,
                      'groupAvatar': value['groupAvatar'] ?? "",
                      'groupName': value['groupName'] ?? "Nhóm không tên",
                      'timestamp': value['lastMessageTime'] ?? 0,
                      'status': value['status'] ?? 'Đã gửi',
                      'members': members.keys.toList(),
                      'numMembers': members.length,
                      'typeRoom': value['typeRoom'] ?? false,
                      'description': value['description'] ?? '',
                      'totalTime': value['totalTime'] ?? '',
                    });
                  }
                }
              }
            }
          }
        }

        allFriend.sort((a, b) => a['fullName'].toLowerCase().compareTo(b['fullName'].toLowerCase()));

        setState(() {
          friendsList = allFriend;
        });

        _cacheFriendsList(allFriend); // Lưu vào cache
      }
    }).catchError((error) {
      print("❌ Lỗi khi tải danh sách bạn bè: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      body: friendsList.isEmpty
          ? Center(
        child: Text(
          "Chưa có bạn bè nào hoạt động!",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Column(
        children: friendsList.map((friend) {
          return Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Message(
                        chatRoomId: friend['groupId'],
                        idFriend: friend['friendId'],
                        avt: friend['avatar'],
                        fullName: friend['fullName'],
                        userId: idUser!,
                        typeRoom: friend['typeRoom'],
                        groupAvatar: friend['groupAvatar'],
                        groupName: friend['groupName'],
                        numMembers: friend['numMembers'],
                        member: List<String>.from(friend['members']),
                        description: friend['description'],
                        isFriend: true,
                        totalTime: friend['totalTime'],
                        senderId: friend['senderId'] ?? '',
                      ),
                    ),
                  );
                },
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey,
                            backgroundImage: friend['avatar'] != null && friend['avatar'].isNotEmpty
                                ? NetworkImage(friend['avatar'])
                                : null,
                            child: (friend['avatar'] == null || friend['avatar'].isEmpty)
                                ? Icon(Icons.person, size: 30, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green, // Online indicator
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          friend['fullName'],
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.call, color: Colors.grey),
                        onPressed: () {
                          Navigator.push(
                              context, MaterialPageRoute(
                            builder: (context) => Call(
                                chatRoomId: friend['groupId'],
                                idFriend: friend['friendId'],
                                avt: friend['avatar'],
                                fullName: friend['fullName'],
                                userId: idUser!),
                          ));
                        },
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
            ],
          );
        }).toList(),
      ),
    );
  }
}
