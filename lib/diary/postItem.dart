import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatonline/User/comment.dart';
import 'package:chatonline/message/option/personalPage/ReportUser.dart';
import 'seeMedia.dart';

class PostItem extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostItem({super.key, required this.post});

  @override
  PostItemState createState() => PostItemState();
}

class PostItemState extends State<PostItem> {
  String? userId;
  String avt = "";
  String fullName = "Người dùng";
  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchUserInfo();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  void toggleLike(String postId, String userId, bool isLiked) {
    DatabaseReference likeRef = FirebaseDatabase.instance.ref("posts/$postId/likes/$userId");
    if (isLiked) {
      likeRef.remove();
    } else {
      likeRef.set(true);
    }
  }

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

  void _showReportBottomSheet(BuildContext context, String idFriend, String idUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
          child: Wrap(
            children: [
              const Center(
                child: Text(
                  "Báo Xấu",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    "Bạn muốn báo xấu nội dung này?",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.grey),
                title: const Text("Báo xấu", style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReportUserScreen(idFriend: idFriend, idUser: idUser, type: "posts report",)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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

  Future<String> uploadImageToFirebase(XFile image, String postId) async {
    Reference storageRef = FirebaseStorage.instance.ref().child("posts/$postId.jpg");
    await storageRef.putFile(File(image.path));
    return await storageRef.getDownloadURL();
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

  String formattedTime(int timestamp) {
    DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(messageTime);
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} giây trước';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return DateFormat("'Hôm nay lúc' hh:mm", 'vi').format(messageTime);
    } else if (difference.inDays == 1) {
      return DateFormat("'Hôm qua lúc' hh:mm", 'vi').format(messageTime);
    } else {
      return DateFormat("dd/MM 'lúc' hh:mm", 'vi').format(messageTime);
    }
  }

  Future<Map<String, dynamic>?> fetchUserInfo(String iDUSer) async {
    try {
      DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$iDUSer");
      DataSnapshot snapshot = await userRef.get();
      if (!snapshot.exists) return null;
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      print("Lỗi khi lấy dữ liệu người dùng: $e");
      return null;
    }
  }

  Future<void> _fetchUserInfo() async {
    String userId = widget.post['userId'] ?? '';
    if (userId.isNotEmpty) {
      var userData = await fetchUserInfo(userId);
      if (userData != null) {
        setState(() {
          avt = userData['AVT'] ?? "";
          fullName = userData['fullName'] ?? "Người dùng";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return SizedBox();
    }
    String id = widget.post['id'] ?? '';
    String text = widget.post['text'] ?? '';
    String fileUrl = widget.post['fileUrl'] ?? '';
    String privacy = widget.post['privacy'] ?? '';
    int timestamp = widget.post['timestamp'] ?? 0;
    String type = widget.post['type'] ?? '';
    String IDUser = widget.post['userId'] ?? '';
    List<String> likes = widget.post['likes'] is Map
        ? Map<String, bool>.from(widget.post['likes']).keys.toList()
        : List<String>.from(widget.post['likes'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4),
        Card(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: avt.isNotEmpty ? NetworkImage(avt) : null,
                      backgroundColor: Colors.grey[300],
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              fullName,
                              style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              type == 'avatar'
                                  ? " đã thay đổi ảnh đại diện"
                                  : type == 'imageCover'
                                  ? " đã thay đổi ảnh bìa"
                                  : "",
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            )
                          ],
                        ),
                        Text(
                          formattedTime(timestamp),
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    Spacer(),
                    userId == IDUser
                        ? IconButton(
                      onPressed: () {
                        bottomSheet(context, id, privacy, text, fileUrl);
                      },
                      icon: Icon(Icons.more_horiz, color: Colors.grey),
                    )
                        : IconButton(
                      onPressed: () {
                        _showReportBottomSheet(context, IDUser, userId!);
                      },
                      icon: Icon(Icons.more_horiz, color: Colors.grey),
                    ),
                  ],
                ),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: TextStyle(fontSize: 16),
                  ),
                if (fileUrl.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(context,
                            MaterialPageRoute(builder: (context) =>
                                SeeMedia(
                                  post: widget.post,
                                  idUser: userId!,
                                  avt: avt,
                                  fullName: fullName,
                                ))
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: SizedBox(
                              child: Image.network(
                                fileUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),

                      /// Tim và bình luận
                      Row(
                        children: [
                          likes.isNotEmpty
                              ? Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.red, size: 18),
                              SizedBox(width: 4),
                              Text(
                                "${likes.length} bạn",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          )
                              : SizedBox(),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              bool isLiked = likes.contains(userId!);
                              toggleLike(id, userId!, isLiked);
                            },
                            icon: Icon(
                              likes.contains(userId!) ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: likes.contains(userId!) ? Colors.red : Colors.black87,
                            ),
                            label: Text(
                              "Thích",
                              style: TextStyle(
                                fontSize: 16,
                                color: likes.contains(userId!) ? Color(0xFF6A0000) : Colors.black87,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                              backgroundColor: Color(0xFFf7f7f7),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Comment(
                                    post: widget.post,
                                    avt: avt,
                                    fullName: fullName,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              backgroundColor: Color(0xFFf7f7f7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: FutureBuilder<int>(
                              future: getTotalCommentsAndReplies(widget.post['id'] ?? ''),
                              builder: (context, snapshot) {
                                if (snapshot.data == 0) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.insert_comment_outlined, size: 20, color: Colors.black87),
                                    ],
                                  );
                                }

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.insert_comment_outlined, size: 20, color: Colors.black87),
                                    SizedBox(width: 6),
                                    Text(
                                      "${snapshot.data}",
                                      style: TextStyle(fontSize: 14, color: Colors.black87,),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 5),
      ],
    );
  }
}