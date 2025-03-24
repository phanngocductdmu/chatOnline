import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SeeMoments extends StatefulWidget {
  final List<Map<String, dynamic>> moments;
  final Map<String, dynamic> userData;
  final String idFriend;
  final String idUser;

  const SeeMoments({
    super.key,
    required this.moments,
    required this.idFriend,
    required this.userData,
    required this.idUser,
  });

  @override
  SeeMomentsState createState() => SeeMomentsState();
}

class SeeMomentsState extends State<SeeMoments> {
  PageController pageController = PageController();
  int currentIndex = 0;
  Timer? timer;
  double _progressValue = 0.0;
  bool isClosing = false;
  int viewersCount = 0;
  bool _isTextFieldFocused = false;
  FocusNode _focusNode = FocusNode();

  late List<Map<String, dynamic>> validMoments;

  @override
  void initState() {
    super.initState();
    validMoments = widget.moments
        .where((moment) => moment['idUser'] == widget.idFriend && moment['isMoments'] == true)
        .toList();
    if (validMoments.isNotEmpty) {
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progressValue += 0.003;
      });

      if (_progressValue >= 1.0) {
        if (currentIndex < validMoments.length - 1) {
          _progressValue = 0.0;
          pageController.nextPage(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          if (Navigator.of(context).canPop() && !isClosing) {
            isClosing = true;
            Navigator.of(context).pop();
          }
        }
      }
    });
  }

  void showMomentOptions(BuildContext context, int currentIndex) {
    Map<String, dynamic> currentMoment = widget.moments[currentIndex];
    String privacyText;
    IconData privacyIcon;
    if (currentMoment['privacy'] == 'Tất cả bạn bè') {
      privacyText = "Tất cả bạn bè";
      privacyIcon = Icons.public;
    } else if (currentMoment['privacy'] == 'Một số bạn bè') {
      privacyText = "Một số bạn bè";
      privacyIcon = Icons.people_alt;
    } else if (currentMoment['privacy'] == 'Bạn bè ngoại trừ') {
      privacyText = "Bạn bè ngoại trừ";
      privacyIcon = Icons.person_off_outlined;
    } else {
      privacyText = "Không xác định";
      privacyIcon = Icons.help;
    }
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOption(
                icon: privacyIcon, // Sử dụng icon xác định ở trên
                text: "Ai xem được khoảnh khắc này?",
                subText: privacyText, // Hiển thị quyền riêng tư
                onTap: () {
                  Navigator.pop(context);
                  _showPrivacy(context, currentIndex);
                },
              ),
              _buildOption(
                icon: Icons.archive,
                text: "Lưu trữ",
                subText: "Chỉ mình bạn xem được khoảnh khắc đã lưu trữ",
                onTap: () {
                  Navigator.pop(context);
                  // Xử lý lưu trữ
                },
              ),
              _buildOption(
                icon: Icons.delete,
                text: "Xóa",
                color: Colors.black,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Xác nhận xóa"),
                        content: Text("Bạn có chắc muốn xóa khoảnh khắc này không?"),
                        actions: [
                          TextButton(
                            child: Text("Hủy"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text("Xóa", style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context); // Đóng bottom sheet
                              // Xóa khoảnh khắc
                              deleteMoment(currentMoment['id']);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void deleteMoment(String momentId) async {
    try {
      await FirebaseDatabase.instance.ref('Moments/$momentId').remove();
      print("Khoảnh khắc đã được xóa thành công!");
      Navigator.pop(context);
    } catch (e) {
      print("Lỗi khi xóa khoảnh khắc: $e");
    }
  }

  String formatTimestamp(int timestamp) {
    DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(messageTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} giây trước';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else {
      return '${difference.inHours} giờ trước';
    }
  }

  void _showPrivacy(BuildContext context, int currentIndex) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    'Cài đặt quyền riêng tư',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.public),
                  title: Text("Tất cả bạn bè"),
                  onTap: () {
                    setState(() {

                    });
                    Navigator.pop(context);
                  },
                ),
                Divider(thickness: 1, color: Colors.grey[200], indent: 56),
                ListTile(
                  leading: Icon(Icons.people_alt),
                  title: Text("Một số bạn bè"),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    setState(() {

                    });
                    Navigator.pop(context);
                  },
                ),
                Divider(thickness: 1, color: Colors.grey[200], indent: 56),
                ListTile(
                  leading: Icon(Icons.person_off_outlined), // Icon mới
                  title: Text("Bạn bè ngoại trừ"),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    setState(() {

                    });
                    Navigator.pop(context);
                  },
                ),
                Divider(thickness: 1, color: Colors.grey[200], indent: 56),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void _markStoryAsViewed(String currentStoryId, String userId) async {
    final DatabaseReference storyRef = FirebaseDatabase.instance.ref('story_views/$currentStoryId/viewers');
    DataSnapshot snapshot = await storyRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> viewers = snapshot.value as Map;
      if (!viewers.containsKey(userId)) {
        await storyRef.child(userId).set(true);
      } else {
      }
    } else {
      await storyRef.child(userId).set(true);
    }
  }

  void _sendReaction(String reaction, String currentStoryId) async {
    DatabaseReference userReactionRef = FirebaseDatabase.instance.ref("moments_reactions/$currentStoryId/reactions/${widget.idUser}");

    DatabaseEvent event = await userReactionRef.once();
    Map<dynamic, dynamic>? userReactions = event.snapshot.value as Map<dynamic, dynamic>?;

    if (userReactions != null && userReactions.length >= 5) {
      return;
    }

    int nextEmojiIndex = 1;
    while (userReactions?.containsKey("emoji_$nextEmojiIndex") ?? false) {
      nextEmojiIndex++;
    }
    String emojiKey = "emoji_$nextEmojiIndex";


    await userReactionRef.update({
      emojiKey: reaction,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (validMoments.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Không có khoảnh khắc nào để hiển thị",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPress: () {
          timer?.cancel();
        },
        onLongPressUp: () {
          if (timer?.isActive == false) {
            _startAutoSlide();
          }
        },
        onTapUp: (details) {
          double screenWidth = MediaQuery.of(context).size.width;
          double tapPosition = details.localPosition.dx;

          if (tapPosition < screenWidth / 2) {
            if (currentIndex > 0) {
              setState(() {
                _progressValue = 0.0;
              });
              pageController.previousPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          } else {
            if (currentIndex == validMoments.length - 1) {
              Navigator.pop(context);
            } else {
              pageController.nextPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        },
        child: PageView.builder(
          controller: pageController,
          itemCount: validMoments.length,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
              _progressValue = 0.0;
            });
          },
          itemBuilder: (context, index) {
            final moment = validMoments[index];
            _markStoryAsViewed(moment['id'], widget.idUser);
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    moment['url'],
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.center,
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      validMoments.length,
                          (i) => Flexible(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: i == currentIndex ? _progressValue : (i < currentIndex ? 1.0 : 0.0),
                            backgroundColor: Colors.grey.shade700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 60,
                  left: 20,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // AVT + tên
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: widget.userData['AVT'] != null
                                ? NetworkImage(widget.userData['AVT'])
                                : null,
                            backgroundColor: Colors.grey[300],
                            child: widget.userData['AVT'] == null
                                ? Icon(Icons.person, color: Colors.white, size: 20)
                                : null,
                          ),
                          SizedBox(width: 10),

                          SizedBox(
                            width: (widget.userData['fullName']?.length ?? 0) > 16 ? 130 : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userData['fullName'] ?? "Người dùng",
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min, // Chỉ sử dụng không gian cần thiết
                            children: [
                              // Thời gian
                              Text(
                                formatTimestamp(moment['timestamp']),
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                              SizedBox(width: 10),
                              // Icon quyền riêng tư
                              Icon(
                                moment['privacy'] == 'Tất cả bạn bè'
                                    ? Icons.public
                                    : moment['privacy'] == 'Một số bạn bè'
                                    ? Icons.people_alt
                                    : moment['privacy'] == 'Bạn bè ngoại trừ'
                                    ? Icons.person_off_outlined
                                    : Icons.lock,
                                color: Colors.grey[300],
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Nút X + 3 chấm
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.more_horiz_outlined, color: Colors.white),
                            onPressed: () {
                              showMomentOptions(context, index);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // Cho phép lướt ngang
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: _isTextFieldFocused
                              ? MediaQuery.of(context).size.width - 20 // Full màn hình trừ padding
                              : MediaQuery.of(context).size.width * 0.5, // Ban đầu 50% màn hình
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  focusNode: _focusNode,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: "Viết tin nhắn...",
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.white),
                                    prefixIcon: Icon(Icons.message, color: Colors.white),
                                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                  ),
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.send,
                                  maxLines: 1,
                                ),
                              ),
                              if (_isTextFieldFocused)
                                IconButton(
                                  icon: Icon(Icons.send, color: Colors.white),
                                  onPressed: () {

                                  },
                                ),
                            ],
                          ),
                        ),
                        if (!_isTextFieldFocused)
                          Row(
                            children: [
                              _buildReactionButton("❤️", "love", moment['id']),
                              _buildReactionButton("👍", "like", moment['id']),
                              _buildReactionButton("😂", "haha", moment['id']),
                              _buildReactionButton("😮", "wow", moment['id']),
                              _buildReactionButton("😢", "sad", moment['id']),
                              _buildReactionButton("😡", "angry", moment['id']),
                            ],
                          ),
                      ],
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReactionButton(String emoji, String reactionType, String idStory) {
    return GestureDetector(
      onTap: () {
        _sendReaction(reactionType, idStory);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String text,
    String? subText,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(text, style: TextStyle(color: color ?? Colors.black)),
      subtitle: subText != null
          ? Text(subText, style: TextStyle(color: Colors.grey, fontSize: 12))
          : null,
      onTap: onTap,
    );
  }
}
