import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class FullScreenImageView extends StatefulWidget {
  final String chatRoomID;
  final String userID;
  final String senderID;
  final String messageID;
  final int? time;
  final String imageUrl;

  const FullScreenImageView({
    super.key,
    required this.chatRoomID,
    required this.userID,
    required this.messageID,
    required this.senderID,
    required this.time,
    required this.imageUrl,
  });

  @override
  _FullScreenImageViewState createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  String senderName = "Đang tải...";
  String senderAvatar = "";
  String formattedTime = "Đang tải...";

  @override
  void initState() {
    super.initState();
    fetchSenderInfo();
    formatTime();
  }

  Future<void> fetchSenderInfo() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("users/${widget.senderID}");
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists && snapshot.value is Map) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          senderName = userData["fullName"] ?? "Không có tên";
          senderAvatar = userData["AVT"] ?? "";
        });
      } else {
        setState(() {
          senderName = "Không tìm thấy người gửi";
        });
      }
    } catch (e) {
      setState(() {
        senderName = "Lỗi tải dữ liệu";
      });

    }
  }

  void updateReaction(String chatId, String messageId, String userId, String value) {
    DatabaseReference messageRef = FirebaseDatabase.instance
        .ref()
        .child("chats")
        .child(chatId)
        .child("messages")
        .child(messageId)
        .child("reactions");

    messageRef.get().then((DataSnapshot snapshot) {
      Map<String, dynamic> reactions = {};

      if (snapshot.value is Map<Object?, Object?>) {
        reactions = (snapshot.value as Map<Object?, Object?>).map(
              (key, val) => MapEntry(key.toString(), Map<String, int>.from(val as Map)),
        );
      }

      if (value == 'remove') {
        for (var key in reactions.keys.toList()) {
          reactions[key]?.remove(userId);
          if (reactions[key]?.isEmpty ?? true) {
            reactions.remove(key);
          }
        }
      } else {
        reactions.putIfAbsent(value, () => {});
        reactions[value]![userId] = (reactions[value]?[userId] ?? 0) + 1;
      }
      messageRef.set(reactions);
    }).catchError((error) {
      print("Lỗi cập nhật reactions: $error");
    });
  }

  void formatTime() {
    if (widget.time != null) {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(widget.time!, isUtc: true)
          .add(const Duration(hours: 7)); // Chuyển sang giờ VN
      setState(() {
        formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
      });
    } else {
      setState(() {
        formattedTime = "Không có thời gian";
      });
    }
  }

  /// Hàm tải ảnh về máy
  Future<void> downloadImage() async {
    try {
      var response = await Dio().get(widget.imageUrl, options: Options(responseType: ResponseType.bytes));
      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/downloaded_image.jpg");
      await file.writeAsBytes(response.data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tải xuống thành công")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải xuống: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            senderAvatar.isNotEmpty
                ? CircleAvatar(
              backgroundImage: NetworkImage(senderAvatar),
            )
                : const CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    formattedTime,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: downloadImage,
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'share') {
                // print("Chia sẽ");
              } else if (value == 'edit') {
                // print("Chỉnh sửa ảnh");
              } else if (value == 'save') {
                // print("Lưu ảnh");
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: const [
                    Icon(Icons.share, color: Colors.black),
                    SizedBox(width: 8),
                    Text("Chia sẽ"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: const [
                    Icon(Icons.edit, color: Colors.black),
                    SizedBox(width: 8),
                    Text("Chỉnh sửa ảnh"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: const [
                    Icon(Icons.save, color: Colors.black),
                    SizedBox(width: 8),
                    Text("Lưu ảnh"),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: Center(
        child: widget.imageUrl.isNotEmpty
            ? InteractiveViewer(
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Text(
              "Hình ảnh không khả dụng",
              style: TextStyle(color: Colors.white),
            ),
          ),
        )
            : const Text(
          "Hình ảnh không khả dụng",
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
               updateReaction(widget.chatRoomID, widget.messageID, widget.userID, 'heart');
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF212121),
                  border: Border.all(color: Color(0xFFCBCBCB), width: 1),
                ),
                child: const Icon(Icons.favorite, color: Colors.red, size: 18),
              ),
            ),
            const SizedBox(width: 35), // Thêm khoảng cách giữa các icon
            GestureDetector(
              onTap: () {
                updateReaction(widget.chatRoomID, widget.messageID, widget.userID, 'haha');
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF212121),
                  border: Border.all(color: Color(0xFFCBCBCB), width: 1),
                ),
                child: const Icon(Icons.emoji_emotions_outlined, color: Colors.yellow, size: 18),
              ),
            ),
            const SizedBox(width: 35),
            GestureDetector(
              onTap: () {
                updateReaction(widget.chatRoomID, widget.messageID, widget.userID, 'like');
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF212121),
                  border: Border.all(color: Color(0xFFCBCBCB), width: 1),
                ),
                child: const Icon(Icons.thumb_up, color: Colors.yellow, size: 18),
              ),
            ),
            const SizedBox(width: 35),
            GestureDetector(
              onTap: () {
                Share.share(widget.imageUrl);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF212121),
                  border: Border.all(color: Color(0xFFCBCBCB), width: 1),
                ),
                child: const Icon(Icons.ios_share_outlined, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
