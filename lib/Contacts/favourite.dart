import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatonline/message/call/call.dart';
import 'package:chatonline/message/message.dart';

class Favourite extends StatefulWidget {
  const Favourite({super.key});

  @override
  State<Favourite> createState() => FavouriteState();
}

class FavouriteState extends State<Favourite> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> favouriteList = [];
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
      _loadCachedFavourites();
      _fetchFavourites(idUser!);
    }
  }

  Future<void> _loadCachedFavourites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedFavourites = prefs.getString('cachedFavourites');
    if (cachedFavourites != null) {
      List<dynamic> cachedData = jsonDecode(cachedFavourites);
      setState(() {
        favouriteList = List<Map<String, dynamic>>.from(cachedData);
      });
    }
  }

  Future<void> _fetchFavourites(String idUser) async {
    try {
      // Lấy dữ liệu từ bestFriends
      DatabaseEvent bestFriendsEvent = await _database.child('bestFriends/$idUser').once();
      if (bestFriendsEvent.snapshot.value != null) {
        Map<dynamic, dynamic> bestFriendsData = bestFriendsEvent.snapshot.value as Map<dynamic, dynamic>;
        List<String> favouriteIds = bestFriendsData.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key.toString())
            .toList();

        print("✅ Danh sách bạn bè yêu thích (true): $favouriteIds");

        // Truy vấn dữ liệu từ chatRooms
        DatabaseEvent chatRoomsEvent = await _database.child('chatRooms').once();
        if (chatRoomsEvent.snapshot.value != null) {
          Map<dynamic, dynamic> data = chatRoomsEvent.snapshot.value as Map<dynamic, dynamic>;
          List<Map<String, dynamic>> allFriend = [];

          for (var entry in data.entries) {
            String groupId = entry.key;
            var value = entry.value;
            if (value['members'] != null && value['members'].length == 2) {
              Map<dynamic, dynamic> members = value['members'];
              if (members.containsKey(idUser)) {
                // Tìm friendId
                String friendId = members.keys.firstWhere((key) => key != idUser, orElse: () => "");
                if (friendId.isNotEmpty && favouriteIds.contains(friendId)) {
                  // Chỉ thêm friendId vào danh sách nếu có trong bestFriends và có giá trị true
                  DatabaseEvent friendEvent = await _database.child('users/$friendId').once();
                  if (friendEvent.snapshot.value != null) {
                    Map<dynamic, dynamic> friendData = friendEvent.snapshot.value as Map<dynamic, dynamic>;
                    allFriend.add({
                      'friendId': friendId,
                      'fullName': friendData['fullName'],
                      'avatar': friendData['AVT'] ?? '',
                      'groupId': groupId,
                      'lastMessage': value['lastMessage'] ?? "",
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

          // Lưu dữ liệu vào cache
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('cachedFavourites', jsonEncode(allFriend));

          setState(() {
            favouriteList = allFriend;
          });
        }
      }
    } catch (error) {
      print("❌ Lỗi khi tải dữ liệu từ Firebase: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      body: favouriteList.isEmpty
          ? Center(
        child: Text(
          "Bạn chưa có bạn bè yêu thích nào!",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: favouriteList.length,
        itemBuilder: (context, index) {
          var friend = favouriteList[index];
          return Column(
            children: [
              Container(
                color: Colors.white,
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: friend['avatar'].isNotEmpty ? NetworkImage(friend['avatar']) : null,
                    child: friend['avatar'].isEmpty ? Icon(Icons.person, size: 30, color: Colors.white) : null,
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend['fullName'],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),  // Tạo khoảng cách giữa tên và tin nhắn cuối
                      Text(
                        friend['lastMessage'] ?? "",  // Hiển thị tin nhắn cuối cùng hoặc chuỗi trống nếu không có
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.call, color: Colors.grey),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Call(
                            chatRoomId: friend['groupId'],
                            idFriend: friend['friendId'],
                            avt: friend['avatar'],
                            fullName: friend['fullName'],
                            userId: idUser!,
                          ),
                        ),
                      );
                    },
                  ),
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
                          typeRoom: false,
                          groupAvatar: '',
                          groupName: '',
                          numMembers: 2,
                          member: [],
                          description: '',
                          isFriend: true,
                          totalTime: friend['totalTime'] ?? '',
                          senderId: friend['senderId'] ?? '',
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
        },
      ),
    );
  }
}
