import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'postNews.dart';
import 'postItem.dart';
import 'showAvatarOptions.dart';
import 'ShowCoverImageOptions.dart';

class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  String? idUser;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getString('userId');
    });
    if (idUser != null) {

    }
  }

  Future<Map<String, dynamic>?> fetchUserInfo() async {
    try {
      DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$idUser");
      DataSnapshot snapshot = await userRef.get();
      if (!snapshot.exists) return null;
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      print("Lỗi khi lấy dữ liệu người dùng: $e");
      return null;
    }
  }

  void _openSeeLogBottomSheet(BuildContext context) {

  }

  Stream<Map<String, dynamic>> fetchUserPosts() {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref("posts");
    return dbRef.onValue.map((event) {
      if (event.snapshot.value == null) return {"posts": [], "imageCount": 0};
      Map<dynamic, dynamic> posts = event.snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> userPosts = posts.entries
          .where((entry) => entry.value["userId"] == idUser && entry.value["type"] != "avatar" && entry.value["type"] != "imageCover")
          .map((entry) {
        Map<dynamic, dynamic>? likes = entry.value["likes"] as Map<dynamic, dynamic>?;
        return {
          "id": entry.key,
          "fileUrl": entry.value["fileUrl"],
          "text": entry.value["text"],
          "timestamp": entry.value["timestamp"],
          "type": entry.value["type"],
          "userId": entry.value["userId"],
          "privacy": entry.value["privacy"],
          "likes": likes != null ? likes.keys.toList() : [],
          "likeCount": likes?.length ?? 0,
        };
      }).toList()
        ..sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));
      int imageCount = userPosts.where((post) => post["type"] == "image").length;
      int videoCount = userPosts.where((post) => post["type"] == "video").length;

      return {"posts": userPosts, "imageCount": imageCount, "videoCount": videoCount};
    });
  }

  Future<int> fetchUserImageCount() async {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref("posts");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idUser = prefs.getString('userId');

      if (idUser == null) return 0;

      DatabaseEvent event = await dbRef.once();
      if (event.snapshot.value == null) return 0;

      Map<dynamic, dynamic> posts = event.snapshot.value as Map<dynamic, dynamic>;

      int imageCount = posts.entries
          .where((entry) => entry.value["userId"] == idUser && entry.value["type"] == "image")
          .length;

      return imageCount;
    } catch (e) {
      print("Lỗi khi lấy số lượng ảnh: $e");
      return 0;
    }
  }

  Future<int> fetchUserVideoCount() async {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref("posts");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idUser = prefs.getString('userId');

      if (idUser == null) return 0;

      DatabaseEvent event = await dbRef.once();
      if (event.snapshot.value == null) return 0;

      Map<dynamic, dynamic> posts = event.snapshot.value as Map<dynamic, dynamic>;

      int imageCount = posts.entries
          .where((entry) => entry.value["userId"] == idUser && entry.value["type"] == "video")
          .length;

      return imageCount;
    } catch (e) {
      print("Lỗi khi lấy số lượng ảnh: $e");
      return 0;
    }
  }

  Stream<List<Map<String, dynamic>>> getMomentsStream(String userId) {
    DatabaseReference momentsRef = FirebaseDatabase.instance.ref("Moments");

    return momentsRef
        .orderByChild("idUser")
        .equalTo(userId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return [];

      return data.entries.map((entry) {
        return {
          "id": entry.key,
          ...Map<String, dynamic>.from(entry.value),
        };
      }).toList();
    });
  }

  Stream<Map<String, dynamic>> getLatestAvatarStream(String userId) {
    return FirebaseDatabase.instance
        .ref()
        .child('posts')
        .orderByChild('userId')
        .equalTo(userId)
        .limitToLast(1)
        .onValue
        .map((event) {
      Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null || data.isEmpty) return {};
      var latestAvatar = data.values.firstWhere(
            (element) => element['type'] == 'avatar',
        orElse: () => {},
      );
      return latestAvatar.isNotEmpty ? Map<String, dynamic>.from(latestAvatar) : {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6F8),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text("Không thể tải thông tin"));
          }
          Map<String, dynamic> userData = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildCoverImage(userData),
                    _buildHeader(),
                    Positioned(
                      bottom: -25,
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      child: _buildAvatar(userData, context),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                _buildUserInfo(userData),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 10),
                _buildPostInput(context),
                const SizedBox(height: 10),
                _buildUserPosts(userData),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoverImage(Map<String, dynamic> userData) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => ShowCoverImageOptions(userData: userData),
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 250,
        child: userData['Bia'] != null && userData['Bia'].isNotEmpty
            ? Image.network(
          userData['Bia'],
          fit: BoxFit.cover,
        )
            : Container(
          color: Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> userData, BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: getLatestAvatarStream(idUser!),
      builder: (context, AsyncSnapshot<Map<String, dynamic>> avatarSnapshot) {
        bool hasMoment = false;
        if (avatarSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (avatarSnapshot.hasData) {
          Map<String, dynamic> avatarData = avatarSnapshot.data ?? {};
          String avatarUrl = avatarData.isNotEmpty && avatarData['fileUrl'] != null
              ? avatarData['fileUrl']
              : '';
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: getMomentsStream(idUser!),
            builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> momentsSnapshot) {
              print("aaaaaaaaaaaaaaa ${avatarData['id']}");
              if (momentsSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (momentsSnapshot.hasData && momentsSnapshot.data!.isNotEmpty) {
                hasMoment = momentsSnapshot.data!.any((moment) => moment["isMoments"] == true);
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => ShowAvatarOptions(
                            userData: userData,
                            avatarData : avatarData,
                            idUser: idUser!,
                            hasMoment: hasMoment,
                            moments: momentsSnapshot.data ?? [],
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: hasMoment ? 57 : 50,
                        backgroundColor: Color(0xFFF5F6F8),
                        child: Container(
                          padding: EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: hasMoment ? Border.all(color: Colors.green.shade400, width: 3) : null,
                          ),
                          child: CircleAvatar(
                            radius: 49,
                            backgroundColor: Color(0xFFF5F6F8),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              backgroundColor: avatarUrl.isEmpty
                                  ? Colors.grey[300]
                                  : Colors.transparent,
                              child: avatarUrl.isEmpty
                                  ? Icon(Icons.person, color: Colors.white, size: 50)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          return Center(child: Icon(Icons.person, size: 50, color: Colors.grey));
        }
      },
    );
  }

  Widget _buildUserInfo(Map<String, dynamic> userData) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            userData['fullName'] ?? "",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            userData['bio'] ?? "",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: StreamBuilder<Map<String, dynamic>>(
          stream: fetchUserPosts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox();
            }

            int imageCount = snapshot.data?["imageCount"] ?? 0;
            int videoCount = snapshot.data?["videoCount"] ?? 0;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildButton(Icons.photo_library, "Ảnh của tôi", imageCount, Colors.blueAccent),
                  _buildButton(Icons.video_library, "Video của tôi", videoCount, Colors.green),
                  _buildButton(Icons.auto_awesome_motion, "Kho khoảnh khắc", 15, Colors.orange),
                  _buildButton(Icons.history, "Kỷ niệm năm xưa", 8, Colors.purple),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostInput(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostScreen()),
        ),
        child: AbsorbPointer(
          child: TextField(
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              hintText: "Bạn đang nghĩ gì?",
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 1, height: 24, color: Color(0xffe6e3e3)),
                  SizedBox(width: 10),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PostScreen()),
                    ),
                    child: Icon(Icons.image, color: Colors.lightGreen),
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserPosts(Map<String, dynamic> userData) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: fetchUserPosts(),
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox();
        }
        if (postSnapshot.hasError || postSnapshot.data == null || postSnapshot.data!["posts"] == null || postSnapshot.data!["posts"].isEmpty) {
          return Center(child: Text("Bạn chưa có bài viết nào."));
        }

        List<Map<String, dynamic>> posts = List<Map<String, dynamic>>.from(postSnapshot.data!["posts"]);

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return PostItem(
              post: posts[index],
              avt: userData['AVT'],
              fullName: userData['fullName'],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 27),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.access_time_outlined, color: Colors.white),
            onPressed: () => _openSeeLogBottomSheet(context),
          ),
          IconButton(
            icon: Icon(Icons.more_horiz_outlined, color: Colors.white),
            onPressed: () => print("option"),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, int quantity, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: color, size: 25),
        label: Text(
          quantity > 0 ? "$label $quantity" : label,
          style: TextStyle(color: Colors.black),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}