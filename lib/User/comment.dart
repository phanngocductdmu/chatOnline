import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../message/option/personalPage/ReportUser.dart';

class Comment extends StatefulWidget {
  final Map<String, dynamic> post;
  final String avt;
  final String fullName;

  const Comment({
    super.key,
    required this.post,
    required this.avt,
    required this.fullName
  });

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  String? userId;
  String? replyingTo;
  String? replyingCommentId;
  String? commentText;
  String? replyingId;
  bool showReplies = false;

  TextEditingController replyController = TextEditingController();
  TextEditingController commentController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadUserId();
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

  void submitComment(String postId, String comment, String userId) {
    FirebaseDatabase.instance
        .ref("posts/$postId/comments")
        .push()
        .set({
      'comment': comment,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'userId': userId
    })
        .then((_) {
      print('Comment submitted');
    })
        .catchError((error) {
      print('Error submitting comment: $error');
    });
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
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM/yyyy', 'vi').format(messageTime);
    }
  }

  Stream<List<String>> getLikesStream(String postId) {
    return FirebaseDatabase.instance.ref("posts/$postId/likes").onValue.map((event) {
      if (event.snapshot.value != null) {
        Map<String, dynamic> likesMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        return likesMap.keys.toList();
      }
      return [];
    });
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId) {
    return FirebaseDatabase.instance
        .ref('posts/$postId/comments')
        .orderByChild('timestamp')
        .onValue
        .asyncMap((event) async {
      final comments = event.snapshot.value as Map<dynamic, dynamic>? ?? {};

      List<Map<String, dynamic>> enrichedComments = [];
      for (var entry in comments.entries) {
        final comment = Map<String, dynamic>.from(entry.value);
        comment['id'] = entry.key;

        if (comment.containsKey('userId')) {
          final userSnapshot = await FirebaseDatabase.instance
              .ref('users/${comment['userId']}')
              .get();

          if (userSnapshot.exists) {
            final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            comment['userAvatar'] = userData['AVT'] ?? '';
            comment['userName'] = userData['fullName'] ?? 'Người dùng ẩn danh';
          } else {
            comment['userAvatar'] = '';
            comment['userName'] = 'Người dùng ẩn danh';
          }
        }

        final repliesSnapshot = await FirebaseDatabase.instance
            .ref('posts/$postId/comments/${entry.key}/replies')
            .orderByChild('timestamp')
            .get();

        if (repliesSnapshot.exists) {
          comment['replies'] = (repliesSnapshot.value as Map<dynamic, dynamic>)
              .entries
              .map((e) => Map<String, dynamic>.from(e.value)..['id'] = e.key)
              .toList()
            ..sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int)); // Sắp xếp từ cũ -> mới
        } else {
          comment['replies'] = [];
        }

        enrichedComments.add(comment);
      }
      enrichedComments.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      return enrichedComments;
    });
  }

  void toggleLikeComment(String postId, String commentId, String userId, {String? replyId}) {
    DatabaseReference ref;
    if (replyId == null) {
      ref = FirebaseDatabase.instance
          .ref("posts/$postId/comments/$commentId/likes/$userId");
    } else {
      ref = FirebaseDatabase.instance
          .ref("posts/$postId/comments/$commentId/replies/$replyId/likes/$userId");
    }
    ref.once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        ref.remove();
      } else {
        ref.set(true);
      }
    });
  }

  void replyToComment(String postId, String commentId, String userId, String replyText, String replyingId) {
    DatabaseReference repliesRef = FirebaseDatabase.instance
        .ref("posts/$postId/comments/$commentId/replies")
        .push();

    repliesRef.set({
      "comment": replyText,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "userId": userId,
      "replyingId" :replyingId,
    });
  }

  Stream<Map<String, dynamic>> getUserInfo(String userId) {
    return FirebaseDatabase.instance.ref("users/$userId").onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return {};

      return {
        "userId": userId,
        "userName": data["fullName"] ?? "Ẩn danh",
        "userAvatar": data["AVT"] ?? "",
      };
    });
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
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.privacy_tip, color: Colors.blue),
                    title: Text("Chỉnh sửa quyền xem"),
                    onTap: () {
                      Navigator.pop(context);
                      editPrivacy(context, postId, privacy);
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.edit, color: Colors.green),
                    title: Text("Chỉnh sửa bài đăng"),
                    onTap: () {
                      Navigator.pop(context);
                      editPost(context, postId, text, fileUrl);
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text("Xóa bài đăng"),
                    onTap: () {
                      Navigator.pop(context);
                      deletePost(context, postId);
                    },
                  ),
                ],
              ),
            );
          },
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
      leading: Icon(icon, color: Colors.blue),
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

  @override
  Widget build(BuildContext context) {
    String id = widget.post['id'] ?? '';
    String text = widget.post['text'] ?? '';
    String fileUrl = widget.post['fileUrl'] ?? '';
    String privacy = widget.post['privacy'] ?? '';
    int timestamp = widget.post['timestamp'] ?? 0;
    String type = widget.post['type'] ?? '';
    String idUser = widget.post['userId'] ?? '';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {});
      },
      child: Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.white, size: 27),
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
          title: GestureDetector(
            child: Text(
              'Bình luận',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 19,
              ),
            ),
          ),
          actions: [
            idUser == userId ?
            IconButton(
              icon: Icon(Icons.more_horiz_outlined),
              onPressed: () {
                bottomSheet(context, id, privacy, text, fileUrl);
              },
            ):
            IconButton(
              icon: Icon(Icons.more_horiz_outlined),
              onPressed: () {
                _showReportBottomSheet(context, id, userId!);
              },
            ),
          ],
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildUserInfo(timestamp),
                    buildPostContent(text, fileUrl),
                    buildLikeButton(id),
                    Divider(),
                    buildCommentList(id),
                  ],
                ),
              ),
            ),
            buildCommentSection(commentController, id),
          ],
        ),

      ),
    );
  }

  Widget buildCommentList(String postId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getCommentsStream(postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Chưa có bình luận nào.'));
        }
        List<Map<String, dynamic>> comments = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return buildCommentItem(postId, comment);
          },
        );
      },
    );
  }

  Widget buildCommentItem(String postId, Map<String, dynamic> comment, {double indent = 15}) {
    String commentId = comment['id'];
    List<Map<String, dynamic>> replies = List<Map<String, dynamic>>.from(comment['replies'] ?? []);

    return Padding(
      padding: EdgeInsets.only(left: indent, top: 5, bottom: 5, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: (comment['userAvatar'] != null && comment['userAvatar']!.isNotEmpty)
                    ? NetworkImage(comment['userAvatar']!)
                    : null,
                child: (comment['userAvatar'] == null || comment['userAvatar']!.isEmpty)
                    ? Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              SizedBox(width: 10),

              // Nội dung bình luận
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          comment['userName'] ?? '',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => toggleLikeComment(postId, commentId, userId!),
                          icon: Icon(
                            Icons.favorite,
                            color: (comment['likes']?.containsKey(userId) ?? false) ? Colors.red : Colors.grey,
                          ),
                          iconSize: 18,
                        ),
                      ],
                    ),
                    Text(comment['comment'] ?? '', style: TextStyle(fontSize: 14)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              formattedTime(comment['timestamp']),
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            SizedBox(width: 10),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  replyingId = comment['userId'];
                                  replyingTo = comment['userName'];
                                  commentText = comment['comment'];
                                  replyingCommentId = commentId;
                                  showReplies = true;
                                });
                              },
                              child: Text("Trả lời", style: TextStyle(fontSize: 12, color: Colors.black)),
                            ),
                            if (replies.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    showReplies = !showReplies;
                                  });
                                },
                                child: Text(
                                  showReplies ? "Ẩn" : "Xem thêm",
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                        if ((comment['likes']?.length ?? 0) > 0)
                          Text(
                            "${comment['likes']?.length} lượt thích",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (replies.isNotEmpty && showReplies)
            Column(
              children: replies.map((reply) {
                return buildCommentReplyItem(postId, commentId, reply, indent: indent + 30);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget buildCommentReplyItem(String postId, String commentId, Map<String, dynamic> reply, {double indent = 30}) {
    String replyId = reply['id'];

    return StreamBuilder<Map<String, dynamic>>(
      stream: getUserInfo(reply['userId']),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return SizedBox();

        final userData = userSnapshot.data!;
        final completeReply = {
          ...reply,
          'userId': userData['userId'],
          'userName': userData['userName'],
          'userAvatar': userData['userAvatar'],
        };

        return StreamBuilder<Map<String, dynamic>>(
          stream: getUserInfo(reply['replyingId']),
          builder: (context, replyingSnapshot) {
            final replyingData = replyingSnapshot.data ?? {};
            final replyingName = replyingData['userName'] ?? '';

            return Padding(
              padding: EdgeInsets.only(left: indent, top: 5, bottom: 5, right: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: (completeReply['userAvatar'] != null && completeReply['userAvatar']!.isNotEmpty)
                            ? NetworkImage(completeReply['userAvatar']!)
                            : null,
                        child: (completeReply['userAvatar'] == null || completeReply['userAvatar']!.isEmpty)
                            ? Icon(Icons.person, color: Colors.white, size: 18)
                            : null,
                      ),
                      SizedBox(width: 10),

                      // Nội dung trả lời
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  completeReply['userName'] ?? '',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  onPressed: () => toggleLikeComment(postId, commentId, userId!, replyId: replyId),
                                  icon: Icon(
                                    Icons.favorite,
                                    color: (reply['likes']?.containsKey(userId) ?? false) ? Colors.red : Colors.grey,
                                  ),
                                  iconSize: 16,
                                ),
                              ],
                            ),

                            // Hiển thị tên người dùng + tên người được trả lời + nội dung comment
                            Text.rich(
                              TextSpan(
                                children: [
                                  if (replyingName.isNotEmpty)
                                    TextSpan(
                                      text: '$replyingName: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green, // Đổi màu xanh dương
                                      ),
                                    ),
                                  TextSpan(
                                    text: completeReply['comment'] ?? '',
                                    style: TextStyle(fontSize: 13, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),

                            // Thời gian & nút trả lời
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                  children: [
                                    Text(
                                      formattedTime(completeReply['timestamp']),
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          replyingId = completeReply['userId'];
                                          replyingTo = completeReply['userName'];
                                          commentText = completeReply['comment'];
                                          replyingCommentId = commentId;
                                        });
                                      },
                                      child: Text("Trả lời", style: TextStyle(fontSize: 11, color: Colors.black)),
                                    ),
                                  ],
                                ),
                                  if ((completeReply['likes']?.length ?? 0) > 0)
                                    Text(
                                      "${completeReply['likes']?.length} lượt thích",
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                              ]
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildUserInfo(int timestamp) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(widget.avt),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fullName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                formattedTime(timestamp),
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPostContent(String text, String fileUrl) {
    return Column(
      children: [
        if (text.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 15, top: 10, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
        if (fileUrl.isNotEmpty)
          ClipRRect(
            child: Image.network(
              fileUrl,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }

  Widget buildLikeButton(String postId) {
    return Padding(
      padding: EdgeInsets.only(left: 20, top: 15, bottom: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 15),
          decoration: BoxDecoration(
            color: Color(0xFFECEDEF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<List<String>>(
                stream: getLikesStream(postId),
                builder: (context, snapshot) {
                  List<String> likes = snapshot.data ?? [];
                  return GestureDetector(
                    onTap: () {
                      bool isLiked = likes.contains(userId!);
                      toggleLike(postId, userId!, isLiked);
                    },
                    child: Row(
                      children: [
                        Icon(
                          likes.contains(userId) ? Icons.favorite : Icons.favorite_border,
                          color: likes.contains(userId) ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Thích",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: likes.contains(userId) ? Color(0xFF6A0000) : Colors.grey,
                          ),
                        ),
                        Row(
                          children: [
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
                              Text('${likes.length}', style: TextStyle(fontSize: 15)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCommentSection(TextEditingController controller, String postId) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị comment gốc nếu đang trả lời
          if (replyingTo != null && commentText != null)
            Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "$replyingTo: $commentText",
                      style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        replyingTo = null;
                        replyingCommentId = null;
                        commentText = null;
                        replyingId = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          Row(
            children: [
              // Icon sticker
              IconButton(
                icon: Icon(Icons.emoji_emotions_outlined),
                onPressed: () {
                  // Add sticker functionality here
                },
              ),

              // Input comment
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: replyingTo != null ? "Trả lời $replyingTo..." : "Nhập bình luận...",
                    border: InputBorder.none,
                  ),
                  maxLines: 1,
                ),
              ),

              // Gửi bình luận
              IconButton(
                icon: Icon(Icons.send, color: Color(0xFF38ef7d)),
                onPressed: () {
                  String comment = controller.text.trim();
                  if (comment.isNotEmpty) {
                    if (replyingTo != null && replyingCommentId != null && replyingId != null) {
                      replyToComment(postId, replyingCommentId!, userId!, comment, replyingId!);
                    } else {
                      submitComment(postId, comment, userId!);
                    }
                    setState(() {
                      controller.clear();
                      replyingTo = null;
                      replyingCommentId = null;
                      commentText = null;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

}
