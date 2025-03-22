import 'dart:async';
import 'seeMomemts.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatonline/Search/TimKiem.dart';
import 'package:chatonline/User/postNews.dart';
import 'package:chatonline/User/personalPage.dart';
import 'postItem.dart';
import 'package:chatonline/User/createMoments.dart';

class Diary extends StatefulWidget {
  const Diary({super.key});

  @override
  State<Diary> createState() => _DiaryState();
}

class _DiaryState extends State<Diary> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? idDiary;
  List<Map<String, dynamic>> chatRooms = [];
  String? idUser;
  List<String> _friends = [];
  List<Map<String, dynamic>> posts = [];
  Future<Map<String, dynamic>?>? futureUserInfo;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    if (idUser != null) {
      futureUserInfo = fetchUserInfo(idUser!);
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

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getString('userId');
    });
    if (idUser != null) {
      _loadFriends();
    }
  }

  Future<void> _loadFriends() async {
    if (idUser == null) return;

    DatabaseReference friendsRef = _database.child("Friends/$idUser");
    friendsRef.once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> friendsData = Map.from(event.snapshot.value as Map<dynamic, dynamic>);
        List<String> friendIds = friendsData.keys.map((key) => key.toString().trim()).toList();

        setState(() {
          _friends = friendIds;
        });
        print("Danh sách bạn bè đã tải: $_friends");
      }
    }).catchError((e) {
      print("Lỗi khi tải danh sách bạn bè: $e");
    });
  }

  Future<List<Map<String, dynamic>>> getMomentsOnce(String myUserId) async {
    DatabaseReference momentsRef = FirebaseDatabase.instance.ref("Moments");
    DatabaseReference friendsRef = FirebaseDatabase.instance.ref("friends/$myUserId");

    // Lấy danh sách bạn bè
    final friendsSnapshot = await friendsRef.once();
    final friendsData = friendsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};

    Set friendIds = friendsData.keys.toSet();

    // Lấy danh sách Moments
    final momentsSnapshot = await momentsRef.once();
    final momentsData = momentsSnapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (momentsData == null) return [];

    List<Map<String, dynamic>> moments = momentsData.entries.map((entry) {
      return {
        "id": entry.key,
        ...Map<String, dynamic>.from(entry.value),
      };
    }).toList();

    List<Map<String, dynamic>> filteredMoments = moments.where((moment) {
      String userId = moment["idUser"];
      return userId == myUserId || friendIds.contains(userId);
    }).toList();

    List<Map<String, dynamic>> myMoments =
    filteredMoments.where((moment) => moment["idUser"] == myUserId && moment["isMoments"] == true).toList();

    List<Map<String, dynamic>> friendsMoments =
    filteredMoments.where((moment) => moment["idUser"] != myUserId && moment["isMoments"] == true).toList();
    friendsMoments.sort((a, b) => (b["timestamp"] ?? 0).compareTo(a["timestamp"] ?? 0));

    // Ghép danh sách Moments của bạn lên đầu
    return [...myMoments, ...friendsMoments];
  }

  Stream<List<Map<String, dynamic>>> streamPosts() {
    DatabaseReference postsRef = FirebaseDatabase.instance.ref("posts");
    DatabaseReference friendsRef = FirebaseDatabase.instance.ref("friends/$idUser");

    return friendsRef.onValue.asyncExpand((friendsSnapshot) {
      final friendsData = friendsSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      Set friendIds = friendsData.keys.toSet();

      return postsRef.onValue.map((postsSnapshot) {
        final postsData = postsSnapshot.snapshot.value as Map<dynamic, dynamic>?;

        if (postsData == null) return [];

        List<Map<String, dynamic>> posts = postsData.entries.map((entry) {
          return {
            "id": entry.key,
            ...Map<String, dynamic>.from(entry.value),
          };
        }).toList();

        List<Map<String, dynamic>> filteredPosts = posts.where((post) {
          String userId = post["userId"];
          String privacy = post["privacy"] ?? "";

          // Ẩn bài viết có privacy là "Chỉ mình tôi"
          if (privacy == "Chỉ mình tôi") return false;

          return userId == idUser || friendIds.contains(userId);
        }).toList();

        filteredPosts.sort((a, b) => (b["timestamp"] ?? 0).compareTo(a["timestamp"] ?? 0));
        return filteredPosts;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimKiem()),
                  );
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TimKiem()),
                );
              },
              child: Text(
                'Tìm kiếm',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 19,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_note),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => PostScreen()));
                },
              ),
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
            iconTheme: IconThemeData(color: Colors.white),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildPostInput(context),
              const SizedBox(height: 10),
              _buildMoments(context),
              const SizedBox(height: 10),
              _buildPosts(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostInput(BuildContext context) {
    if (idUser == null) {
      return const Center(child: Text("Không có dữ liệu người dùng"));
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PostScreen()),
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: fetchUserInfo(idUser!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: SizedBox());
          }
          var userData = snapshot.data;
          String avatarUrl = userData?['AVT'] ?? '';
          return Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalPage()));
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: avatarUrl.isEmpty
                          ? Icon(Icons.person, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PostScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            "Hôm nay bạn thế nào?",
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          SizedBox(width: 10),
                          Expanded(child: SizedBox()),
                          Text(
                            "|",
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.image,
                            color: Colors.lightGreen,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoments(BuildContext context){
    if (idUser == null) {
      return const Center(child: Text("Không có dữ liệu người dùng"));
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getMomentsOnce(idUser!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SizedBox());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Lỗi tải dữ liệu"));
        }
        var moments = snapshot.data ?? [];
        Set<String> seenUsers = {};
        var filteredMoments = moments.where((moment) {
          if (!moment['isMoments']) return false;
          if (seenUsers.contains(moment['idUser'])) {
            return false;
          } else {
            seenUsers.add(moment['idUser']);
            return true;
          }
        }).toList();
        return SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, ),
                  child: Text(
                    "Khoảnh khắc",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ô New Moment
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateMoments(idUser: idUser!)));
                        },
                        child: Container(
                          width: 90,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add,
                              size: 40,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredMoments.length,
                          itemBuilder: (context, index) {
                            var post = filteredMoments[index];
                            return FutureBuilder<Map<String, dynamic>?>(
                              future: fetchUserInfo(post['idUser']),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    width: 90,
                                    height: 140,
                                    child: Center(child: SizedBox()),
                                  );
                                }

                                var userInfo = userSnapshot.data;
                                String avatarUrl = userInfo?['AVT'] ?? "";
                                String username = userInfo?['fullName'] ?? "Người dùng";

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child:  GestureDetector(
                                    onTap: () {
                                      Map<String, String> avatars = {
                                        for (var moment in moments)
                                          moment['idUser'].toString(): userInfo?['AVT'] ?? "",
                                      };

                                      Map<String, String> names = {
                                        for (var moment in moments)
                                          moment['idUser'].toString(): userInfo?['fullName'] ?? "Người dùng",
                                      };
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SeeMoments(
                                            idUserPerson: post['idUser'],
                                            moments: moments,
                                            idUser: idUser!,
                                            userIds: filteredMoments.map((e) => e['idUser'].toString()).toSet().toList(),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 90,
                                            height: 140,
                                            child: Image.network(
                                              post['url'],
                                              fit: BoxFit.none,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 90,
                                          padding: const EdgeInsets.symmetric(vertical: 5),
                                          decoration: const BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(10),
                                              bottomRight: Radius.circular(10),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.green,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: Colors.white,
                                                    child: CircleAvatar(
                                                      radius: 13,
                                                      backgroundImage: avatarUrl.isNotEmpty
                                                          ? NetworkImage(avatarUrl)
                                                          : null,
                                                      backgroundColor: avatarUrl.isNotEmpty ? Colors.transparent : Colors.grey,
                                                      child: avatarUrl.isNotEmpty
                                                          ? null
                                                          : const Icon(Icons.person, color: Colors.white, size: 16),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                username,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPosts(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: streamPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: SizedBox());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("Không có bài viết nào!"));
        }

        List<Map<String, dynamic>> postsWithImages = snapshot.data!
            .where((post) => post["fileUrl"] != null && post["fileUrl"].isNotEmpty)
            .toList();

        if (postsWithImages.isEmpty) {
          return Center(child: Text("Không có bài viết nào có ảnh!"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: postsWithImages.length,
          itemBuilder: (context, index) {
            var post = postsWithImages[index];
            return PostItem(post: post);
          },
        );
      },
    );
  }
}