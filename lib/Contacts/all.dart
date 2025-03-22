import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatonline/message/call/call.dart';
import 'package:chatonline/message/message.dart';

class All extends StatefulWidget {
  const All({super.key});

  @override
  State<All> createState() => AllState();
}

class AllState extends State<All> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> friendsList = [];
  String? idUser;
  List<String> friends = [];

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
      _fetchFriends(idUser!);
    }
  }

  Future<void> _fetchFriends(String idUser) async {
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
                  });
                }
              }
            }
          }
        }

        allFriend.sort((a, b) => a['fullName'].toLowerCase().compareTo(b['fullName'].toLowerCase()));

        setState(() {
          friendsList = allFriend;
        });
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
          "Bạn chưa có bạn bè nào!",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: friendsList.map((group) {
            return Column(
              children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: group['avatar'].isNotEmpty
                          ? NetworkImage(group['avatar'])
                          : null,
                      child: group['avatar'].isEmpty
                          ? Icon(Icons.person, size: 30, color: Colors.white)
                          : null,
                    ),
                    title: Text(
                      group['fullName'],
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.call, color: Colors.grey),
                      onPressed: () {
                        Navigator.push(
                            context, MaterialPageRoute(
                            builder: (context) => Call(
                                chatRoomId: group['groupId'],
                                idFriend: group['friendId'],
                                avt: group['avatar'],
                                fullName: group['fullName'],
                                userId: idUser!),
                        ));
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Message(
                            chatRoomId: group['groupId'],
                            idFriend: group['friendId'],
                            avt: group['avatar'],
                            fullName: group['fullName'],
                            userId: idUser!,
                            typeRoom: group['typeRoom'],
                            groupAvatar: group['groupAvatar'],
                            groupName: group['groupName'],
                            numMembers: group['numMembers'],
                            member: List<String>.from(group['members']),
                            description: group['description'],
                            isFriend: true,
                          ),
                        ),
                      );
                    },
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
      ),
    );
  }
}