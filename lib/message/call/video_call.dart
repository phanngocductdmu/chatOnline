import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'hand_detector.dart';
import 'package:camera/camera.dart';


const String appId = "bad34fda816e4c31a4d63a6761c653af";
const String serverUrl = "https://5b4fc1b1-9820-45b6-8387-e1815f06d52f-00-1cd15kud1kxfl.sisko.replit.dev:5000/rtc-token";

class VideoCall extends StatefulWidget {
  final String chatRoomId, idFriend, avt, fullName, userId;

  const VideoCall({super.key, required this.chatRoomId, required this.idFriend, required this.avt, required this.fullName, required this.userId});

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  bool isCameraOn = true;
  bool isMicOn = true;
  bool isSpeakerOn = true;
  RtcEngine? _engine;
  int? _remoteUid;
  String? agoraToken;
  bool isLoading = true;
  bool hasPopped = false;
  Timer? _timer;
  Duration callDuration = Duration();
  DateTime? connectedTime;
  int timeout = 15;
  bool hide = false;
  bool isAISwitchOn = false;
  bool isBlurEnabled = false;
  bool isFrontCamera = false;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();



  late CameraController _cameraController;
  late List<CameraDescription> cameras;
  HandDetector handDetector = HandDetector();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeCall();
    _initializeCamera();
    _initializeCall().then((_) {
      _checkCallStatus();
    });
  }

  void _checkCallStatus() {
    try {
      DatabaseReference callsRef = FirebaseDatabase.instance.ref("calls");
      callsRef
          .orderByChild('channelName')
          .equalTo(widget.chatRoomId)
          .onValue
          .listen((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> calls = event.snapshot.value as Map;
          calls.forEach((key, value) async {
            String status = value['status']
                .toString()
                .toLowerCase();
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

  void _sendMessage(String statusS, String idUser) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final receiverId = await _getReceiverId();
    if (receiverId == null) return;
    final snapshot = await _database.child('users/$receiverId/status/online').get();
    final isReceiverOnline = snapshot.exists && snapshot.value == true;
    final newStatus = isReceiverOnline ? 'Đã nhận' : 'Đã gửi';
    final messageData = {
      'text': 'Cuộc gọi đến',
      'senderId': idUser,
      'timestamp': timestamp,
      'typeChat': "videoCall",
      'status': newStatus,
      'statuss': statusS,
      'totalTime': _formatDurationFirebase(callDuration),
    };
    await _database.child('chats/${widget.chatRoomId}/messages').push().set(messageData);
    await _database.child('chatRooms/${widget.chatRoomId}').update({
      'lastMessage': 'Cuộc gọi đến',
      'lastMessageTime': timestamp,
      'status': newStatus,
      'senderId': widget.userId,
    });
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  String _formatDurationFirebase(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds.remainder(60);
    return "$minutes phút $seconds giây";
  }

  void onUserConnected() {
    setState(() {
      connectedTime = DateTime.now();
      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (connectedTime != null) {
        setState(() {
          callDuration = DateTime.now().difference(connectedTime!);
        });
      }
    });
  }

  Future<String> copyAssetToTemp(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/cuocgoidi.mp3');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
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

  Future<void> _waitForRemoteUser() async {
    while (timeout > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (_remoteUid != null) {
        return;
      }
      timeout--;
    }
    await _updateCallStatusToMissed();
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
    Navigator.pop(context);
  }

  Future<void> _updateCallStatusToMissed() async {
    String channelName = widget.chatRoomId;
    DatabaseReference ref = FirebaseDatabase.instance.ref("calls");

    try {
      DatabaseEvent event = await ref.orderByChild("channelName").equalTo(channelName).once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> calls = event.snapshot.value as Map<dynamic, dynamic>;
        calls.forEach((key, value) async {
          await ref.child(key).update({"status": "missed"});
        });
        print("✅ Cập nhật trạng thái missed thành công.");
      } else {
        print("⚠️ Không tìm thấy cuộc gọi với channelName: $channelName");
      }
    } catch (e) {
      print("🔴 Lỗi cập nhật trạng thái cuộc gọi: $e");
    }
  }

  void endCall() async {
    try {
      DatabaseReference callsRef = FirebaseDatabase.instance.ref("calls");
      DatabaseEvent event = await callsRef.orderByChild('channelName').equalTo(widget.chatRoomId).once();
      if (event.snapshot.exists) {
        for (var child in event.snapshot.children) {
          Map<dynamic, dynamic>? callData = child.value as Map<dynamic, dynamic>?;
          if (callData != null) {
            String myID = callData['myID'] ?? '';
            if (_remoteUid == null) {
              await FirebaseDatabase.instance.ref("calls/${child.key}").update({
                'status': 'missed',
              });
              _sendMessage('missed', myID);
              print("📢 Cuộc gọi bị bỏ lỡ (missed)");
            } else {
              await FirebaseDatabase.instance.ref("calls/${child.key}").update({
                'status': 'ended',
              });
              _sendMessage('ended', myID);
              print("📢 Cuộc gọi đã kết thúc");
            }
          }
        }
      }
      if (_engine != null) {
        await _engine!.stopAudioMixing();
        await _engine!.muteLocalAudioStream(true);
        await _engine!.muteAllRemoteAudioStreams(true);
        await _engine!.leaveChannel();
        await _engine!.release();
      }
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

  void toggleMic() async {
    try {
      bool newMicState = !isMicOn;
      await _engine!.muteLocalAudioStream(!newMicState);
      setState(() {
        isMicOn = newMicState;
      });
      print("🎙 Mic ${isMicOn ? "bật" : "tắt"}");
    } catch (e) {
      print("❌ Lỗi khi bật/tắt mic: $e");
    }
  }

  void frontCamera() async {
    try {
      if (_engine == null) {
        print("⚠️ Lỗi: Agora chưa được khởi tạo!");
        return;
      }
      await _engine!.switchCamera();
      setState(() {
        isFrontCamera = !isFrontCamera;
      });
      print("📷 Camera chuyển sang ${isFrontCamera ? "trước" : "sau"}");
    } catch (e) {
      print("❌ Lỗi khi đổi camera: $e");
    }
  }

  void toggleCamera() async {
    try {
      if (_engine == null) {
        print("⚠️ Lỗi: Agora chưa được khởi tạo!");
        return;
      }
      bool newCameraState = !isCameraOn;
      await _engine!.muteLocalVideoStream(!newCameraState);
      setState(() {
        isCameraOn = newCameraState;
      });
      print("📷 Camera ${isCameraOn ? "BẬT" : "TẮT"}");
    } catch (e) {
      print("❌ Lỗi khi bật/tắt camera: $e");
    }
  }

  Future<void> setBlurBackground() async {
    if (_engine == null) {
      // print("RTC Engine chưa khởi tạo.");
      return;
    }
    await _engine!.enableVideo();
    // Cấu hình làm mờ nền
    final virtualBackgroundSource = VirtualBackgroundSource(
      backgroundSourceType: BackgroundSourceType.backgroundBlur,
      blurDegree: BackgroundBlurDegree.blurDegreeHigh,
    );
    final segmentationProperty = SegmentationProperty(
      modelType: SegModelType.segModelAi,
      greenCapacity: 0.5,
    );
    // Bật tính năng Virtual Background
    try {
      await Future.delayed(Duration(milliseconds: 500));
      await _engine!.enableVirtualBackground(
        enabled: true,
        backgroundSource: virtualBackgroundSource,
        segproperty: segmentationProperty,
      );
      // print("Virtual Background đã được kích hoạt.");
    } catch (e) {
      // print("Lỗi khi bật Virtual Background: $e");
    }
  }

  Future<void> toggleBlurBackground() async {
    if (isBlurEnabled) {
      await _engine?.enableVirtualBackground(
        enabled: false,
        backgroundSource: const VirtualBackgroundSource(
          backgroundSourceType: BackgroundSourceType.backgroundNone,
        ),
        segproperty: const SegmentationProperty(
          modelType: SegModelType.segModelAi,
          greenCapacity: 0.5,
        ),
      );
    } else {
      await setBlurBackground();
    }
    isBlurEnabled = !isBlurEnabled;
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _cameraController = CameraController(cameras[1], ResolutionPreset.medium);
    await _cameraController.initialize();
    _cameraController.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!isAISwitchOn || _isProcessing) return;

    _isProcessing = true;
    try {
      final tempFile = File('/tmp/temp_image.jpg');
      await tempFile.writeAsBytes(image.planes[0].bytes);

      bool isFist = await handDetector.detectHandGesture(tempFile);
      bool shouldExit = handDetector.handleFistGesture(isFist);

      if (shouldExit) {
        endCall();
        print("🚀 Đã thoát khỏi video call!");
      }
    } catch (e) {
      print("Lỗi xử lý ảnh: $e");
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _initializeCall() async {
    setState(() => isLoading = true);
    String channelName = widget.chatRoomId;
    int uid = widget.userId.hashCode;

    try {
      // Lấy token từ server
      agoraToken = await fetchAgoraToken(channelName, uid);
      if (agoraToken == null) throw Exception("Không thể lấy token từ server.");

      // Khởi tạo Agora
      await _initializeAgora(channelName, uid, agoraToken!);
      await Future.delayed(const Duration(seconds: 1));
      await _engine!.enableVideo();
      await _engine!.startPreview();

      print("✅ Cuộc gọi đã khởi tạo thành công");
    } catch (e) {
      print("🔴 Lỗi khi khởi tạo cuộc gọi: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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

      onUserJoined: (connection, remoteUid, elapsed) async {
        if (!mounted) return;
        setState(() {
          onUserConnected();
          _remoteUid = remoteUid;
        });
        await _engine!.stopAudioMixing();
        await _engine!.muteLocalAudioStream(false);
      },

      onUserOffline: (connection, remoteUid, reason) {
        setState(() => _remoteUid = null);
        Navigator.pop(context);
      },

      onAudioMixingStateChanged: (state, reason) {
      },

      onAudioMixingFinished: () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            hide = !hide;
          });
        },
        child: Stack(
          children: [
            _remoteUid != null ? _remoteVideo() : _buildMyVideoFullScreen(),
            if (_remoteUid == null) _buildWaitingOverlay(),
            if (_remoteUid != null) Positioned(top: 30, right: 10, child: _buildMyVideoSmall()),
            if (_remoteUid != null) Positioned(top: 30, left: 10, child: switchAI()),
            if (_remoteUid != null)
              Positioned(
                top: MediaQuery.of(context).size.height / 2 - 50,
                right: 10,
                child: optionVideoCall(),
              ),
            _buildControlPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyVideoFullScreen() {
    if (_engine == null) {
      return const Center(child: SizedBox());
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget switchAI() {
    if (hide) return SizedBox();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.6,
          child: Switch(
            value: isAISwitchOn,
            activeColor: Color(0xFF11998e),
            activeTrackColor: Color(0xFF38ef7d),
            onChanged: (value) {
              setState(() {
                isAISwitchOn = value;
              });
            },
          ),
        ),
        const Text("Tự động tắt (Nắm tay 3 lần)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget optionVideoCall() {
    if (hide) return SizedBox();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isBlurEnabled ? Icons.blur_off : Icons.blur_on,
            color: Colors.white,
          ),
          onPressed: () async {
            await toggleBlurBackground(); // Gọi đúng cách
          },
        ),
        SizedBox(height: 10),
        IconButton(
          icon: Icon(Icons.face_retouching_natural_outlined, color: Colors.white), // Filter
          onPressed: () {
            
          },
        ),
      ],
    );
  }

  Widget _buildMyVideoSmall() {
    return Visibility(
      visible: isCameraOn,
      child: Container(
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
            backgroundColor: Colors.grey[300],
            backgroundImage: widget.avt != null && widget.avt.isNotEmpty
                ? NetworkImage(widget.avt)
                : null,
            child: widget.avt == null || widget.avt.isEmpty
                ? Icon(Icons.person, size: 50, color: Colors.grey[700])
                : null,
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
            if (!hide) _buildControlButton(
              isCameraOn ? Icons.videocam : Icons.videocam_off,
              toggleCamera,
              isCameraOn ? Colors.green : Colors.grey[800] ?? Colors.grey,
            ),
            if (!hide) _buildControlButton(
              isMicOn ? Icons.mic : Icons.mic_off,
              toggleMic,
              isMicOn ? Colors.green : Colors.grey[800] ?? Colors.grey,
            ),
            if (!hide) _buildControlButton(
              Icons.flip_camera_ios,
                frontCamera,
              Colors.green
            ),
            if (!hide) _buildControlButton(Icons.call_end, endCall, Colors.red),
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

  @override
  void dispose() {
    _cameraController.dispose();
    _timer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    _engine = null;
    super.dispose();
  }
}
