import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chatonline/User/comment.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SeeMedia extends StatefulWidget {
  final Map<String, dynamic> post;
  final String idUser;
  final String avt;
  final String fullName;

  const SeeMedia({
    super.key, required this.post, required this.idUser, required this.avt, required this.fullName,
  });

  @override
  SeeMediaState createState() => SeeMediaState();
}

class SeeMediaState extends State<SeeMedia> {
  Future<int> getTotalCommentsAndReplies(String postId) async {
    final commentsSnapshot = await FirebaseDatabase.instance
        .ref('posts/$postId/comments')
        .get();

    if (!commentsSnapshot.exists) return 0;

    int totalCount = 0;

    final comments = commentsSnapshot.value as Map<dynamic, dynamic>;
    totalCount += comments.length;

    for (var entry in comments.entries) {
      final repliesSnapshot = await FirebaseDatabase.instance
          .ref('posts/$postId/comments/${entry.key}/replies')
          .get();

      if (repliesSnapshot.exists) {
        final replies = repliesSnapshot.value as Map<dynamic, dynamic>;
        totalCount += replies.length;
      }
    }
    return totalCount;
  }

  List<String> likes = [];

  @override
  void initState() {
    super.initState();
    likes = widget.post['likes'] is Map
        ? Map<String, bool>.from(widget.post['likes']).keys.toList()
        : List<String>.from(widget.post['likes'] ?? []);
  }

  void toggleLike(String postId, String userId, bool isLiked) {
    DatabaseReference likeRef = FirebaseDatabase.instance.ref("posts/$postId/likes/$userId");

    if (isLiked) {
      likeRef.remove().then((_) {
        setState(() {
          likes.remove(userId);
        });
      });
    } else {
      likeRef.set(true).then((_) {
        setState(() {
          likes.add(userId);
        });
      });
    }
  }

