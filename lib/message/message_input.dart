import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:validators/validators.dart';

class MessageInput extends StatefulWidget {
  final String chatRoomId;
  final String senderId;
  final String idFriend;
  final Map<String, dynamic>? selectedReplyMessage;
  final Function()? onClearReply;
  final bool isFriend;

  const MessageInput({super.key, required this.chatRoomId, required this.senderId, required this.selectedReplyMessage, required this.onClearReply, required this.isFriend, required this.idFriend});

  @override
  MessageInputState createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _isTyping = false;
  Timer? _typingTimer;
  List<String> stickers = [];
  bool _isLoadingStickers = true;
  String? fileName;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  Map<String, dynamic>? selectedReplyMessage;

  @override
  void initState() {
    super.initState();
    _updateUserChatStatus(true, widget.chatRoomId);
    _markMessagesAsRead();
    _loadStickers();
  }

  @override
  void dispose() {
    _updateUserChatStatus(false, widget.chatRoomId);
    _setTypingStatus(false);
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _updateUserChatStatus(bool isInChat, String chatRoomId) {
    _database.child('users/${widget.senderId}').update({
      'inChatRoom': isInChat,
      'chatRoomId': isInChat ? chatRoomId : null,
    });
  }

  Future<String?> _getReceiverId() async {
    final snapshot = await _database.child('chatRooms/${widget.chatRoomId}/members').get();
    if (snapshot.exists && snapshot.value is Map) {
      return (snapshot.value as Map).keys.firstWhere((id) => id != widget.senderId, orElse: () => null);
    }
    return null;
  }

  void _sendMessage(String typeChat, String message, String? urlFile, Map<String, dynamic>? replyMessage) async {
    if (message.isEmpty && (urlFile == null || urlFile.isEmpty)) {
      return;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final receiverId = await _getReceiverId();
    if (receiverId == null) {
      return;
    }
    final snapshot = await _database.child('users/$receiverId/status/online').get();
    final isReceiverOnline = snapshot.exists && snapshot.value == true;
    final newStatus = isReceiverOnline ? 'Đã nhận' : 'Đã gửi';
    bool isLink = isValidURL(message);
    String displayMessage = _getDisplayMessage(typeChat, message, isLink);
    final messageData = {
      'text': message,
      'senderId': widget.senderId,
      'timestamp': timestamp,
      'typeChat': isLink ? 'link' : typeChat,
      'status': newStatus,
      'urlFile': urlFile,
    };
    if (replyMessage != null && replyMessage['id'] != null && replyMessage['id'] is String) {
      messageData['replyTo'] = replyMessage['id'];
      messageData['replyText'] = replyMessage['text'] ?? 'Không có tin nhắn';
    } else {

    }
    await _database.child('chats/${widget.chatRoomId}/messages').push().set(messageData);
    _sendLastMessege(displayMessage, timestamp, newStatus);
    setState(() {
      _isTyping = false;
      selectedReplyMessage = null;
    });
    _setTypingStatus(false);
  }

  String _getDisplayMessage(String typeChat, String message, bool isLink) {
    if (isLink || typeChat == 'text') return message;

    Map<String, String> typeLabels = {
      'sticker': '[Nhãn dán]',
      'audio': '[Ghi âm]',
      'image': '[Hình ảnh]',
      'video': '[Video]',
      'word': '[Word]',
      'ppt': '[PowerPoint]',
      'excel': '[Excel]',
      'pdf': '[Pdf]'
    };

    return typeLabels[typeChat] ?? message;
  }

  bool isValidURL(String text) {
    return isURL(text);
  }

  void _sendLastMessege(String message, final timestamp, String newStatus ) async{
    if (message.isEmpty) return;
    await _database.child('chatRooms/${widget.chatRoomId}').update({
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'status': newStatus,
      'senderId': widget.senderId,
    });
  }

  void _markMessagesAsRead() {
    if(widget.isFriend){
      final messagesRef = _database.child('chats/${widget.chatRoomId}/messages');
      messagesRef.onChildAdded.listen((event) {
        if (event.snapshot.exists && event.snapshot.value is Map) {
          final messageData = event.snapshot.value as Map;
          if (messageData['senderId'] != widget.senderId && (messageData['status'] == 'Đã gửi' || messageData['status'] == 'Đã nhận')) {
            messagesRef.child(event.snapshot.key!).update({'status': 'Đã xem'});
          }
        }
      });
      _database.child('chatRooms/${widget.chatRoomId}').update({'status': 'Đã xem'});
    }
  }

  void _setTypingStatus(bool isTyping) {
    _database.child('typingStatus/${widget.chatRoomId}/${widget.senderId}').set(isTyping);
  }

  void _onTextChanged(String text) {
    if (text.trim().isNotEmpty) {
      if (!_isTyping) {
        setState(() => _isTyping = true);
        _setTypingStatus(true);
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        setState(() => _isTyping = false);
        _setTypingStatus(false);
      });
    } else {
      setState(() => _isTyping = false);
      _setTypingStatus(false);
      _typingTimer?.cancel();
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('image/$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);

      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return '';
    }
  }

  Future<String> _uploadVideo(File videoFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('videos/$fileName.mp4');
      UploadTask uploadTask = ref.putFile(videoFile);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return '';
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickMedia();

    if (file == null) return;

    File selectedFile = File(file.path);
    String extension = file.path.split('.').last.toLowerCase();
    String fileType = _getFileType(".$extension");

    if(fileType == 'image'){
      String fileUrl = await _uploadImage(selectedFile);
      if (fileUrl.isNotEmpty) {
        _sendMessage('image', "file", fileUrl, null);
      }

    }else{
      String fileUrl = await _uploadVideo(selectedFile);
      if(fileUrl.isNotEmpty){
        _sendMessage('video', "file", fileUrl, null);
      }
    }
  }

  void _showBottomSheetImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Chọn hành động",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Chụp ảnh"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Chọn từ thư viện"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _loadStickers() async {
    await _fetchStickers();
    setState(() {
      _isLoadingStickers = false;
    });
  }

  void _showBottomSheetSticker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sticker",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildStickerGrid()),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchStickers() async {
    try {
      final storageRef = FirebaseStorage.instance.ref('sticker/EmoticonsSticker');
      final result = await storageRef.listAll();

      for (var item in result.items) {
        item.getDownloadURL().then((url) {
          setState(() {
            stickers.add(url);
          });
        });
      }
    } catch (error) {
      //print('Lỗi khi lấy sticker: $error');
    } finally {
      setState(() {
        _isLoadingStickers = false;
      });
    }
  }


