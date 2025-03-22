import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const String appId = "bad34fda816e4c31a4d63a6761c653af";
const String serverUrl = "http://192.168.1.11:5000/rtc-token";

class VideoCall extends StatefulWidget {
  final String chatRoomId, idFriend, avt, fullName, userId;

  const VideoCall({super.key, required this.chatRoomId, required this.idFriend, required this.avt, required this.fullName, required this.userId});

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  bool isCameraOn = true;
  bool isMicOn = true;
  RtcEngine? _engine;
  int? _remoteUid;
  String? agoraToken;
  bool isLoading = true;
  bool hasPopped = false;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeCall();
    _initializeCall().then((_) {
      _checkCallStatus();
    });
  }

  void _checkCallStatus() {
    try {
      DatabaseReference callsRef = FirebaseDatabase.instance.ref("calls");
      // Lắng nghe sự thay đổi trong dữ liệu của cuộc gọi
      callsRef
          .orderByChild('channelName')
          .equalTo(widget.chatRoomId)
          .onValue
          .listen((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> calls = event.snapshot.value as Map;
          calls.forEach((key, value) async {
            // Kiểm tra trạng thái cuộc gọi
            String status = value['status']
                .toString()
                .toLowerCase(); // Chuyển về chữ thường
            if (status == 'refuse' && !hasPopped) {
              if (mounted) {
                Navigator.pop(context);
                hasPopped = true;
              }
            }
          });
        }
      });
    } catch (e) {
      // print("🔴 Lỗi khi kiểm tra trạng thái cuộc gọi: $e");
    }
  }

  Future<void> _requestPermissions() async {
    // print("🔵 Requesting permissions");
    var statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera]!.isPermanentlyDenied || statuses[Permission.microphone]!.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<Map<String, String>?> getMyInfo(String userId) async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$userId");
    DatabaseEvent event = await userRef.once();

    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> userData = event.snapshot.value as Map;
      return {
        'fullName': userData['fullName'] ?? 'Unknown',
        'avt': userData['avt'] ?? '',
      };
    } else {
      // print("⚠️ Không tìm thấy thông tin người dùng.");
      return null;
    }
  }

  Future<String?> _getReceiverId() async {
    final snapshot = await _database.child('chatRooms/${widget.chatRoomId}/members').get();
    if (snapshot.exists && snapshot.value is Map) {
      return (snapshot.value as Map).keys.firstWhere((id) => id != widget.userId, orElse: () => null);
    }
    return null;
  }

  void _sendMessage(String statuss) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final receiverId = await _getReceiverId();
    if (receiverId == null) return;

    final snapshot = await _database.child('users/$receiverId/status/online').get();
    final isReceiverOnline = snapshot.exists && snapshot.value == true;
    final newStatus = isReceiverOnline ? 'Đã nhận' : 'Đã gửi';

    // final messageData = {
    //   'text': 'Cuộc gọi đến',
    //   'senderId': widget.userId,
    //   'timestamp': timestamp,
    //   'typeChat': "call",
    //   'status': newStatus,
    //   'statuss': statuss,
    // };
    //
    // await _database.child('chats/${widget.chatRoomId}/messages').push().set(messageData);
    // await _database.child('chatRooms/${widget.chatRoomId}').update({
    //   'lastMessage': 'Cuộc gọi đến',
    //   'lastMessageTime': timestamp,
    //   'status': newStatus,
    //   'senderId': widget.userId,
    // });
    //
    // setState(() => isLoading = false);
  }

  Future<String> copyAssetToTemp(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/cuocgoidi.mp3');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
  }

  Future<void> _initializeCall() async {
    setState(() => isLoading = true);
    String channelName = widget.chatRoomId;
    int uid = widget.userId.hashCode;
    String userId = widget.userId;

    try {
      Map<String, String>? myInfo = await getMyInfo(userId);
      if (myInfo == null) throw Exception("Không tìm thấy thông tin người dùng.");

      String myFullName = myInfo['fullName']!;
      String myavt = myInfo['avt']!;
      agoraToken = await fetchAgoraToken(channelName, uid);
      if (agoraToken == null) throw Exception("Không thể lấy token từ server.");

      await _initializeAgora(channelName, uid, agoraToken!);

      await Future.delayed(const Duration(seconds: 1));
      await _engine!.enableVideo();

      await _engine!.startPreview();

      DatabaseReference callRef = FirebaseDatabase.instance.ref("calls");
      DatabaseEvent event = await callRef.orderByChild('channelName').equalTo(channelName).once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        snapshot.children.forEach((childSnapshot) async {
          var callKey = childSnapshot.key;
          var callData = childSnapshot.value as Map<dynamic, dynamic>;
          String currentStatus = callData['status'];
          // print('Current status: $currentStatus');

          if (currentStatus == 'ended' || currentStatus == 'refuse' || currentStatus == 'missed') {
            await FirebaseDatabase.instance.ref("calls/$callKey").update({
              'status': 'calling',
              'timestamp': ServerValue.timestamp,
              'idFriend': widget.idFriend,
              'myavt': myavt,
              'myID': widget.userId,
              'callerAvatar': widget.avt,
              'myName': myFullName,
              'nameFriend': widget.fullName,
              'typeCall': 'VideoCall',
            });
            // print("📢 Cuộc gọi đã được cập nhật thành 'Đang gọi...'.");
          } else {
            // print("📢 Trạng thái cuộc gọi không thay đổi.");
          }
        });
      } else {
        await FirebaseDatabase.instance.ref("calls").push().set({
          'status': 'calling',
          'channelName': channelName,
          'idFriend': widget.idFriend,
          'nameFriend': widget.fullName,
          'callerAvatar': widget.avt,
          'myName': myFullName,
          'myavt': myavt,
          'myID': widget.userId,
          'timestamp': ServerValue.timestamp,
          'typeCall': 'Call',
        });
        // print("📢 Cuộc gọi đã được ghi vào Firebase");
      }

      // print("✅ Call initialized successfully");
    } catch (e) {
      // // print("🔴 Error initializing call: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text("Không thể kết nối. Vui lòng thử lại sau!"))
      // );
      // if (mounted) Navigator.pop(context);
    } finally {
      setState(() => isLoading = false);
    }
  }


  Future<String?> fetchAgoraToken(String channelName, int uid) async {
    // print("🔵 Fetching Agora token");
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"channelName": channelName, "uid": uid, "role": "publisher", "expireTime": 3600}),
      );
      if (response.statusCode == 200) {
        // print("✅ Agora token received");
        return jsonDecode(response.body)["token"];
      }
    } catch (e) {
      // print("🔴 Error fetching Agora token: $e");
    }
    return null;
  }

  Future<void> _initializeAgora(String channelName, int uid, String token) async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: appId));
    String tempFilePath = await copyAssetToTemp("assets/audio/cuocgoidi.mp3");

    await _engine!.startAudioMixing(
      filePath: tempFilePath,
      loopback: true,
      cycle: 1,
    );

    await _engine!.enableAudio();

    await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);

    await _engine!.setupLocalVideo(const VideoCanvas(uid: 0, renderMode: RenderModeType.renderModeHidden));

    _engine!.registerEventHandler(RtcEngineEventHandler(

      // onError: (ErrorCodeType err, String msg) => print("🔴 Agora Error: $err - $msg"),
      onUserJoined: (connection, remoteUid, elapsed) async {
        setState(() => _remoteUid = remoteUid);
        // print("📞 Người nhận đã vào phòng, dừng nhạc chuông.");

        await _engine!.stopAudioMixing();

        await _engine!.muteLocalAudioStream(false);
      },

      onUserOffline: (connection, remoteUid, reason) {
        // print("🔴 Remote user offline: $remoteUid");

        setState(() => _remoteUid = null);

        endCall();
      },

      onAudioMixingStateChanged: (state, reason) {
        // print("🎵 Trạng thái Audio Mixing: $state, Lý do: $reason");
      },

      onAudioMixingFinished: () {
        // print("🎵 Audio Mixing đã phát xong!");
      },
    ));

    await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions()
    );

    _waitForRemoteUser();
  }

  Future<void> _waitForRemoteUser() async {
    int timeout = 10;
    while (timeout > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (_remoteUid != null) {
        // print("✅ Người nhận đã tham gia, không kết thúc cuộc gọi.");
        return;
      }

      timeout--;
    }
    String tempPath = await copyAssetToTemp("assets/audio/cuocgoiketthuc.mp3");
    if (await File(tempPath).exists()) {
      // print("🔊 Phát âm thanh kết thúc cuộc gọi: $tempPath");
      await _engine!.startAudioMixing(
        filePath: tempPath,
        loopback: true,
        cycle: 1,
      );
      await Future.delayed(const Duration(seconds: 3));
    }
    endCall();
  }

  void endCall() async {
    try {
      DatabaseReference callsRef = FirebaseDatabase.instance.ref("calls");
      DatabaseEvent event = await callsRef.orderByChild('channelName').equalTo(widget.chatRoomId).once();
      if (event.snapshot.exists) {
        for (var child in event.snapshot.children) {
          String callKey = child.key!;
          if (_remoteUid == null) {
            await FirebaseDatabase.instance.ref("calls/$callKey").update({'status': 'missed'});
            _sendMessage('missed');
            // print("📢 Cuộc gọi bị bỏ lỡ (missed)");
          } else {
            await FirebaseDatabase.instance.ref("calls/$callKey").update({'status': 'ended'});
            _sendMessage('ended');
          }
        }
      }
      await _engine?.stopAudioMixing();
      await _engine?.muteLocalAudioStream(true);
      await _engine?.muteAllRemoteAudioStreams(true);
      await _engine?.leaveChannel();
      await _engine?.release();
      setState(() {
        _remoteUid = null;
      });
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // print("🔴 Lỗi khi kết thúc cuộc gọi: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _remoteUid != null ? _remoteVideo() : _buildMyVideoFullScreen(),
          if (_remoteUid == null) _buildWaitingOverlay(),
          if (_remoteUid != null) Positioned(top: 30, right: 10, child: _buildMyVideoSmall()),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildMyVideoFullScreen() {
    if (_engine == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _buildMyVideoSmall() {
    return Container(
      width: 100,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      ),
    );
  }

  Widget _buildWaitingOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(widget.avt),
          ),
          const SizedBox(height: 10),
          Text(
            widget.fullName,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "Đang gọi...",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    return Container(
      color: Colors.black,
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.chatRoomId),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(isCameraOn ? Icons.videocam : Icons.videocam_off, () => setState(() => isCameraOn = !isCameraOn), Colors.green),
            _buildControlButton(Icons.call_end, endCall, Colors.red),
            _buildControlButton(isMicOn ? Icons.mic : Icons.mic_off, () => setState(() => isMicOn = !isMicOn), Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, Color color) {
    return RawMaterialButton(
      onPressed: onPressed,
      shape: const CircleBorder(),
      fillColor: color,
      constraints: const BoxConstraints.tightFor(width: 56, height: 56),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
