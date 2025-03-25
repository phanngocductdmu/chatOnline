import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'editInformation.dart';

class Information extends StatefulWidget {
  final String idUser;
  final Map<String, dynamic> userData;

  const Information({super.key, required this.idUser, required this.userData});

  @override
  State<Information> createState() => _InformationState();
}

class _InformationState extends State<Information> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? userData;
  TextEditingController nameController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() {
    _database.child('users').child(widget.idUser).onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          userData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  Stream<Map<String, dynamic>> getImageCover(String userId) {
    return FirebaseDatabase.instance
        .ref()
        .child('posts')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return {};
      }

      Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;

      // Lọc danh sách các bài đăng có type = "imageCover"
      var imageCovers = data.entries
          .where((entry) => entry.value['type'] == 'imageCover')
          .toList();

      if (imageCovers.isEmpty) {
        return {};
      }

      // Sắp xếp theo timestamp giảm dần (mới nhất lên đầu)
      imageCovers.sort((a, b) => b.value['timestamp'].compareTo(a.value['timestamp']));

      // Lấy ảnh mới nhất
      var latestCover = imageCovers.first;

      Map<String, dynamic> coverData = Map<String, dynamic>.from(latestCover.value);
      coverData['key'] = latestCover.key;
      return coverData;
    });
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: getImageCover(widget.idUser),
      builder: (context, snapshot) {
        String? coverImageUrl;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          coverImageUrl = snapshot.data!['fileUrl'];
        }

        return Scaffold(
          backgroundColor: Color(0xFFF5F6F8),
          body: userData == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
            children: [
              // Ảnh bìa
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: (coverImageUrl == null || coverImageUrl.isEmpty)
                        ? Colors.grey
                        : null, // Nếu có ảnh thì không cần màu nền
                    image: (coverImageUrl != null && coverImageUrl.isNotEmpty)
                        ? DecorationImage(
                      image: NetworkImage(coverImageUrl),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                ),
              ),
              // AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: kToolbarHeight + 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: AppBar(
                    leading: IconButton(
                      icon: Icon(Icons.chevron_left, color: Colors.white, size: 27),
                      onPressed: () => Navigator.pop(context),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                ),
              ),
              // Nội dung chính
              Column(
                children: [
                  const SizedBox(height: 170),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: (userData!['AVT'] != null &&
                                    userData!['AVT'].toString().isNotEmpty)
                                    ? NetworkImage(userData!['AVT'])
                                    : null,
                                child: (userData!['AVT'] == null ||
                                    userData!['AVT'].toString().isEmpty)
                                    ? Icon(Icons.person, size: 30, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              widget.userData!['fullName'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Thông tin cá nhân",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(Icons.person, "Giới tính",
                              widget.userData!['gender'] ?? "Người dùng chưa cập nhật"),
                          _divider(),
                          _buildInfoRow(Icons.cake, "Ngày sinh",
                              widget.userData!['namSinh'] ?? "Người dùng chưa cập nhật"),
                          _divider(),
                          _buildInfoRow(Icons.email, "Email",
                              widget.userData['email'] ?? "Người dùng chưa cập nhật"),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity, // Full chiều ngang
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) => EditInformation(idUser: widget.idUser, userData: widget.userData),));
                              },
                              icon: Icon(Icons.edit, color: Colors.black),
                              label: Text(
                                "Chỉnh sửa",
                                style: TextStyle(fontSize: 16, color: Colors.black), // Màu chữ đen
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFE0DDDD), // Màu nền xám
                                padding: EdgeInsets.symmetric(vertical: 0), // Tăng chiều cao nút
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black, size: 24),
              const SizedBox(width: 10),
              Text(
                "$title:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      thickness: 1,
      height: 15,
      color: Color(0xFFF3F4F6),
    );
  }
}
