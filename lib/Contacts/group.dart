import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'createGroup.dart';
import 'package:chatonline/message/nhan_tin.dart';

class Group extends StatefulWidget {
  const Group({super.key});

  @override
  State<Group> createState() => GroupState();
}

class GroupState extends State<Group> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> groupList = [];
  String? idUser;
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
      _fetchGroups();
    }
  }

  Future<void> _fetchGroups() async {
    _database.child('chatRooms').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> tempGroups = [];

        data.forEach((key, value) {
          if (value['typeRoom'] == true && value['members'] != null) {
            Map<dynamic, dynamic> members = value['members'];

            // Kiểm tra ID của người dùng có trong danh sách members không
            bool isUserInGroup = members.keys.any((key) => key == idUser);

            if (isUserInGroup) {
              tempGroups.add({
                'groupId': key,
                'groupAvatar': value['groupAvatar'] ?? "",
                'groupName': value['groupName'] ?? "Nhóm không tên",
                'lastMessage': value['lastMessage'] ?? "Chưa có tin nhắn",
                'lastMessageTime': value['lastMessageTime'] ?? 0,
                'timestamp': value['lastMessageTime'] ?? 0,
                'status': value['status'] ?? 'Đã gửi',
                'members': members.keys.toList(),
                'numMembers': members.length,
                'typeRoom': value['typeRoom'] ?? false,
                'description': value['description'] ?? '',
              });
            }
          }
        });

        setState(() {
          groupList = tempGroups;
        });
      }
    });
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
    return Scaffold(
      body: groupList.isEmpty
          ? const Center(child: Text("Không có nhóm nào"))
          :ListView.builder(
        itemCount: groupList.length,
        itemBuilder: (context, index) {
          final group = groupList[index];

          bool isFriend = false;

          if (group['typeRoom'] == true) {
            isFriend = true;
          } else if (group['typeRoom'] == false){
            final friendId = (group['members'] as List).firstWhere((id) => id != idUser);
            isFriend = _friends.contains(friendId.trim());
          }

          final friendId = (group['members'] as List).firstWhere((id) => id != idUser);

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: group['groupAvatar'].isNotEmpty
                  ? NetworkImage(group['groupAvatar'])
                  : null,
              child: group['groupAvatar'].isEmpty ? Icon(Icons.group) : null,
            ),
            title: Text(group['groupName']),
            subtitle: Text(group['lastMessage']),
            trailing: Text(
              formatTimestamp(group['lastMessageTime']),
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(
                  builder: (context) => NhanTin(
                      chatRoomId: group['groupId'],
                      idFriend: friendId,
                      avt: group['groupAvatar'],
                      fullName: group['groupName'],
                      userId: idUser!,
                      typeRoom: group['typeRoom'],
                      groupAvatar: group['groupAvatar'],
                      groupName: group['groupName'],
                      numMembers: group['numMembers'],
                      member: List<String>.from(group['members']),
                      description: group['description'],
                      isFriend: isFriend),
              )
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (idUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateGroup(userId: idUser!)),
            );
          }
        },
        icon: const Icon(Icons.group_add, color: Colors.grey, size: 20),
        label: const Text("Tạo nhóm", style: TextStyle(color: Colors.black, fontSize: 14)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
    );
  }
}
