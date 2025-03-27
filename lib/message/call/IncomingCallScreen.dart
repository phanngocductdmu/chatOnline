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
  IncomingCallScreenState createState() => IncomingCallScreenState();
}

class IncomingCallScreenState extends State<IncomingCallScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    _checkCallStatus();
    _playRingtone();
  }

  Future<void> _playRingtone() async {
    try {
      String filePath = await copyAssetToTemp("assets/audio/cuocgoiden.mp3");
      await _audioPlayer.setSourceDeviceFile(filePath);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.resume();
    } catch (e) {
      print("🔴 Lỗi khi phát âm thanh: $e");
    }
  }

  Future<String> copyAssetToTemp(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/cuocgoiden.mp3');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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

              CircleAvatar(
                radius: 50,
                backgroundImage: widget.myAVT != null && widget.myAVT.isNotEmpty
                    ? NetworkImage(widget.myAVT)
                    : (widget.myAVT != null && widget.myAVT.isNotEmpty
                    ? NetworkImage(widget.myAVT)
                    : null),
                backgroundColor: widget.myAVT == null || widget.myAVT.isEmpty ? Colors.grey[300] : null,
                child: (widget.myAVT == null || widget.myAVT.isEmpty) && (widget.myAVT == null || widget.myAVT.isEmpty)
                    ? Icon(Icons.person, size: 50, color: Colors.grey[700])
                    : null,
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
                      if (widget.typeCall == "videoCall") {
                        Navigator.pop(context);
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
                        Navigator.pop(context);
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
