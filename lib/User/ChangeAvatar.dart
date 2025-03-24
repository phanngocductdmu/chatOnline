import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scribble/scribble.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart' as cropper;
import 'dart:ui' as ui;

class ChangeAvatar extends StatefulWidget {
  final String idUser;

  const ChangeAvatar({super.key, required this.idUser});
  @override
  ChangeAvatarState createState() => ChangeAvatarState();
}

class ChangeAvatarState extends State<ChangeAvatar> {
  final ImagePicker _picker = ImagePicker();
  List<AssetEntity> _galleryImages = [];
  File? _selectedImage;
  final ScribbleNotifier _scribbleNotifier = ScribbleNotifier();
  bool showTextField = false;
  TextEditingController textController = TextEditingController();
  List<Uint8List?> cachedThumbnails = [];
  bool showOptions = true;
  final GlobalKey _globalKey = GlobalKey();
  StreamSubscription? _subscription;
  bool locationTrackingEnabled = false;
  bool dataSharingEnabled = false;
  String privacy = "Tất cả bạn bè";
  IconData selectedIcon = Icons.public;
  bool _hideUI = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
    await Permission.photos.request();
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      List<AssetPathEntity> albums =
      await PhotoManager.getAssetPathList(type: RequestType.image);
      if (albums.isNotEmpty) {
        List<AssetEntity> images =
        await albums.first.getAssetListPaged(page: 0, size: 100);
        setState(() {
          _galleryImages = images;
        });
      }
    }
  }

  Future<void> _captureImage() async {
    final XFile? imageFile = await _picker.pickImage(source: ImageSource.camera);
    if (imageFile != null) {
      _selectNewImage(File(imageFile.path));
    }
  }

  Future<void> _cropImage() async {
    if (_selectedImage == null) return;
    try {
      final croppedFile = await cropper.ImageCropper().cropImage(
        sourcePath: _selectedImage!.path,
        aspectRatio: const cropper.CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
        uiSettings: [
          cropper.AndroidUiSettings(
            toolbarTitle: 'Cắt ảnh',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            aspectRatioPresets: [
              cropper.CropAspectRatioPreset.ratio16x9,
            ],
          ),
          cropper.IOSUiSettings(
            title: 'Cắt ảnh',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        _selectNewImage(File(croppedFile.path));
      }
    } catch (e) {
      debugPrint("Lỗi khi cắt ảnh: $e");
    }
  }

  Widget _galleryView() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _galleryImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _galleryImages.length) {
            return GestureDetector(
              onTap: _captureImage,
              child: Container(
                width: 80,
                height: 80,
                margin: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 40),
              ),
            );
          }
          if (cachedThumbnails.length <= index) {
            cachedThumbnails.add(null);
            _galleryImages[index].thumbnailData.then((data) {
              if (mounted) {
                setState(() {
                  cachedThumbnails[index] = data;
                });
              }
            });
          }
          return GestureDetector(
            onTap: () async {
              File? file = await _galleryImages[index].file;
              if (file != null) {
                _selectNewImage(file);
                _cropImage();
              }
            },
            child: Padding(
              padding: EdgeInsets.all(5),
              child: cachedThumbnails[index] != null
                  ? Image.memory(cachedThumbnails[index]!,
                  width: 80, height: 80, fit: BoxFit.cover)
                  : SizedBox(),
            ),
          );
        },
      ),
    );
  }

  Widget _imagePreview() {
    return RepaintBoundary(
      key: _globalKey,
      child: Stack(
        children: [
          if (_selectedImage != null)
            Positioned.fill(
              child: Image.file(
                _selectedImage!,
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),

          if (_selectedImage != null && !_hideUI)
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[400],
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _selectNewImage(File newImage) {
    setState(() {
      _selectedImage = newImage;
      _scribbleNotifier.clear();
      showTextField = false;
    });
  }

  Future<Uint8List> _captureWidgetImage() async {
    try {
      setState(() {
        _hideUI = true;
      });

      await Future.delayed(Duration(milliseconds: 200));

      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      setState(() {
        _hideUI = false;
      });

      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('Lỗi khi chụp ảnh: $e');
      setState(() {
        _hideUI = false;
      });
      rethrow;
    }
  }

  Future<void> _uploadImage() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang tải lên...'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );

      Uint8List imageBytes = await _captureWidgetImage();
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.png';

      // 1. Upload ảnh lên Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child('avatars/${widget.idUser}/$fileName');
      UploadTask uploadTask = storageRef.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Đăng bài trong `posts`
      DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('posts');
      DatabaseReference newMomentRef = dbRef.push();
      int timestamp = DateTime.now().millisecondsSinceEpoch;

      await newMomentRef.set({
        "userId": widget.idUser,
        "fileUrl": downloadUrl,
        "timestamp": timestamp,
        "privacy": privacy,
        "type": "avatar"
      });

      // 3. Cập nhật avatar trong `users`
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users/${widget.idUser}');
      await userRef.update({"AVT": downloadUrl});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📷 Cập nhật ảnh đại diện thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Lỗi khi upload ảnh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Đăng bài hoặc cập nhật ảnh đại diện thất bại!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          showOptions = false;
        });
        FocusScope.of(context).unfocus();
      },

      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text("Thay đổi ảnh đại diện", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            if (_selectedImage != null )
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.crop, size: 25, color: Colors.white),
                      onPressed: _cropImage,
                    ),
                  ],
                ),
              ),
            SizedBox(width: 10),
            if (_selectedImage != null)
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  _uploadImage();
                },
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (_selectedImage != null)
                    _imagePreview()
                  else
                    Center(
                      child: Text(
                        "Chọn hoặc chụp ảnh để tiếp tục",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            _galleryView(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}