  Future<void> pickFile() async {
    if (await Permission.storage.request().isGranted ||
        await Permission.mediaLibrary.request().isGranted) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        String extension = fileName.split('.').last.toLowerCase();
        extension = ".$extension";
        String fileType = _getFileType(extension);
        if (fileType == "unsupported") {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Loại file không được hỗ trợ!"))
          );
          return;
        }
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });
        String fileUrl = await uploadFileToFirebase(file, fileName);
        setState(() {
          _isUploading = false;
        });
        _sendMessage(fileType, fileName, fileUrl, null);
      } else {
      }
    } else {
    }
  }

  String _getFileType(String extension) {
    switch (extension) {
      case ".jpg":
      case ".jpeg":
      case ".png":
      case ".gif":
        return "image";
      case ".mp4":
      case ".avi":
      case ".mov":
      case ".mkv":
        return "video";
      case ".mp3":
      case ".wav":
      case ".aac":
      case ".ogg":
        return "audio";
      case ".pdf":
        return "pdf";
      case ".doc":
      case ".docx":
        return "word";
      case ".xls":
      case ".xlsx":
        return "excel";
      case ".ppt":
      case ".pptx":
        return "ppt";
      case ".txt":
        return "text";
      default:
        return "unsupported";
    }
  }

  Future<String> uploadFileToFirebase(File file, String fileName) async {
    try {
      Reference storageRef = FirebaseStorage.instance.ref().child("file/$fileName");
      UploadTask uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
      });

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return "";
    }
  }

  void _showBottomSheetRecord(BuildContext context) {
    final AudioRecorder recorder = AudioRecorder();
    final AudioPlayer audioPlayer = AudioPlayer();
    final FirebaseStorage _storage = FirebaseStorage.instance;

    String? _filePath;
    bool _isRecording = false;
    Duration _recordDuration = Duration.zero;
    Timer? _timer;

    Future<bool> _checkPermission() async {
      if (!await recorder.hasPermission()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng cấp quyền ghi âm để sử dụng tính năng này")),
        );
        return false;
      }
      return true;
    }

    Future<void> startRecording(Function setState) async {
      if (!await _checkPermission()) return;

      final dir = await getApplicationDocumentsDirectory();
      _filePath = '${dir.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await recorder.start(const RecordConfig(), path: _filePath!);

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordDuration += const Duration(seconds: 1));
      });
    }

    Future<void> stopRecording(Function setState) async {
      _filePath = await recorder.stop();

      setState(() {
        _isRecording = false;
      });
      _timer?.cancel();
    }

    Future<void> playRecording() async {
      if (_filePath != null) await audioPlayer.play(DeviceFileSource(_filePath!));
    }

    Future<void> uploadToFirebase(BuildContext context) async {
      if (_filePath == null) return;
      try {
        final file = File(_filePath!);
        final fileName = "audio_${DateTime.now().millisecondsSinceEpoch}.m4a";
        final uploadTask = await _storage.ref('audio/$fileName').putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
         _sendMessage('audio', 'ghi âm', downloadUrl, null);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gửi thành công!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi tải lên: \$e")),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String formattedTime =
                "${_recordDuration.inMinutes}:${_recordDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}";

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text("Ghi âm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  // Nút ghi âm
                  GestureDetector(
                    onLongPress: () => startRecording(setState),
                    onLongPressUp: () => stopRecording(setState),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? Colors.redAccent : Colors.blueAccent,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Hiển thị thời gian ghi âm
                  Text(
                    formattedTime,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                  ),

                  const SizedBox(height: 32),

                  // Nút nghe lại & gửi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow, size: 32),
                        onPressed: _filePath != null ? playRecording : null,
                        color: _filePath != null ? Colors.green : Colors.grey,
                      ),
                      ElevatedButton.icon(
                        onPressed: _filePath != null ? () => uploadToFirebase(context) : null,
                        icon: const Icon(Icons.send),
                        label: const Text("Gửi"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          backgroundColor: _filePath != null ? Colors.blueAccent : Colors.grey,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isUploading) _buildUploadProgress(),
        _buildReplyMessage(),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      children: [
        LinearProgressIndicator(value: _uploadProgress),
        const SizedBox(height: 10),
        Text("Đang tải lên... ${(_uploadProgress * 100).toStringAsFixed(0)}%"),
      ],
    );
  }

  Widget _buildReplyMessage() {
    if (widget.selectedReplyMessage == null) return SizedBox();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.reply, color: Colors.green, size: 16),
          SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Trả lời: ",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: widget.selectedReplyMessage?['text'] ?? '[Không có nội dung]',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16), // 🔹 Thu nhỏ nút xóa
            onPressed: () {
              widget.onClearReply?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(5.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.emoji_emotions_outlined), onPressed: () => _showBottomSheetSticker(context)),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Tin nhắn', border: InputBorder.none),
              onChanged: _onTextChanged,
            ),
          ),
          const SizedBox(width: 8),
          _isTyping ? _buildSendButton() : _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return IconButton(
      icon: const Icon(Icons.send),
      onPressed: () {
        if (_controller.text.trim().isNotEmpty) {
          final reply = widget.selectedReplyMessage;
          _sendMessage("text", _controller.text.trim(), '', reply);
          _controller.clear();
          widget.onClearReply?.call();
          setState(() => selectedReplyMessage = null);
        }
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.attach_file), onPressed: pickFile),
        IconButton(icon: const Icon(Icons.mic_none_outlined), onPressed: () => _showBottomSheetRecord(context)),
        IconButton(icon: const Icon(Icons.image), onPressed: () => _showBottomSheetImage(context)),
      ],
    );
  }

  Widget _buildStickerGrid() {
    if (_isLoadingStickers) {
      return const Center(child: CircularProgressIndicator());
    } else if (stickers.isEmpty) {
      return const Center(child: Text("Không có sticker nào"));
    }
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: _isLoadingStickers ? stickers.length + 1 : stickers.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _sendMessage('sticker', '', stickers[index].toString(), null);
            Navigator.pop(context);
          },
          child: Image.network(stickers[index], fit: BoxFit.contain),
        );
      },
    );
  }
}