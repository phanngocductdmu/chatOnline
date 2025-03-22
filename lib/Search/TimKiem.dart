import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_item.dart';
import 'package:flutter/material.dart';
import 'package:chatonline/message/message.dart';
import 'package:chatonline/message/option/personalPage/personalPageF.dart';

class TimKiem extends StatefulWidget {
  const TimKiem({super.key});

  @override
  State<TimKiem> createState() => _TimKiemState();
}

class _TimKiemState extends State<TimKiem> {
  final TextEditingController searchController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, String>> users = [];
  List<Map<String, String>> filteredUsers = [];
  List<Map<String, dynamic>> chatRooms = [];
  List<String> _friends = [];
  List<Map<String, dynamic>> filteredChatRooms = [];

  String? idUser;

  @override
  void initState() {
    super.initState();
    _initialize();
    searchController.addListener(() {
      _filterSearchResults(searchController.text);
    });
    _fetchChatRooms();
  }

  Future<void> _initialize() async {
    await _loadUserId();
    _loadUsers();
    _loadFriends();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getString('userId');
    });
  }

  Future<void> _loadUsers() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref("users");
    ref.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      var data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      List<Map<String, String>> loadedUsers = [];
      data.forEach((key, value) {
        if (key != idUser) {
          loadedUsers.add({
            "id": key,
            "AVT": value["AVT"] ?? "",
            "fullName": value["fullName"] ?? "",
            "email": value["email"] ?? "",
            "gender": value["gender"] ?? "",
          });
        }
      });
      setState(() {
        users = loadedUsers;
        filteredUsers = users;
      });
    });
  }

  void _fetchChatRooms() {
    _database.child('chatRooms').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> rooms = [];
        data.forEach((key, value) {
          if (value['members'] != null && (value['members'] as Map).containsKey(idUser)) {
            String? nickname;
            final members = value['members'] as Map<dynamic, dynamic>;

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
        rooms.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
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

  void _filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredUsers = List.from(users);
        filteredChatRooms = List.from(chatRooms);
      });
      return;
    }

    setState(() {
      filteredUsers = users.where((user) {
        final fullName = user["fullName"]?.toLowerCase() ?? "";
        bool match = fullName.contains(query.toLowerCase());
        print("User: ${user["fullName"]}, Match: $match");
        return match;
      }).toList();

      filteredChatRooms = chatRooms.where((room) {
        final nickname = room["nickname"]?.toLowerCase() ?? "";
        final groupName = room["groupName"]?.toLowerCase() ?? "";
        bool match = nickname.contains(query.toLowerCase()) || groupName.contains(query.toLowerCase());
        return match;
      }).toList();
    });
  }

  Future<void> _loadFriends() async {
    if (idUser == null) return;
    _database.child("friends/$idUser").onValue.listen((event) {
      if (event.snapshot.value != null) {
        var data = event.snapshot.value as Map<dynamic, dynamic>;
        List<String> friendIds = data.keys.map((key) => key.toString()).toList();

        setState(() {
          _friends = friendIds;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedUsers = filteredUsers
        .where((user) => !_friends.contains(user["id"]))
        .where((user) => user["id"] != idUser)
        .toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildUserList(displayedUsers),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildSearchField(),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
            onPressed: () {},
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.black),
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> displayedUsers) {
    List<Map<String, dynamic>> combinedList = [];

    for (var user in displayedUsers) {
      bool isFriend = _friends.contains(user["id"]);
      combinedList.add({
        "type": "user",
        "id": user["id"] ?? '',
        "avatar": user["AVT"] ?? '',
        "name": user["fullName"] ?? '',
        "isFriend": isFriend,
      });
    }

    for (var room in filteredChatRooms) {
      combinedList.add({
        "type": "chatRoom",
        "typeRoom": room["typeRoom"] ?? false,
        "roomId": room["roomId"] ?? '',
        "groupAvatar": room["groupAvatar"] ?? '',
        "groupName": room["groupName"] ?? '',
        "lastMessage": room["lastMessage"] ?? '',
        "members": room["members"] is List ? List<String>.from(room["members"]) : [],
        "description": room["description"] ?? '',
        "FriendID": room["FriendID"] is List ? List<String>.from(room["FriendID"]) : [],
        "numMembers": room["numMembers"],
        "nickname": room["nickname"],
      });
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: combinedList.length,
      itemBuilder: (context, index) {
        var item = combinedList[index];
        if (item["type"] == "user") {
          return SearchItem(
            avatarUrl: item["avatar"],
            fullName: item["name"],
            onPressed: () {

            },
            idUser: idUser ?? "",
            idFriend: item["id"],
            isFriend: item["isFriend"],
          );
        } else if (item["type"] == "chatRoom") {
          if (item["typeRoom"] == false) {
            final friendId = (item['members'] as List).firstWhere((id) => id != idUser);
            return FutureBuilder<Map<String, String>>(
              future: _getFriendDetails(friendId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData) {
                  return const SizedBox();
                }
                final friendInfo = snapshot.data!;
                return SearchItemChatRooms(
                  groupAvatar: friendInfo['AVT'] ?? '',
                  groupName:item['nickname'] ?? friendInfo['fullName'] ?? '',
                  onTapPersonal: (){
                    Navigator.push(context,
                        MaterialPageRoute(
                            builder: (context) => PersonalPage(idFriend: friendId, idChatRoom: item['roomId'], nickName: item['nickname'] ?? friendInfo['fullName'] ?? '', idUser: idUser!, avt: friendInfo['AVT'] ?? '', isFriend: true),
                        ));
                  },
                  onTap: () {
                    if (idUser != null) {
                      _database.child('chatRooms/${item['roomId']}').update({'status': 'Đã xem'});
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Message(
                            chatRoomId: item['roomId'],
                            idFriend: friendId,
                            avt: friendInfo['AVT'] ?? '',
                            fullName: friendInfo['fullName'] ?? '',
                            userId: idUser!,
                            typeRoom: item['typeRoom'],
                            groupAvatar: item['groupAvatar'],
                            groupName: item['groupName'],
                            numMembers: item['numMembers'],
                            description: item['description'],
                            member: List<String>.from(item['members']),
                            isFriend: item["isFriend"],
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          } else {
            return SearchItemChatRooms(
              groupAvatar: item['groupAvatar'] ?? '',
              groupName: item['groupName'] ?? '',
              onTapPersonal: (){
                if (idUser != null) {
                  _database.child('chatRooms/${item['roomId']}').update({'status': 'Đã xem'});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Message(
                        chatRoomId: item['roomId'],
                        idFriend: item['FriendID'].isNotEmpty ? item['FriendID'].first : '',
                        avt: item['groupAvatar'] ?? '',
                        fullName: item['groupName'] ?? '',
                        userId: idUser!,
                        typeRoom: item['typeRoom'],
                        groupAvatar: item['groupAvatar'],
                        groupName: item['groupName'],
                        numMembers: item['numMembers'],
                        description: item['description'],
                        member: item['members'],
                        isFriend: item["isFriend"],
                      ),
                    ),
                  );
                }
              },
              onTap: () {
                if (idUser != null) {
                  _database.child('chatRooms/${item['roomId']}').update({'status': 'Đã xem'});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Message(
                        chatRoomId: item['roomId'],
                        idFriend: item['FriendID'].isNotEmpty ? item['FriendID'].first : '',
                        avt: item['groupAvatar'] ?? '',
                        fullName: item['groupName'] ?? '',
                        userId: idUser!,
                        typeRoom: item['typeRoom'],
                        groupAvatar: item['groupAvatar'],
                        groupName: item['groupName'],
                        numMembers: item['numMembers'],
                        description: item['description'],
                        member: item['members'],
                        isFriend: item["isFriend"],
                      ),
                    ),
                  );
                }
              },
            );
          }
        }
        return const SizedBox();
      },
    );
  }
}