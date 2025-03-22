import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_database/firebase_database.dart';

class FullScreenVideoView extends StatefulWidget {
  final String senderID, videoUrl;
  final int time;

  const FullScreenVideoView({
    Key? key,
    required this.senderID,
    required this.time,
    required this.videoUrl,
  }) : super(key: key);

  @override
  _FullScreenVideoViewState createState() => _FullScreenVideoViewState();
}

class _FullScreenVideoViewState extends State<FullScreenVideoView> {
  late VideoPlayerController _controller;
  String senderName = "Đang tải...";
  String senderAvatar = "";
  String formattedTime = "Đang tải...";
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });

    fetchSenderInfo();
    formatTime();
  }

  /// Lấy thông tin người gửi từ Firebase
  Future<void> fetchSenderInfo() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("users/${widget.senderID}");
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists && snapshot.value is Map) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          senderName = userData["fullName"] ?? "Không có tên";
          senderAvatar = userData["AVT"] ?? "";
        });
      } else {
        setState(() {
          senderName = "Không tìm thấy người gửi";
        });
      }
    } catch (e) {
      setState(() {
        senderName = "Lỗi tải dữ liệu";
      });
    }
  }

  /// Định dạng thời gian theo múi giờ Việt Nam
  void formatTime() {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(widget.time, isUtc: true)
        .add(const Duration(hours: 7)); // Chuyển sang giờ VN
    setState(() {
      formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    });
  }

  /// Play/Pause video
  void togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        isPlaying = false;
      } else {
        _controller.play();
        isPlaying = true;
      }
    });
  }

  /// Tua tiến 10 giây
  void forward10Seconds() {
    final position = _controller.value.position + const Duration(seconds: 10);
    _controller.seekTo(position);
  }

  /// Tua lùi 10 giây
  void rewind10Seconds() {
    final position = _controller.value.position - const Duration(seconds: 10);
    _controller.seekTo(position);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            senderAvatar.isNotEmpty
                ? CircleAvatar(
              backgroundImage: NetworkImage(senderAvatar),
            )
                : const CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    formattedTime,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Video Player
          Expanded(
            child: Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : const CircularProgressIndicator(),
            ),
          ),

          // Thanh tiến trình + thời gian
          _controller.value.isInitialized
              ? Column(
            children: [
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.blue,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_controller.value.position),
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      _formatDuration(_controller.value.duration),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          )
              : Container(),

          // Điều khiển video
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nút tua lùi
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                  onPressed: rewind10Seconds,
                ),

                // Nút Play/Pause
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: togglePlayPause,
                ),

                // Nút tua tiến
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                  onPressed: forward10Seconds,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
