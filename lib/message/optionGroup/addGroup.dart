import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddGroup extends StatefulWidget {
  final String userId;
  final String chatRoomId;
  final List<String> member;
  const AddGroup({
    super.key,
    required this.userId,
    required this.chatRoomId,
    required this.member,
  });

  @override
  AddGroupState createState() => AddGroupState();
}

class AddGroupState extends State<AddGroup> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> friends = [];
  List<Map<String, String>> filteredFriends = [];
  List<String> selectedFriends = [];
  File? _image;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
    _searchController.addListener(_filterFriends);
    selectedFriends = List.from(widget.member);
  }

  void _fetchFriends() async {
    final ref = FirebaseDatabase.instance.ref();
    final friendsRef = ref.child('friends/${widget.userId}');
    final usersRef = ref.child('users');

    final snapshot = await friendsRef.get();

    if (snapshot.exists && snapshot.value is Map) {
      Map<String, dynamic> friendIds = Map<String, dynamic>.from(snapshot.value as Map);

      if (friendIds.isNotEmpty) {
        friends.clear();
        for (String friendId in friendIds.keys) {
          final userSnapshot = await usersRef.child(friendId).get();
          if (userSnapshot.exists) {
            var userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            setState(() {
              friends.add({
                'id': friendId,
                'name': userData['fullName'] ?? 'Không tên',
                'AVT': userData['AVT'] ?? '',
              });
            });
          }
        }
      }
      setState(() {
        filteredFriends = List.from(friends);
      });
    }
  }


  void _filterFriends() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredFriends = friends.where((friend) =>
          friend['name']!.toLowerCase().contains(query)
      ).toList();
    });
  }

  void _toggleSelection(String friendId) {
    if (widget.member.contains(friendId)) return;

    setState(() {
      if (selectedFriends.contains(friendId)) {
        selectedFriends.remove(friendId);
      } else {
        selectedFriends.add(friendId);
      }
    });
  }

  Future<void> addMembersToGroup() async {
    if (selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng chọn ít nhất một thành viên để thêm vào nhóm")),
      );
      return;
    }
    final groupRef = FirebaseDatabase.instance.ref().child('chatRooms/${widget.chatRoomId}/members');
    for (var id in selectedFriends) {
      await groupRef.child(id).set(true);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã thêm thành viên vào nhóm!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm vào nhóm', style: TextStyle(color: Colors.white, fontSize: 18)),
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
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
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
            Text("Chọn thành viên:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  var friend = friends[index];
                  bool isSelected = selectedFriends.contains(friend['id']);
                  return ListTile(
                    leading: friend['AVT']!.isNotEmpty ? CircleAvatar(
                        backgroundImage: NetworkImage(friend['AVT']!)
                    ): SizedBox(
                      width: 40,
                      height:40,
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                    ),
                    title: Text(friend['name']!),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : Icon(Icons.radio_button_unchecked),
                    onTap: () => _toggleSelection(friend['id']!),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addMembersToGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF11998e),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text("Thêm", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}