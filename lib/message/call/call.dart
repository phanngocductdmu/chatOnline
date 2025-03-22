import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

const String appId = "bad34fda816e4c31a4d63a6761c653af";
const String serverUrl = "http://192.168.1.11:5000/rtc-token";

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
  bool _isMicOn = true;
  bool _isSpeakerOn = false;
  String? agoraToken;
  bool isLoading = true;
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

  bool hasPopped = false;

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

    // final snapshot = await _database.child('users/$receiverId/status/online').get();
    // final isReceiverOnline = snapshot.exists && snapshot.value == true;
    // final newStatus = isReceiverOnline ? 'Đã nhận' : 'Đã gửi';
    //
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
      print("⚠️ Không tìm thấy thông tin người dùng.");
      return null;
    }
  }

  Future<void> _initializeCall() async {
    String channelName = widget.chatRoomId;
    String userId = widget.userId;
    int uid = userId.hashCode;
    try {
      Map<String, String>? myInfo = await getMyInfo(userId);
      if (myInfo == null) throw Exception(
          "Không tìm thấy thông tin người dùng.");
      String myFullName = myInfo['fullName']!;
      String myavt = myInfo['avt']!;

      agoraToken = await fetchAgoraToken(channelName, uid);

      if (agoraToken == null) throw Exception("Không thể lấy token từ server");
      _initializeAgora(channelName, uid, agoraToken!);

      DatabaseReference callRef = FirebaseDatabase.instance.ref("calls");
      DatabaseEvent event = await callRef.orderByChild('channelName').equalTo(
          channelName).once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.exists) {
        snapshot.children.forEach((childSnapshot) async {
          var callKey = childSnapshot.key;
          var callData = childSnapshot.value as Map<dynamic, dynamic>;
          String currentStatus = callData['status'];
          print('Current status: $currentStatus');
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
              'typeCall': 'Call',
            });
            print("📢 Cuộc gọi đã được cập nhật thành 'Đang gọi...'.");
          } else {
            print("📢 Trạng thái cuộc gọi không thay đổi.");
          }
        });
      } else
      {await FirebaseDatabase.instance.ref("calls").push().set({
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
        print("📢 Cuộc gọi đã được ghi vào Firebase");
      }
    } catch (e) {
      print("🔴 Lỗi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể lấy token. Vui lòng thử lại sau!"))
      );
      Navigator.pop(context);
    }
    setState(() {
      isLoading = false;
    });
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

    await _engine!.enableAudio();
    await _engine!.setChannelProfile(
        ChannelProfileType.channelProfileCommunication);

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
          print("🎉 Người tham gia cuộc gọi: $remoteUid");
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
  }

  void toggleMic() {
    setState(() {
      _isMicOn = !_isMicOn;
    });
    _engine!.muteLocalAudioStream(!_isMicOn);
  }

  void toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _engine!.setEnableSpeakerphone(_isSpeakerOn);
  }

  void checkMissedCall() {
    Future.delayed(Duration(seconds: 30), () async {
      if (_remoteUid == null) {
        await FirebaseDatabase.instance.ref("calls").orderByChild('channelName')
            .equalTo(widget.chatRoomId)
            .once()
            .then((DatabaseEvent event) {
          if (event.snapshot.value != null) {
            Map<dynamic, dynamic> calls = event.snapshot.value as Map;
            calls.forEach((key, value) async {
              if (value['status'] == 'Đang gọi...') {
                await FirebaseDatabase.instance.ref("calls/$key").update({'status': 'missed'});
                if (mounted) Navigator.pop(context);
              }
            });
          }
        });
      }
    });
  }


  void endCall() async {
    try {
      DatabaseReference callsRef = FirebaseDatabase.instance.ref("calls");
      DatabaseEvent event = await callsRef.orderByChild('channelName').equalTo(widget.chatRoomId).once();

      if (event.snapshot.exists) {
        for (var child in event.snapshot.children) {
          String callKey = child.key!;
          Map<dynamic, dynamic> callData = child.value as Map;

          if (_remoteUid == null) {
            // 📌 Trường hợp chưa có ai tham gia cuộc gọi -> Missed Call
            await FirebaseDatabase.instance.ref("calls/$callKey").update({
              'status': 'missed',
            });
            _sendMessage('missed');
            print("📢 Cuộc gọi bị bỏ lỡ (missed)");
          } else {
            // 📌 Trường hợp đã tham gia -> Kết thúc cuộc gọi
            await FirebaseDatabase.instance.ref("calls/$callKey").update({
              'status': 'ended',
            });
            _sendMessage('ended');
            print("📢 Cuộc gọi đã kết thúc");
          }
        }
      }

      // Thoát khỏi kênh gọi
      await _engine?.leaveChannel();
      _engine?.release();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print("🔴 Lỗi khi kết thúc cuộc gọi: $e");
    }
  }


  @override
  void dispose() {
    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
    }
    super.dispose();
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
          radius: 80,
          backgroundImage: NetworkImage(widget.avt),
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
          _remoteUid == null ? "Đang gọi..." : "Đã kết nối",
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
          color: _isSpeakerOn ? Colors.green : Colors.grey[800],
          boxShadow: [
            if (_isSpeakerOn)
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 3,
              ),
          ],
        ),
        child: Icon(
          _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
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
          color: _isMicOn ? Colors.green : Colors.grey[800],
          boxShadow: [
            if (_isMicOn)
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 3,
              ),
          ],
        ),
        child: Icon(
          _isMicOn ? Icons.mic : Icons.mic_off,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
