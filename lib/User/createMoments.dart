import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scribble/scribble.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart' as cropper;
import 'dart:ui' as ui;


class CreateMoments extends StatefulWidget {
  final String idUser;

  const CreateMoments({super.key, required this.idUser});
  @override
  CreateMomentsState createState() => CreateMomentsState();
}

class CreateMomentsState extends State<CreateMoments> {
  final ImagePicker _picker = ImagePicker();
  bool _isDrawing = false;
  List<AssetEntity> _galleryImages = [];
  File? _selectedImage;
  final ScribbleNotifier _scribbleNotifier = ScribbleNotifier();
  bool _showTextField = false;
  TextEditingController textController = TextEditingController();
  Color _selectedColor = Colors.white;
  double _textFieldX = 50;
  double _textFieldY = 100;
  List<Uint8List?> cachedThumbnails = [];
  bool _showOptions = true;
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

  void _showPrivacySettings(BuildContext context) {
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
                      privacy = "Tất cả bạn bè";
                      selectedIcon = Icons.public;
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
                      privacy = "Một số bạn bè";
                      selectedIcon = Icons.people_alt;
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
                      privacy = "Bạn bè ngoại trừ";
                      selectedIcon = Icons.person_off_outlined; // Cập nhật icon
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
        compressQuality: 100,
        uiSettings: [
          cropper.AndroidUiSettings(
            toolbarTitle: 'Cắt ảnh',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          cropper.IOSUiSettings(
            title: 'Cắt ảnh',
            aspectRatioLockEnabled: false,
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

          if (_isDrawing)
            Positioned.fill(
              child: ClipRect(
                child: Scribble(
                  notifier: _scribbleNotifier,
                ),
              ),
            ),

          if (_showTextField) // Ẩn khi chụp ảnh
            Positioned(
              left: _textFieldX,
              top: _textFieldY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _textFieldX += details.delta.dx;
                    _textFieldY += details.delta.dy;
                  });
                },
                child: Container(
                  constraints: BoxConstraints(minWidth: 10, maxWidth: 300),
                  padding: EdgeInsets.all(5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: TextField(
                          controller: textController,
                          cursorColor: Colors.white,
                          style: TextStyle(
                            color: _selectedColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Nhập văn bản...",
                            hintStyle: TextStyle(color: _selectedColor),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          onTap: () {
                            setState(() {
                              _showOptions = true;
                            });
                          },
                        ),
                      ),
                      if (_showOptions && !_hideUI)
                        GestureDetector(
                          onTap: _showColorPicker,
                          child: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.color_lens, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      if (_showOptions && !_hideUI) // Ẩn khi chụp ảnh
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showTextField = false;
                              textController.clear();
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Nút xóa ảnh (Ẩn khi chụp)
          if (_selectedImage != null && !_hideUI)
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                    _isDrawing = false;
                    _showTextField = false;
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

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Chọn màu"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text("Đóng"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _selectNewImage(File newImage) {
    setState(() {
      _selectedImage = newImage;
      _isDrawing = false;
      _scribbleNotifier.clear();
      _showTextField = false;
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
      Reference storageRef = FirebaseStorage.instance.ref().child('Moments/$fileName');
      UploadTask uploadTask = storageRef.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('Moments');
      DatabaseReference newMomentRef = dbRef.push();

      int timestamp = DateTime.now().millisecondsSinceEpoch;
      int expiresAt = timestamp + 24 * 60 * 60 * 1000;

      await newMomentRef.set({
        "idUser": widget.idUser,
        "url": downloadUrl,
        "timestamp": timestamp,
        "expiresAt": expiresAt,
        "privacy": privacy,
        "isMoments": true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📷 Đăng bài thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Lỗi khi upload ảnh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Đăng bài thất bại!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> downloadImage() async {
    try {
      setState(() {
        _hideUI = true;
      });

      await Future.delayed(Duration(milliseconds: 100));
      Uint8List imageBytes = await _captureWidgetImage();

      setState(() {
        _hideUI = false;
      });

      String fileName = "${DateTime.now().millisecondsSinceEpoch}.png";
      Directory downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      File file = File("${downloadDir.path}/$fileName");
      await file.writeAsBytes(imageBytes);
      _scanFile(file.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tải xuống thành công")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải xuống: $e")),
      );
    }
  }

  void _scanFile(String path) {
    final platform = MethodChannel('com.example.app/scanFile');
    platform.invokeMethod('scanFile', {'path': path});
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
          _showOptions = false;
        });
        FocusScope.of(context).unfocus();
      },

      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text("Tạo khoảnh khắc", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
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
            if (_selectedImage != null )
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.text_fields, size: 30, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showTextField = true;
                          _showOptions = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.crop, size: 30, color: Colors.white),
                      onPressed: _cropImage,
                    ),
                    IconButton(
                      icon: Icon(Icons.brush, size: 30, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isDrawing = !_isDrawing;
                        });
                      },
                    ),
                  ],
                ),
              ),
            _galleryView(),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      _showPrivacySettings(context);
                    },
                    icon: Icon(selectedIcon, color: Colors.white),
                  ),
                  FloatingActionButton(
                    onPressed: _captureImage,
                    backgroundColor: Colors.white,
                    shape: CircleBorder(),
                    child: Icon(Icons.camera_alt_outlined, color: Colors.black),
                  ),

                  IconButton(
                    onPressed: () async {
                      downloadImage();
                    },
                    icon: Icon(Icons.download, color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}