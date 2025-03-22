import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

class CreateGroupScreen extends StatefulWidget {
  final String userId, friendId;
    const CreateGroupScreen({
      super.key,
      required this.userId,
      required this.friendId}
      );

  @override
  CreateGroupScreenState createState() => CreateGroupScreenState();
}

class CreateGroupScreenState extends State<CreateGroupScreen> {
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
    if(widget.friendId != null && widget.friendId != ''){
      selectedFriends.add(widget.friendId);
    }
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
    setState(() {
      if (selectedFriends.contains(friendId)) {
        selectedFriends.remove(friendId);
      } else {
        selectedFriends.add(friendId);
      }
    });
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty || selectedFriends.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập tên nhóm và chọn ít nhất hai thành viên")),
      );
      return;
    }
    final groupRef = FirebaseDatabase.instance.ref().child('chatRooms').push();
    String groupId = groupRef.key!;
    String? imageUrl;
    if (_image != null) {
      imageUrl = await _uploadImageToFirebase(groupId);
    }
    await groupRef.set({
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'lastMessage': "Hãy bắt đầu trò chuyện với nhóm mới",
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'members': {
        widget.userId: true,
        for (var id in selectedFriends) id: true,
      },
      'typeRoom': true,
      'groupName': _groupNameController.text,
      'groupAvatar': imageUrl ?? "",
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Nhóm '${_groupNameController.text}' đã được tạo!")),
    );
    for (int i = 0; i < 3; i++) {
      Navigator.pop(context);
    }
  }

  Future<String?> _uploadImageToFirebase(String groupId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('group_avatars/$groupId.jpg');
      await ref.putFile(_image!);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Lỗi upload ảnh: $e");
      return null;
    }
  }


  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo nhóm', style: TextStyle(color: Colors.white, fontSize: 18)),
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
            Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null
                        ? Icon(Icons.camera_alt, color: Colors.white, size: 30)
                        : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _groupNameController,
                    cursorColor: Colors.green,
                    decoration: InputDecoration(
                      labelText: "Tên nhóm",
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
                    ),
                  ),
                ),
              ],
            ),
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
                onPressed: _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF11998e),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text("Tạo nhóm", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
