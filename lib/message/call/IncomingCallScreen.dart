import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chatonline/message/call/call.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chatonline/message/call/video_call.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callKey;
  final String idFriend;
  final String nameFriend;
  final String callerAVT;
  final String channelId;
  final String myName;
  final String myAVT;
  final String myID;
  final String status;
  final String typeCall;

  const IncomingCallScreen({
    super.key,
    required this.callKey,
    required this.idFriend,
    required this.nameFriend,
    required this.callerAVT,
    required this.channelId,
    required this.myName,
    required this.myAVT,
    required this.myID,
    required this.status,
    required this.typeCall,
  });

  @override
  _IncomingCallScreenState createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    _checkCallStatus();
    _playRingtone();
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setSource(AssetSource("audio/cuocgoiden.mp3"));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.resume(); // Bắt đầu phát
    } catch (e) {
      print("🔴 Lỗi khi phát âm thanh: $e");
    }
  }


  bool hasPopped = false;
  void _checkCallStatus() {
    try {
      DatabaseReference callsRef = FirebaseDatabase.instance.ref("calls/${widget.callKey}");
      callsRef.onValue.listen((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> callData = event.snapshot.value as Map;
          if (callData['status'] == 'refuse' && !hasPopped || callData['status'] == 'ended' && !hasPopped || callData['status'] == 'missed' && !hasPopped) {
            if (mounted) {
              Navigator.pop(context);
              hasPopped = true;
              _audioPlayer.stop();
            }
          }
        }
      });
    } catch (e) {
      print("🔴 Lỗi khi kiểm tra trạng thái cuộc gọi: $e");
    }
  }

  Future<String> copyAssetToTemp(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/cuocgoidi.mp3');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ảnh nền là avatar của người gọi
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.network(
                widget.myAVT,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Avatar người gọi
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(widget.myAVT),
              ),
              const SizedBox(height: 20),
              // Tên người gọi
              Text(
                widget.myName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Cuộc gọi đến...",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nút từ chối cuộc gọi
                  GestureDetector(
                    onTap: () async {
                      try {
                        DatabaseReference callsRef = FirebaseDatabase.instance.ref("calls");
                        DatabaseEvent event = await callsRef.once();
                        if (event.snapshot.value != null) {
                          Map<dynamic, dynamic> calls = event.snapshot.value as Map;
                          calls.forEach((key, value) async {
                            if (value['channelName'] == widget.channelId) {
                              await FirebaseDatabase.instance.ref("calls").child(key).update({
                                'status': 'refuse',
                                'timestamp': ServerValue.timestamp,
                              });
                              //Navigator.pop(context);
                            }
                          });
                        }
                      } catch (e) {
                        // print("🔴 Lỗi khi từ chối cuộc gọi: $e");
                      }
                    },
                    child: Column(
                      children: const [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.call_end, color: Colors.white, size: 30),
                        ),
                        SizedBox(height: 10),
                        Text("Từ chối", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  // Nút nhận cuộc gọi
                  GestureDetector(
                    onTap: () {
                      _audioPlayer.stop();
                      if (widget.typeCall == "VideoCall") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCall(
                              chatRoomId: widget.channelId,
                              idFriend: widget.idFriend,
                              avt: widget.myAVT,
                              fullName: widget.myName,
                              userId: widget.idFriend,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Call(
                              chatRoomId: widget.channelId,
                              idFriend: widget.idFriend,
                              avt: widget.myAVT,
                              fullName: widget.myName,
                              userId: widget.idFriend,
                            ),
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: const [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green,
                          child: Icon(Icons.call, color: Colors.white, size: 30),
                        ),
                        SizedBox(height: 10),
                        Text("Chấp nhận", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}
