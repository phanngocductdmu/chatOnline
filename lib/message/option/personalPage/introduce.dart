import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:validators/validators.dart';

class Introduce extends StatefulWidget {
  final String userId, friendId, idChatRooms;
  const Introduce({
    super.key,
    required this.userId,
    required this.friendId,
    required this.idChatRooms
  });

  @override
  IntroduceState createState() => IntroduceState();
}

class IntroduceState extends State<Introduce> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _searchController = TextEditingController();
  List<String> _friends = [];
  List<Map<String, String>> filteredFriends = [];
  List<String> selectedFriends = [];
  List<Map<String, dynamic>> chatRooms = [];
  bool _isTyping = false;
  List<String> selectedChatRooms = [];
  Map<String, dynamic>? selectedReplyMessage;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _fetchChatRooms();
  }

  Future<void> _loadFriends() async {
    if (widget.userId == null) return;
    _database.child("friends/${widget.userId}").onValue.listen((event) {
      if (event.snapshot.value != null) {
        var data = event.snapshot.value as Map<dynamic, dynamic>;
        List<String> friendIds = data.keys.map((key) => key.toString().trim()).toList();

        setState(() {
          _friends = friendIds;
        });
      }
    });
  }

  void _fetchChatRooms() {
    _database.child('chatRooms').onValue.listen((event) {
      if (event.snapshot.value == null) {
        return;
      }
      final Object? rawData = event.snapshot.value;
      if (rawData is! Map) {
        return;
      }
      Map<dynamic, dynamic> data = rawData;
      List<Map<String, dynamic>> rooms = [];

      data.forEach((key, value) {
        if (value is! Map || key == widget.idChatRooms) {
          return;
        }
        if (value['members'] is Map && value['members'].containsKey(widget.userId)) {
          String? nickname;
          final Map<dynamic, dynamic> members = value['members'];

          members.forEach((userId, _) {
            if (userId != widget.userId) {
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
            'totalTime': value['totalTime'] ?? '',
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

  void _sendMessage(String idFriend) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final receiverId = await _getReceiverId();
    if (receiverId == null) {
      return;
    }
    final snapshot = await _database.child('users/$receiverId/status/online').get();
    final isReceiverOnline = snapshot.exists && snapshot.value == true;
    final newStatus = isReceiverOnline ? 'Đã nhận' : 'Đã gửi';
    final messageData = {
      'text': idFriend,
      'senderId': widget.userId,
      'timestamp': timestamp,
      'typeChat': 'introduce',
      'status': newStatus,
    };
    await _database.child('chats/${widget.idChatRooms}/messages').push().set(messageData);
    _sendLastMessege(timestamp, newStatus);
    setState(() {
      _isTyping = false;
      selectedReplyMessage = null;
    });
  }

  void _sendLastMessege(final timestamp, String newStatus ) async{
    await _database.child('chatRooms/${widget.idChatRooms}').update({
      'lastMessage': '[Danh thiếp]',
      'lastMessageTime': timestamp,
      'status': newStatus,
      'senderId': widget.userId,
    });
  }

  Future<String?> _getReceiverId() async {
    final snapshot = await _database.child('chatRooms/${widget.idChatRooms}/members').get();
    if (snapshot.exists && snapshot.value is Map) {
      return (snapshot.value as Map).keys.firstWhere((id) => id != widget.userId, orElse: () => null);
    }
    return null;
  }

  void _toggleChatRoomSelection(String roomId) {
    setState(() {
      if (selectedChatRooms.contains(roomId)) {
        selectedChatRooms.remove(roomId);
      } else {
        selectedChatRooms.add(roomId);
      }
    });
  }

  void _sendMessageToSelectedRooms() async {
    if (selectedChatRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng chọn ít nhất một phòng chat!")),
      );
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    for (String roomId in selectedChatRooms) {
      await _database.child('chats/$roomId/messages').push().set({
        'text': widget.friendId, // Gửi ID người được giới thiệu
        'senderId': widget.userId,
        'timestamp': timestamp,
        'typeChat': 'introduce',
        'status': 'Đã gửi',
      });

      await _database.child('chatRooms/$roomId').update({
        'lastMessage': '[Danh thiếp]',
        'lastMessageTime': timestamp,
        'senderId': widget.userId,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã gửi danh thiếp thành công!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giới thiệu', style: TextStyle(color: Colors.white, fontSize: 18)),
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
        actions: [
          IconButton(
            icon: Icon(Icons.send, color: Colors.white, size: 27),
            onPressed: _sendMessageToSelectedRooms,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              cursorColor: Colors.green,
              decoration: InputDecoration(
                labelText: "Tìm kiếm bạn bè",
                labelStyle: TextStyle(color: Colors.green),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                prefixIcon: Icon(Icons.search, color: Colors.green),
              ),
            ),
            SizedBox(height: 16),
            Text("Trò chuyện gần đây", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  final chatRoom = chatRooms[index];
                  final bool isGroupChat = chatRoom['typeRoom'] == true;
                  final String friendId = isGroupChat
                      ? ''
                      : (chatRoom['members'] as List)
                      .firstWhere((id) => id != widget.userId);

                  return FutureBuilder<Map<String, String>>(
                    future: isGroupChat
                        ? Future.value({'fullName': chatRoom['groupName'], 'AVT': chatRoom['groupAvatar']})
                        : _getFriendDetails(friendId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.grey),
                          title: Text("Đang tải..."),
                        );
                      }

                      final String avatarUrl = snapshot.data!['AVT'] ?? '';
                      final String displayName = snapshot.data!['fullName'] ?? 'Người bạn mới';

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                          backgroundColor: avatarUrl.isEmpty ? Colors.grey[300] : Colors.transparent,
                          child: avatarUrl.isEmpty ? Icon(Icons.person, color: Colors.white) : null,
                        ),
                        title: Text(displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        trailing: selectedChatRooms.contains(chatRoom['roomId'])
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.radio_button_unchecked),
                        onTap: () =>  _toggleChatRoomSelection(chatRoom['roomId']),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}