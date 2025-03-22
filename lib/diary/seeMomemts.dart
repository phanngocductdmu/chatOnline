import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chatonline/message/option/personalPage/ReportUser.dart';
import 'package:chatonline/User/createMoments.dart';

class SeeMoments extends StatefulWidget {
  final String idUserPerson;
  final List<Map<String, dynamic>> moments;
  final List<String> userIds;
  final String idUser;

  const SeeMoments({
    super.key,
    required this.idUserPerson,
    required this.moments,
    required this.userIds,
    required this.idUser,
  });

  @override
  SeeMomentsState createState() => SeeMomentsState();
}

class SeeMomentsState extends State<SeeMoments> {
  List<StoryItem> _stories = [];
  late StoryController _storyController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  String avatar = "";
  String name = "Người dùng";
  String time = "";
  String currentStoryId = "a";
  bool hasViewed = false;
  int viewersCount = 0;
  int timeStory = 700;
  bool _isTextFieldFocused = false;
  FocusNode _focusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    _storyController = StoryController();
    _currentUserIndex = widget.userIds.indexOf(widget.idUserPerson);
    _loadStories();
    _focusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _focusNode.hasFocus;
      });
    });
  }

  void _fetchUserInfo(String userId) {
    DatabaseReference userRef =
    FirebaseDatabase.instance.ref().child("users").child(userId);

    userRef.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<String, dynamic> userData =
        Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          avatar = userData['AVT'] ?? "";
          name = userData['fullName'] ?? "Người dùng";
        });
      }
    }).catchError((error) {
      print("Lỗi lấy thông tin user: $error");
    });
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

  void _showOptionsMenu(String idFiend) {
    _storyController.pause();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.grey),
              title: const Text("Báo cáo"),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ReportUserScreen(idUser: widget.idUser, type: "Story", idFriend: idFiend,)));
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      _storyController.play();
    });
  }

  void showMomentOptions(BuildContext context, int currentIndex) {
    _storyController.pause();
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

  void _showPrivacy(BuildContext context, int currentIndex) {
    _storyController.pause();
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
                  leading: Icon(Icons.person_off_outlined),
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
    ).whenComplete(() {
      _storyController.play();
    });
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

  void _sendReaction(String reaction) async {
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

  void _goToPreviousStory() {
    if (_currentStoryIndex > 0) {
      _storyController.previous();
    } else if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
        _loadStories();
      });
    }
  }

  void _goToNextUser() {
    if (_currentUserIndex < widget.userIds.length - 1) {
      setState(() {
        _currentUserIndex++;
        _storyController.dispose();
        _storyController = StoryController();
        _loadStories();

        _isTextFieldFocused = false;
        _focusNode.unfocus();
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _loadStories() {
    String currentUserId = widget.userIds[_currentUserIndex];
    _fetchUserInfo(currentUserId);
    List<Map<String, dynamic>> userMoments = widget.moments
        .where((moment) => moment['idUser'] == currentUserId)
        .toList();

    if (userMoments.isNotEmpty) {
      time = formatTimestamp(userMoments[0]['timestamp']);
    }

    List<StoryItem> newStories = userMoments.map((moment) {
      return StoryItem.pageImage(
        url: moment['url'] ?? "",
        controller: _storyController,
        caption: Text(
          moment['caption'] ?? "",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        duration: Duration(seconds: timeStory),
      );
    }).toList();

    setState(() {
      _stories = [];
      _currentStoryIndex = 0;
      currentStoryId = currentStoryId;

      // Tắt bàn phím khi tải story mới
      _isTextFieldFocused = false;
      _focusNode.unfocus();
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() {
        _stories = newStories;
      });
    });
  }

  void _markStoryAsViewed(String currentStoryId, String userId) async {
    final DatabaseReference storyRef = FirebaseDatabase.instance.ref('story_views/$currentStoryId/viewers');
    DataSnapshot snapshot = await storyRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> viewers = snapshot.value as Map;
      if (!viewers.containsKey(userId)) {
        await storyRef.child(userId).set(true);
      } else {
        // print("User has already viewed");
      }
    } else {
      await storyRef.child(userId).set(true);
    }
  }

  void listenToViewers(String idStory) {
    DatabaseReference ref = FirebaseDatabase.instance.ref("story_views/$idStory/viewers");
    ref.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        int count = (event.snapshot.value as Map).length;
        setState(() {
          viewersCount = count;
        });
      } else {
        setState(() {
          viewersCount = 0;
        });
      }
    });
  }

  void showViewersBottomSheet(BuildContext context, String idStory, int viewersCount) {
    _storyController.pause();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchViewersDetails(idStory),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 400,
                child: Center(child: SizedBox.shrink()),
              );
            }
            List<Map<String, dynamic>> viewersData = snapshot.data ?? [];
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 10),
                  Center( // Căn giữa tiêu đề
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Để Row không chiếm hết chiều rộng
                      children: [
                        Icon(Icons.remove_red_eye, color: Colors.grey, size: 24),
                        SizedBox(width: 10),
                        Text(
                          "$viewersCount người đã xem",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: viewersData.isEmpty
                        ? Center(child: Text("Chưa có ai xem story"))
                        : ListView.builder(
                      itemCount: viewersData.length,
                      itemBuilder: (context, index) {
                        var viewer = viewersData[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey,
                                backgroundImage: viewer['AVT'] != null && viewer['AVT'].isNotEmpty
                                    ? NetworkImage(viewer['AVT'])
                                    : null,
                                child: viewer['AVT'] == null || viewer['AVT'].isEmpty
                                    ? Icon(Icons.person, color: Colors.white, size: 30)
                                    : null,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(viewer['fullName'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                                    viewer['reaction'] != null && viewer['reaction'].isNotEmpty
                                        ? Row(
                                      children: viewer['reaction']
                                          .map<Widget>((emoji) => Padding(
                                        padding: const EdgeInsets.symmetric(horizontal:2),
                                        child: Text(_getReactionEmoji(emoji), style: TextStyle(fontSize: 16)),
                                      ))
                                          .toList(),
                                    )
                                        : SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _storyController.play();
    });
  }

  String _getReactionEmoji(String reaction) {
    switch (reaction) {
      case "love":
        return "❤️";
      case "like":
        return "👍";
      case "haha":
        return "😂";
      case "wow":
        return "😮";
      case "sad":
        return "😢";
      case "angry":
        return "😡";
      default:
        return reaction;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchViewersDetails(String idStory) async {
    DatabaseReference viewersRef = FirebaseDatabase.instance.ref("story_views/$idStory/viewers");
    DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");
    DatabaseReference reactionsRef = FirebaseDatabase.instance.ref("moments_reactions/$idStory/reactions");
    List<Map<String, dynamic>> viewersList = [];

    DataSnapshot snapshot = await viewersRef.get();
    if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
      Map<dynamic, dynamic> viewersData = Map<dynamic, dynamic>.from(snapshot.value as Map);

      for (String userId in viewersData.keys) {
        Map<String, dynamic> userInfo = {
          'id': userId,
          'fullName': "Người dùng ẩn danh",
          'AVT': "",
          'reaction': [],
        };

        // Lấy thông tin user
        DataSnapshot userSnapshot = await usersRef.child(userId).get();
        if (userSnapshot.exists && userSnapshot.value is Map<dynamic, dynamic>) {
          Map<dynamic, dynamic> userData = Map<dynamic, dynamic>.from(userSnapshot.value as Map);
          userInfo['fullName'] = userData['fullName'] ?? "Người dùng";
          userInfo['AVT'] = userData['AVT'] ?? "";
        }

        // Lấy reaction nếu có
        DataSnapshot reactionSnapshot = await reactionsRef.child(userId).get();
        if (reactionSnapshot.exists && reactionSnapshot.value is Map<dynamic, dynamic>) {
          Map<dynamic, dynamic> reactionData = Map<dynamic, dynamic>.from(reactionSnapshot.value as Map);

          List<String> sortedReactions = [
            reactionData['emoji_5'] as String? ?? '',
            reactionData['emoji_4'] as String? ?? '',
            reactionData['emoji_3'] as String? ?? '',
            reactionData['emoji_2'] as String? ?? '',
            reactionData['emoji_1'] as String? ?? '',
          ].where((emoji) => emoji.isNotEmpty).toList();

          userInfo['reaction'] = sortedReactions;
        }

        viewersList.add(userInfo);
      }
    }
    return viewersList;
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = widget.userIds[_currentUserIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _stories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
            onTapDown: (details) {
              double screenWidth = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < screenWidth / 3) {
                _goToPreviousStory();
              }
            },
            child: StoryView(
              storyItems: _stories,
              controller: _storyController,
              onComplete: _goToNextUser,
              onVerticalSwipeComplete: (direction) {
                if (direction == Direction.down) {
                  Navigator.pop(context);
                }
              },
              onStoryShow: (storyItem, index) {
                _currentStoryIndex = index;
                var currentStory = widget.moments
                    .where((moment) => moment['idUser'] == widget.userIds[_currentUserIndex])
                    .toList()[index];
                String idStory = currentStory['id'];
                if (widget.idUser != currentUserId) {
                  _markStoryAsViewed(idStory, widget.idUser);
                }
                listenToViewers(idStory);
                Future.microtask(() {
                  if (mounted) {
                    setState(() {
                      time = formatTimestamp(currentStory['timestamp']);
                      currentStoryId = idStory;
                    });
                  }
                });
              },
            ),
          ),

          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  backgroundColor: Colors.grey,
                  child: avatar.isEmpty
                      ? const Icon(Icons.person, size: 24, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),

                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    int index = int.tryParse(currentUserId.toString()) ?? 0; 
                    currentUserId == widget.idUser
                        ? showMomentOptions(context, index)
                        : _showOptionsMenu(currentUserId);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),


          if (widget.idUser != currentUserId)
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
                          _buildReactionButton("❤️", "love"),
                          _buildReactionButton("👍", "like"),
                          _buildReactionButton("😂", "haha"),
                          _buildReactionButton("😮", "wow"),
                          _buildReactionButton("😢", "sad"),
                          _buildReactionButton("😡", "angry"),
                        ],
                      ),
                  ],
                ),
              ),
            ) else ...[
            Positioned(
              bottom: 20,
              left: 20,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      showViewersBottomSheet(context, currentStoryId, viewersCount);
                    },
                    icon: Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 24),
                  ),
                  Text(
                    "$viewersCount",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CreateMoments(idUser: widget.idUser)));
                },
                icon: Icon(Icons.add_box_outlined, color: Colors.white),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildReactionButton(String emoji, String reactionType) {
    return GestureDetector(
      onTap: () {
        _sendReaction(reactionType);
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

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }
}
