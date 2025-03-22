import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'createMoments.dart';

class SeeMoments extends StatefulWidget {
  final List<Map<String, dynamic>> moments;
  final Map<String, dynamic> userData;
  final String idUser;

  const SeeMoments({
    super.key,
    required this.moments,
    required this.idUser,
    required this.userData,
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

  late List<Map<String, dynamic>> validMoments;

  @override
  void initState() {
    super.initState();
    validMoments = widget.moments
        .where((moment) => moment['idUser'] == widget.idUser && moment['isMoments'] == true)
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
    // Map<String, dynamic> currentMoment = widget.moments[currentIndex];
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
    );
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
          'AVT': "https://via.placeholder.com/150",
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
            listenToViewers(moment['id']);
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
                  bottom: 20,
                  left: 20,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          showViewersBottomSheet(context, moment['id'], viewersCount);
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
              ],
            );
          },
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
