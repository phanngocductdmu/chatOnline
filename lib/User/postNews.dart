import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  PostScreenState createState() => PostScreenState();
}

class PostScreenState extends State<PostScreen> {
  final TextEditingController _postController = TextEditingController();
  XFile? _selectedMedia;
  final ImagePicker _picker = ImagePicker();
  String _privacy = "Tất cả bạn bè";
  String? idUser;
  String? _mediaType ;

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

  Future<void> _pickMedia(bool isImage) async {
    final pickedFile = isImage
        ? await _picker.pickImage(source: ImageSource.gallery)
        : await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedMedia = pickedFile;
        _mediaType = isImage ? "image" : "video";
      });
    }
  }

  Future<void> _submitPost() async {
    final snackBar = SnackBar(
      content: Row(
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(width: 10),
          Text("Đang đăng bài..."),
        ],
      ),
      duration: Duration(seconds: 3),
    );

    if (mounted) {
      Navigator.pop(context);
    }

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    if (idUser == null) {
      return;
    }

    String? fileUrl;
    if (_selectedMedia != null) {
      fileUrl = await _uploadFile(File(_selectedMedia!.path), _mediaType ?? "image");
    }
    await _savePostData(fileUrl);
    setState(() {
      _postController.clear();
      _selectedMedia = null;
      _mediaType = null;
    });
  }

  Future<void> _savePostData(String? fileUrl) async {
    DatabaseReference postRef = FirebaseDatabase.instance.ref().child("posts").push();
    Map<String, dynamic> postData = {
      "userId": idUser,
      "text": _postController.text,
      "fileUrl": fileUrl ?? "",
      "type": _mediaType ?? "text",
      "privacy": _privacy,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };
    print("Dữ liệu lưu: $postData");

    await postRef.set(postData);
  }

  Future<String?> _uploadFile(File file, String type) async {
    try {
      String extension = type == "image" ? "jpg" : "mp4";
      String fileName = "posts/${DateTime.now().millisecondsSinceEpoch}.$extension";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print("Đang tải $_mediaType: ${progress.toStringAsFixed(2)}%");
      });

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Lỗi tải $_mediaType lên: $e");
      return null;
    }
  }

  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Quyền riêng tư",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(
                    leading: Icon(Icons.public),
                    title: Text("Tất cả bạn bè"),
                    onTap: () {
                      setState(() => _privacy = "Tất cả bạn bè");
                      Navigator.pop(context);
                    },
                  ),
                  Divider(thickness: 1, height: 1, color: Color(0xFFF3F4F6)),
                  ListTile(
                    leading: Icon(Icons.lock),
                    title: Text("Chỉ mình tôi"),
                    onTap: () {
                      setState(() => _privacy = "Chỉ mình tôi");
                      Navigator.pop(context);
                    },
                  ),
                  Divider(thickness: 1, height: 1, color: Color(0xFFF3F4F6)),
                  ListTile(
                    leading: Icon(Icons.people_outline),
                    title: Text("Bạn bè ngoại trừ"),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      setState(() => _privacy = "Bạn bè ngoại trừ");
                      Navigator.pop(context);
                    },
                  ),
                  Divider(thickness: 1, height: 1, color: Color(0xFFF3F4F6)),
                  ListTile(
                    leading: Icon(Icons.group),
                    title: Text("Bạn bè trong nhóm"),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      setState(() => _privacy = "Bạn bè trong nhóm");
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(width: 5),
            GestureDetector(
              onTap: _showPrivacyOptions,
              child: Row(
                children: [
                  Text(_privacy, style: TextStyle(fontSize: 18, color: Colors.black)),
                  Icon(Icons.arrow_drop_down, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _submitPost,
            icon: Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _selectedMedia != null
                  ? SizedBox()
                  : SizedBox(
                width: double.infinity,
                child: Material(
                  elevation: 1,
                  borderRadius: BorderRadius.circular(10),
                  child: TextField(
                    controller: _postController,
                    decoration: InputDecoration(
                      hintText: "Bạn đang nghĩ gì?",
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _pickMedia(true), // Chọn ảnh
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(Icons.image, color: Colors.lightGreen),
                            ),
                          ),
                          InkWell(
                            onTap: () => _pickMedia(false), // Chọn video
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(Icons.videocam, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              if (_selectedMedia != null) ...[
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_selectedMedia!.path),
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedMedia = null);
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 14,
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _postController,
                    decoration: InputDecoration(
                      hintText: "Thêm mô tả cho ảnh...",
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
