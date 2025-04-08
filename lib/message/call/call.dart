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

const String appId = "bad34fda816e4c31a4d63a6761c653af";
const String serverUrl =
    "https://5b4fc1b1-9820-45b6-8387-e1815f06d52f-00-1cd15kud1kxfl.sisko.replit.dev:5000/rtc-token";

class Call extends StatefulWidget {
  final String chatRoomId, idFriend, avt, fullName, userId;

  const Call({
    super.key,
    required this.chatRoomId,
    required this.idFriend,
    required this.avt,
    required this.fullName,
    required this.userId,
  });

  @override
  State<Call> createState() => _CallState();
}

class _CallState extends State<Call> {
  RtcEngine? _engine;
  int? _remoteUid;
  bool isMicOn = true;
  bool isSpeakerOnOn = true;
  String? agoraToken;
  bool isLoading = true;
  Timer? _timer;
  Duration callDuration = Duration();
  DateTime? connectedTime;
  bool hasPopped = false;
  int timeout = 15;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _initializeCall();
    _requestPermissions();
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
      print("🔴 Lỗi khi kiểm tra trạng thái cuộc gọi: $e");
    }
  }

  Future<void> _requestPermissions() async {
    // Chuyển phần này vào phương thức async để sử dụng await
    PermissionStatus permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      // Thông báo lỗi nếu không cấp quyền
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng cấp quyền truy cập microphone")),
      );
      return;
    }
  }

  Future<String?> _getReceiverId() async {
    final snapshot =
        await _database.child('chatRooms/${widget.chatRoomId}/members').get();
    if (snapshot.exists && snapshot.value is Map) {
      return (snapshot.value as Map)
          .keys
          .firstWhere((id) => id != widget.userId, orElse: () => null);
    }
    return null;
  }

  void _sendMessage(String statusS, String idUser) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final receiverId = await _getReceiverId();
    if (receiverId == null) return;
    final snapshot =
        await _database.child('users/$receiverId/status/online').get();
    final isReceiverOnline = snapshot.exists && snapshot.value == true;
    final newStatus = isReceiverOnline ? 'Đã nhận' : 'Đã gửi';
    final messageData = {
      'text': 'Cuộc gọi đến',
      'senderId': idUser,
      'timestamp': timestamp,
      'typeChat': "call",
      'status': newStatus,
      'statuss': statusS,
      'totalTime': _formatDurationFirebase(callDuration),
    };
    await _database
        .child('chats/${widget.chatRoomId}/messages')
        .push()
        .set(messageData);
    await _database.child('chatRooms/${widget.chatRoomId}').update({
      'lastMessage': 'Cuộc gọi đến',
      'lastMessageTime': timestamp,
      'status': newStatus,
      'senderId': idUser,
    });
    setState(() => isLoading = false);
  }

  Future<void> _initializeCall() async {
    String channelName = widget.chatRoomId;
    String userId = widget.userId;
    int uid = userId.hashCode;
    try {
      agoraToken = await fetchAgoraToken(channelName, uid);
      if (agoraToken == null) throw Exception("Không thể lấy token từ server");

      _initializeAgora(channelName, uid, agoraToken!);
      print("✅ Cuộc gọi đã khởi tạo thành công.");
    } catch (e) {
      print("🔴 Lỗi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể lấy token. Vui lòng thử lại sau!")),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<String?> fetchAgoraToken(String channelName, int uid) async {
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "channelName": channelName,
          "uid": uid,
          "role": "publisher",
          "expireTime": 3600
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["token"];
      } else {
        print("🔴 Lỗi lấy token từ server: ${response.body}");
        return null;
      }
    } catch (e) {
      print("🔴 Lỗi kết nối với server: $e");
      return null;
    }
  }

  void _initializeAgora(String channelName, int uid, String token) async {
    _engine = await createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: appId));

    String tempFilePath = await copyAssetToTemp("assets/audio/cuocgoidi.mp3");
    await _engine!.startAudioMixing(
      filePath: tempFilePath,
      loopback:
          false, // ⚠️ Đảm bảo chỉ phát cho người gọi, không phát lại vào mic
      cycle: -1, // 🔄 Lặp vô hạn cho nhạc chuông
    );

    await _engine!.enableAudio();
    await _engine!
        .setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await _engine!.setupLocalVideo(
        const VideoCanvas(uid: 0, renderMode: RenderModeType.renderModeHidden));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined:
            (RtcConnection connection, int remoteUid, int elapsed) async {
          setState(() {
            onUserConnected();
            _remoteUid = remoteUid;
          });
          print("🎉 Người tham gia cuộc gọi: $remoteUid");

          // Kiểm tra nhạc có đang phát không trước khi dừng
          int position = await _engine!.getAudioMixingCurrentPosition();
          if (position > 0) {
            print("🛑 Dừng nhạc chuông");
            await _engine!.stopAudioMixing();
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
          print("🔴 Người tham gia cuộc gọi đã rời đi: $remoteUid");
          if (!hasPopped && mounted) {
            Navigator.pop(context);
            hasPopped = true;
          }
        },
      ),
    );

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );

    print("🔔 Đã tham gia kênh cuộc gọi: $channelName với UID: $uid");
    _waitForRemoteUser();
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
      DatabaseEvent event =
          await ref.orderByChild("channelName").equalTo(channelName).once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> calls =
            event.snapshot.value as Map<dynamic, dynamic>;
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

  Future<String> copyAssetToTemp(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/cuocgoidi.mp3');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
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

  void toggleSpeaker() async {
    try {
      if (_engine == null) {
        print("⚠️ Lỗi: Agora chưa được khởi tạo!");
        return;
      }
      bool newSpeakerState = !isSpeakerOnOn;
      await _engine!.setEnableSpeakerphone(newSpeakerState);
      await _engine!.setDefaultAudioRouteToSpeakerphone(newSpeakerState);

      if (!newSpeakerState) {
        await _engine!.adjustPlaybackSignalVolume(0); // Tắt hẳn âm thanh
      } else {
        await _engine!.adjustPlaybackSignalVolume(100); // Bật lại âm thanh
      }
      setState(() {
        isSpeakerOnOn = newSpeakerState;
        print("🔍 Trạng thái loa: $isSpeakerOnOn");
      });
      print("🔊 Loa ngoài ${isSpeakerOnOn ? "BẬT" : "TẮT"}");
    } catch (e) {
      print("❌ Lỗi khi bật/tắt loa ngoài: $e");
    }
  }

  void checkMissedCall() {
    Future.delayed(Duration(seconds: 30), () async {
      if (_remoteUid == null) {
        await FirebaseDatabase.instance
            .ref("calls")
            .orderByChild('channelName')
            .equalTo(widget.chatRoomId)
            .once()
            .then((DatabaseEvent event) {
          if (event.snapshot.value != null) {
            Map<dynamic, dynamic> calls = event.snapshot.value as Map;
            calls.forEach((key, value) async {
              if (value['status'] == 'Đang gọi...') {
                await FirebaseDatabase.instance
                    .ref("calls/$key")
                    .update({'status': 'missed'});
                if (mounted) Navigator.pop(context);
              }
            });
          }
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
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

  void endCall() async {
    try {
      DatabaseReference callsRef = FirebaseDatabase.instance.ref("calls");
      DatabaseEvent event = await callsRef
          .orderByChild('channelName')
          .equalTo(widget.chatRoomId)
          .once();
      if (event.snapshot.exists) {
        for (var child in event.snapshot.children) {
          Map<dynamic, dynamic>? callData =
              child.value as Map<dynamic, dynamic>?;
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
      print("🔴 Lỗi khi kết thúc cuộc gọi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: endCall,
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildCallUI(),
    );
  }

  Widget _buildCallUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(height: 20),
        Text(
          widget.fullName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _remoteUid == null ? "Đang gọi..." : _formatDuration(callDuration),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSpeakerButton(),
              _buildEndCallButton(),
              _buildMicButton(),
            ],
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildSpeakerButton() {
    return GestureDetector(
      onTap: toggleSpeaker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSpeakerOnOn ? Colors.green : Colors.grey[800],
          boxShadow: [
            if (isSpeakerOnOn)
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 3,
              ),
          ],
        ),
        child: Icon(
          isSpeakerOnOn ? Icons.volume_up : Icons.volume_off,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: endCall,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(Icons.call_end, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: toggleMic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isMicOn ? Colors.green : Colors.grey[800],
          boxShadow: [
            if (isMicOn)
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 3,
              ),
          ],
        ),
        child: Icon(
          isMicOn ? Icons.mic : Icons.mic_off,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
      _engine = null;
    }
    super.dispose();
  }
}
