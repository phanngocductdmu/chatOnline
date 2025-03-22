import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class GroupDescription extends StatefulWidget {
  final String groupID;
  final String groupAvatar;
  final String groupName;

  const GroupDescription({
    super.key,
    required this.groupAvatar,
    required this.groupName,
    required this.groupID,
  });

  @override
  State<GroupDescription> createState() => _GroupDescriptionState();
}

class _GroupDescriptionState extends State<GroupDescription> {
  final TextEditingController descriptionController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _fetchDescription();
  }

  // 🔹 Lấy dữ liệu mô tả nhóm từ Firebase khi mở màn hình
  void _fetchDescription() async {
    DatabaseReference ref = _database.child("chatRooms/${widget.groupID}/description");

    ref.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        setState(() {
          descriptionController.text = event.snapshot.value.toString();
        });
      }
    });
  }

  // 🔹 Cập nhật mô tả nhóm vào Firebase
  void _updateDescription() async {
    String newDescription = descriptionController.text.trim();
    if (newDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập mô tả nhóm!")),
      );
      return;
    }

    await _database.child("chatRooms/${widget.groupID}/description").set(newDescription);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Cập nhật mô tả nhóm thành công!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
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
            title: Text(
              'Mô tả nhóm',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 19,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _updateDescription, // Gọi hàm cập nhật Firebase
                child: Text(
                  'Lưu',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
            iconTheme: IconThemeData(color: Colors.white),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
        body: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(widget.groupAvatar),
            ),
            SizedBox(height: 10),
            Text(
              widget.groupName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Nhập mô tả nhóm...",
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: TextStyle(color: Colors.black),
                maxLines: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