  void bottomSheet(BuildContext context, String postId, String privacy, String text, String fileUrl) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.privacy_tip, color: Colors.grey[400]),
                title: Text("Chỉnh sửa quyền xem"),
                onTap: () {
                  Navigator.pop(context);
                  // Gọi hàm chỉnh sửa quyền xem
                  editPrivacy(context, postId, privacy);
                },
              ),
              Divider(),
              // Chỉnh sửa bài đăng
              ListTile(
                leading: Icon(Icons.edit, color: Colors.grey[400]),
                title: Text("Chỉnh sửa bài đăng"),
                onTap: () {
                  Navigator.pop(context);
                  // Gọi hàm chỉnh sửa bài đăng
                  editPost(context, postId, text, fileUrl);
                },
              ),
              Divider(),
              // Xóa bài đăng
              ListTile(
                leading: Icon(Icons.delete, color: Colors.grey[400]),
                title: Text("Xóa bài đăng"),
                onTap: () {
                  Navigator.pop(context);
                  // Gọi hàm xóa bài đăng
                  deletePost(context, postId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void editPrivacy(BuildContext context, String postId, String currentPrivacy) {
    DatabaseReference postRef = FirebaseDatabase.instance.ref("posts/$postId");

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Chỉnh sửa quyền xem",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _privacyOption(context, postRef, postId, "Tất cả bạn bè", Icons.public, currentPrivacy),
              _privacyOption(context, postRef, postId, "Chỉ mình tôi", Icons.lock, currentPrivacy),
              _privacyOption(context, postRef, postId, "Bạn bè ngoại trừ", Icons.people_outline, currentPrivacy),
              _privacyOption(context, postRef, postId, "Bạn bè trong nhóm", Icons.group, currentPrivacy),
            ],
          ),
        );
      },
    );
  }

  void editPost(BuildContext context, String postId, String currentText, String currentFileUrl) async {
    TextEditingController textController = TextEditingController(text: currentText);
    XFile? pickedImage;
    final ImagePicker _picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 15,
                right: 15,
                top: 15,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Chỉnh sửa bài đăng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: InputDecoration(hintText: "Nhập nội dung mới...", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 10),
                    pickedImage != null
                        ? Image.file(File(pickedImage!.path), height: 200)
                        : (currentFileUrl.isNotEmpty
                        ? Image.network(currentFileUrl, height: 200)
                        : Container()),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            pickedImage = image;
                          });
                        }
                      },
                      icon: Icon(Icons.image),
                      label: Text("Chọn ảnh mới"),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        String newText = textController.text.trim();
                        String newFileUrl = currentFileUrl;

                        if (pickedImage != null) {
                          newFileUrl = await uploadImageToFirebase(pickedImage!, postId);
                        }

                        updatePostInFirebase(context, postId, newText, newFileUrl);

                        Navigator.pop(context);
                      },
                      child: Text("Lưu chỉnh sửa"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void updatePostInFirebase(BuildContext context, String postId, String newText, String newFileUrl) {
    DatabaseReference postRef = FirebaseDatabase.instance.ref("posts/$postId");

    postRef.update({
      "text": newText,
      "fileUrl": newFileUrl,
    }).then((_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Chỉnh sửa bài đăng thành công!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi chỉnh sửa bài đăng: $error")),
      );
    });
  }

  void deletePost(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa bài đăng này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Hủy",
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              DatabaseReference postRef = FirebaseDatabase.instance.ref("posts/$postId");
              postRef.remove().then((_) {

              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi khi xóa bài đăng: $error")),
                );
              });
            },
            child: Text(
              "Xóa",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> uploadImageToFirebase(XFile image, String postId) async {
    Reference storageRef = FirebaseStorage.instance.ref().child("posts/$postId.jpg");
    await storageRef.putFile(File(image.path));
    return await storageRef.getDownloadURL();
  }

  String formattedTime(int timestamp) {
    DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(messageTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} giây trước';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return DateFormat("'Hôm nay lúc' HH:mm", 'vi').format(messageTime);
    } else if (difference.inDays == 1) {
      return DateFormat("'Hôm qua lúc' HH:mm", 'vi').format(messageTime);
    } else {
      return DateFormat('dd-MM-yyyy | HH:mm', 'vi').format(messageTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    String id = widget.post['id'] ?? '';
    String text = widget.post['text'] ?? '';
    String fileUrl = widget.post['fileUrl'] ?? '';
    String privacy = widget.post['privacy'] ?? '';
    int timestamp = widget.post['timestamp'] ?? 0;
    String type = widget.post['type'] ?? '';
    String iDUser = widget.post['userId'] ?? '';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white, size: 24), // Icon "X"
        ),
        title: Text(
          formattedTime(timestamp), // Hiển thị thời gian
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true, // Căn giữa thời gian
        actions: [
          widget.idUser != iDUser ?
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showReportBottomSheet(context);
            },
          ): IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              bottomSheet(context, id, privacy, text, fileUrl);
            },
          )
        ],
      ),

      body: Column(
        children: [
          // Hình ảnh căn giữa màn hình
          Expanded(
            child: Center(
              child: fileUrl.isNotEmpty
                  ? Image.network(fileUrl, fit: BoxFit.contain)
                  : const Text(
                "Hình ảnh không khả dụng",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          // Nội dung văn bản và nút Thích
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị văn bản bài viết

                if (text.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Text(
                      text,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  SizedBox(height: 8), // Khoảng cách giữa text và nút Like
                ],
                // Nút Thích & Bình luận
                Row(
                  children: [
                    // Nút Thích
                    GestureDetector(
                      onTap: () {
                        bool isLiked = likes.contains(widget.idUser);
                        toggleLike(id, widget.idUser, isLiked);
                      },
                      child: Container(
                        height: 36,
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFF212121),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              likes.contains(widget.idUser) ? Icons.favorite : Icons.favorite_border,
                              color: likes.contains(widget.idUser) ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Thích",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: likes.contains(widget.idUser) ? Color(0xFF6A0000) : Colors.grey,
                              ),
                            ),
                            if (likes.isNotEmpty) ...[
                              SizedBox(width: 10),
                              Container(
                                width: 1,
                                height: 16,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.favorite, color: Colors.red, size: 16),
                              SizedBox(width: 5),
                              Text('${likes.length}', style: TextStyle(fontSize: 15, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 8), // Khoảng cách giữa 2 nút

                    // Nút Bình luận
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Comment(
                              post: widget.post,
                              avt: widget.avt,
                              fullName: widget.fullName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(0, 36),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Color(0xFF212121),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: FutureBuilder<int>(
                        future: getTotalCommentsAndReplies(widget.post['id'] ?? ''),
                        builder: (context, snapshot) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.insert_comment_outlined, size: 18, color: Colors.grey),
                              if (snapshot.hasData && snapshot.data! > 0) ...[
                                SizedBox(width: 6),
                                Text(
                                  "${snapshot.data}",
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    Spacer(),

                    if (type == "avatar") ...[
                      ElevatedButton(
                        onPressed: () {
                          // Xử lý khi nhấn nút
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(0, 36),
                          padding: EdgeInsets.symmetric(horizontal: 60, vertical: 8),
                          backgroundColor: Color(0xFF212121),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.white, width: 1), // Thêm viền màu trắng
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 6),
                            Text(
                              "Đổi ảnh",
                              style: TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    ] else if (type == "imageCover") ...[
                      ElevatedButton(
                        onPressed: () {

                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(0, 36),
                          padding: EdgeInsets.symmetric(horizontal: 60, vertical: 8),
                          backgroundColor: Color(0xFF212121),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.white, width: 1), // Thêm viền màu trắng
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 6),
                            Text(
                              "Đổi ảnh bìa",
                              style: TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    ] else ...[
                      SizedBox(),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

    );
  }

  void _showReportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Xác nhận",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const Text(
                "Bạn muốn thông báo ảnh này có nội dung xấu?",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              _buildReportOption(context, "Nội dung nhạy cảm"),
              _buildReportOption(context, "Làm phiền"),
              _buildReportOption(context, "Spam hoặc lừa đảo"),
              _buildReportOption(context, "Lý do khác"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOption(BuildContext context, String reason) {
    return ListTile(
      title: Center(child: Text(reason)), // Căn giữa
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã báo cáo: $reason")),
        );
      },
    );
  }

  Widget _privacyOption(BuildContext context, DatabaseReference postRef, String postId, String privacy, IconData icon, String currentPrivacy) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[400]),
      title: Text(privacy),
      trailing: currentPrivacy == privacy ? Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        postRef.update({"privacy": privacy}).then((_) {
          Navigator.pop(context);
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi khi cập nhật: $error")),
          );
        });
      },
    );
  }
}