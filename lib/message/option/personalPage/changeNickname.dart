import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ChangeNickname extends StatefulWidget {
  final String idFriend, idChatRoom, nickName;
  const ChangeNickname({
    super.key,
    required this.idFriend,
    required this.idChatRoom,
    required this.nickName,
  });

  @override
  State<ChangeNickname> createState() => ChangeNicknameState();
}

class ChangeNicknameState extends State<ChangeNickname> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.nickName);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _updateNickname(String newNickname) {
    _database
        .child('chatRooms')
        .child(widget.idChatRoom)
        .child('nicknames')
        .update({
      widget.idFriend: newNickname,
    }).catchError((error) {
      print('Lỗi khi cập nhật nickname: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Chỉnh sửa tên",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Nhập tên mới",
              labelStyle: TextStyle(color: Colors.green),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                String newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  _updateNickname(newName);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "Lưu",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
