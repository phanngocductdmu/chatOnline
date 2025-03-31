import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chatonline/message/FullScreenMedia.dart';
import 'package:audioplayers/audioplayers.dart';
import 'FullScreenVideoView.dart';
import 'package:chatonline/message/LinkPreview.dart';

class MessageList extends StatefulWidget {
  final String chatRoomId;
  final String userId;
  final String idFriend;
  final String avt;
  final bool isSearchActive;
  final Function(Map<String, dynamic>) onReplyMessage;
  final Function(bool) onSearchToggle;
  final bool typeRoom;
  final bool isFriend;

  const MessageList({
    super.key,
    required this.chatRoomId,
    required this.userId,
    required this.avt,
    required this.onReplyMessage,
    required this.isSearchActive,
    required this.onSearchToggle,
    required this.typeRoom,
    required this.isFriend,
    required this.idFriend,
  });

  @override
  MessageListState createState() => MessageListState();
}

class MessageListState extends State<MessageList> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> messages = [];
  String? selectedMessageId;
  Map<String, dynamic>? playingMessage;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  List<Map<String, dynamic>> filteredMessages = [];
  late bool isSearch;
  String searchQuery = "";
  List<int> searchResults = [];
  int currentSearchIndex = 0;


  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _totalDuration = Duration.zero;
  Duration _remainingTime = Duration.zero;
  bool isPlaying = false;
  @override
  void initState() {
    _fetchMessages();
    super.initState();

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted && duration.inMilliseconds > 0) {
        setState(() {
          _totalDuration = duration;
          _remainingTime = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && _totalDuration != Duration.zero) {
        setState(() {
          Duration timeLeft = _totalDuration - position;
          _remainingTime = timeLeft.inMilliseconds > 0 ? timeLeft : Duration.zero;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          _remainingTime = Duration.zero;
        });
      }
    });

  }

  void _togglePlayPause(String url) async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(UrlSource(url));
      await _audioPlayer.resume();
    }

    setState(() {
      isPlaying = !isPlaying;
    });
  }

  String _formatDuration(Duration? duration) {
    print("Duration received: $duration"); // Debugging

    if (duration == null || duration == Duration.zero) return "00:00";

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  Future<String?> getVideoThumbnail(String videoUrl) async {
    try {
      final directory = await getTemporaryDirectory();
      final thumbnailPath = '${directory.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final command = '-i "$videoUrl" -ss 00:00:01.000 -vframes 1 "$thumbnailPath"';
      await FFmpegKit.execute(command);
      if (File(thumbnailPath).existsSync()) {
        return thumbnailPath;
      } else {
        return null;
      }
    } catch (e) {
      print("Error generating thumbnail: $e");
      return null;
    }
  }

  bool isHidden(Map<String, dynamic> message) {
    if (message['hiddenBy'] is List) {
      return (message['hiddenBy'] as List).contains(widget.userId);
    } else if (message['hiddenBy'] is String) {
      return message['hiddenBy'] == widget.userId;
    }
    return false;
  }

  void _fetchMessages() {
    _database
        .child('chats')
        .child(widget.chatRoomId)
        .child('messages')
        .onValue
        .listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, dynamic>> loadedMessages = [];
        Set<String> senderIds = {};
        Map<String, Map<String, String>> userCache = {};

        for (var entry in data.entries) {
          String key = entry.key;
          Map<dynamic, dynamic> value = entry.value;

          if (value['isDelete'] == true || isHidden(value.cast<String, dynamic>())) continue;


          String senderId = value['senderId'] ?? '';
          senderIds.add(senderId);

          loadedMessages.add({
            'id': key,
            'text': value['text'] ?? '',
            'time': _formatTimestamp(DateTime.fromMillisecondsSinceEpoch(value['timestamp'] ?? 0)),
            'senderId': senderId,
            'status': value['status'] ?? 'Đã gửi',
            'timestamp': value['timestamp'] ?? 0,
            'typeChat': value['typeChat'] ?? '',
            'statuss': value['statuss'] ?? 'Đã gửi',
            'urlFile': value['urlFile'] ?? '',
            'reactions': value['reactions'] ?? '',
            'hiddenBy': value['hiddenBy'] ?? '',
            'isDelete': value['isDelete'] ?? false,
            'replyTo': value['replyTo'] ?? '',
            'replyText': value['replyText'] ?? '',
            'totalTime': value['totalTime'] ,
          });
        }

        for (String userId in senderIds) {
          userCache[userId] = await _fetchUserInfo(userId);
        }

        for (var message in loadedMessages) {
          String senderId = message['senderId'];
          message['avatar'] = userCache[senderId]?['avatar'] ?? '';
          message['name'] = userCache[senderId]?['fullName'] ?? '';
        }

        loadedMessages.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

        setState(() {
          messages = loadedMessages.reversed.toList();
        });
      }
    });
  }

  Future<Map<String, String>> _fetchUserInfo(String userId) async {
    try {
      DatabaseEvent snapshot = await _database.child('users').child(userId).once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      return {
        'avatar': data?['AVT']?.toString() ?? '',
        'fullName': data?['fullName']?.toString() ?? '',
        'email': data?['email']?.toString() ?? ''
      };
    } catch (e) {
      return {'avatar': '', 'fullName': '', 'email': ''};
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(timestamp);
    if (difference.inDays == 0 && now.day == timestamp.day) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != timestamp.day)) {
      return 'Hôm qua, ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('dd/MM, HH:mm').format(timestamp);
    }
  }

  void deleteMessage(String chatRoomId, String messageId) {
    DatabaseReference messageRef = FirebaseDatabase.instance
        .ref()
        .child("chats/$chatRoomId/messages/$messageId");

    messageRef.update({"isDelete": true}).then((_) {
      print("✅ Tin nhắn xóa thành công!");
    }).catchError((error) {
      print("❌ Lỗi khi ẩn tin nhắn: $error");
    });
  }

  void hideMessage(String chatRoomId, String messageId, String userId) {
    DatabaseReference messageRef = FirebaseDatabase.instance
        .ref()
        .child("chats/$chatRoomId/messages/$messageId/hiddenBy");

    messageRef.once().then((DatabaseEvent event) {
      List<dynamic> hiddenBy = event.snapshot.value != null
          ? List<dynamic>.from(event.snapshot.value as List<dynamic>)
          : [];

      if (!hiddenBy.contains(userId)) {
        hiddenBy.add(userId);
      }

      messageRef.set(hiddenBy).then((_) {
        print("✅ Tin nhắn đã được ẩn!");
      }).catchError((error) {
        print("❌ Lỗi khi ẩn tin nhắn: $error");
      });
    });
  }

  void updateReaction(String chatId, String messageId, String userId, String value) {
    DatabaseReference messageRef = FirebaseDatabase.instance
        .ref()
        .child("chats")
        .child(chatId)
        .child("messages")
        .child(messageId)
        .child("reactions");

    messageRef.get().then((DataSnapshot snapshot) {
      Map<String, dynamic> reactions = {};

      if (snapshot.value is Map<Object?, Object?>) {
        reactions = (snapshot.value as Map<Object?, Object?>).map(
              (key, val) => MapEntry(key.toString(), Map<String, int>.from(val as Map)),
        );
      }

      if (value == 'remove') {
        // Xóa reaction của user hiện tại
        for (var key in reactions.keys.toList()) {
          reactions[key]?.remove(userId);
          if (reactions[key]?.isEmpty ?? true) {
            reactions.remove(key);
          }
        }
      } else {
        // Thêm hoặc cập nhật reaction
        reactions.putIfAbsent(value, () => {});
        reactions[value]![userId] = (reactions[value]?[userId] ?? 0) + 1;
      }

      // Lưu lại vào Firebase
      messageRef.set(reactions);
    }).catchError((error) {
      print("Lỗi cập nhật reactions: $error");
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToReplyMessage(String replyToId) {
    int index = messages.indexWhere((msg) => msg['id'] == replyToId);
    if (index == -2) {
      _fetchMessageById(replyToId);
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    double position = index * 100.0;
    double maxScroll = _scrollController.position.maxScrollExtent;
    double minScroll = _scrollController.position.minScrollExtent;
    double currentScroll = _scrollController.position.pixels;

    if ((position - currentScroll).abs() > 500) {
      _smoothScrollToPosition(position);
    } else {
      _scrollController.animateTo(
        position.clamp(minScroll, maxScroll),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _smoothScrollToPosition(double target) {
    double step = 200.0;
    double currentPosition = _scrollController.position.pixels;

    void scrollStep() {
      if ((target - currentPosition).abs() < step) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }

      currentPosition += target > currentPosition ? step : -step;
      _scrollController.animateTo(
        currentPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) => scrollStep()); // Tiếp tục cuộn nếu chưa đến nơi
    }

    scrollStep();
  }

  Future<void> _fetchMessageById(String messageId) async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref();
      setState(() {
        messages.insert(0, {
          'id': messageId,
          'text': 'Đang tải tin nhắn...',
          'loading': true,
        });
      });

      final snapshot = await databaseRef.child("messages/$messageId").get();

      if (snapshot.exists) {
        final messageData = Map<String, dynamic>.from(snapshot.value as Map);

        setState(() {
          int index = messages.indexWhere((msg) => msg['id'] == messageId);
          if (index != -1) {
            messages[index] = messageData;
          }
        });

        Future.delayed(const Duration(milliseconds: 200), () {
          _scrollToReplyMessage(messageId);
        });
      } else {
        print("Không tìm thấy tin nhắn có ID: $messageId");
      }
    } catch (e) {
      print("Lỗi khi tải tin nhắn từ Realtime Database: $e");
    }
  }

  void searchMessages(String query) {
    setState(() {
      searchQuery = query;
      searchResults.clear();
      currentSearchIndex = -1;

      if (query.isNotEmpty) {
        for (int i = 0; i < messages.length; i++) {
          String messageText = messages[i]['text']?.toLowerCase() ?? '';

          // Bỏ qua tin nhắn là link
          if (messages[i]['typeChat'] == "sticker") {
            continue;
          }

          if (messageText.contains(query.toLowerCase())) {
            searchResults.add(i);
          }
        }
      }

      // Log ra số lượng kết quả tìm được
      print("Tổng số kết quả tìm thấy: ${searchResults.length}");

      // Log ra nội dung tin nhắn tìm thấy
      for (int index in searchResults) {
        print("Tin nhắn tại index $index: ${messages[index]['text']}");
      }
    });
  }

  void _scrollToMessage(int index) {
    if (searchResults.isEmpty) return;
    int messageIndex = searchResults[index];
    _scrollController.animateTo(
      messageIndex * 70.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextSearchResult() {
    if (searchResults.isEmpty) return;
    setState(() {
      currentSearchIndex = (currentSearchIndex + 1) % searchResults.length;
    });
    _scrollToMessage(currentSearchIndex);
  }

  void _prevSearchResult() {
    if (searchResults.isEmpty) return;
    setState(() {
      currentSearchIndex = (currentSearchIndex - 1 + searchResults.length) % searchResults.length;
    });
    _scrollToMessage(currentSearchIndex);
  }

  void _sendFriendRequest(BuildContext context) {
    final DatabaseReference friendRequestRef = FirebaseDatabase.instance.ref("friendInvitation");

    final Map<String, dynamic> friendRequestData = {
      "from": widget.userId,
      "to": widget.idFriend,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    friendRequestRef.push().set(friendRequestData).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lời mời kết bạn đã được gửi')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi khi gửi lời mời')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    isSearch = widget.isSearchActive;
    return Container(
      color: const Color(0xFFE4E8F3),
      child: Column(
        children: [
          if (!widget.isFriend)
            GestureDetector(
              onTap: () {
                _sendFriendRequest(context);
              },
              child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_outlined, color: Colors.grey[800], size: 20,),
                    SizedBox(width: 8),
                    Text("Kết bạn", style: TextStyle(color: Colors.black, fontSize: 14)),
                  ],
                ),
              ),
            ),
          if (isSearch)
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Nhập tin nhắn cần tìm...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              isSearch = false;
                              searchQuery = "";
                              searchResults.clear();
                              currentSearchIndex = -1;
                            });
                            widget.onSearchToggle(false);
                          },
                        ),
                      ),
                      onChanged: (value) {
                        searchMessages(value);
                      },
                    ),
                  ),
                ),
                if (searchResults.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${currentSearchIndex + 1}/${searchResults.length}",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_upward, size: 16), // Nhỏ hơn
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        visualDensity: VisualDensity.compact, // Giảm kích thước padding nội bộ
                        onPressed: _prevSearchResult,
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_downward, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        onPressed: _nextSearchResult,
                      ),
                    ],
                  ),
              ],
            ),
          Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            reverse: true,
            itemBuilder: (context, index) {
              final message = messages[index];
              String text = message['text'] ?? "";
              bool isMe = message['senderId'] == widget.userId;
              bool isSelected = selectedMessageId == message['id'];

              List<TextSpan> textSpans = [];
              if (searchQuery.isNotEmpty && text.toLowerCase().contains(searchQuery)) {
                String lowerText = text.toLowerCase();
                int startIndex = 0;

                while (startIndex < lowerText.length) {
                  int matchIndex = lowerText.indexOf(searchQuery, startIndex);

                  if (matchIndex == -1) {
                    textSpans.add(TextSpan(text: text.substring(startIndex)));
                    break;
                  }

                  textSpans.add(TextSpan(text: text.substring(startIndex, matchIndex)));

                  textSpans.add(TextSpan(
                    text: text.substring(matchIndex, matchIndex + searchQuery.length),
                    style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                  ));

                  startIndex = matchIndex + searchQuery.length;
                }
              } else {
                textSpans.add(TextSpan(text: text));
              }

              if (!_messageKeys.containsKey(message['id'])) {
                _messageKeys[message['id']] = GlobalKey();
              }

                if (message['isDelete'] == true) return SizedBox();
                return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMessageId = isSelected ? null : message['id'];
                  });
                },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 12),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Căn giữa icon + text
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8), // Khoảng cách giữa icon và text
                                    Text(
                                      "Xóa tin nhắn của bạn",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  deleteMessage(widget.chatRoomId, message['id']);
                                  Navigator.pop(context);
                                },
                              ),
                              Divider(height: 1, thickness: 0.5),
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Căn giữa icon + text
                                  children: [
                                    Icon(Icons.visibility_off, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text("Ẩn tin nhắn phía bạn"),
                                  ],
                                ),
                                onTap: () {
                                  hideMessage(widget.chatRoomId, message['id'], widget.userId);
                                  Navigator.pop(context);
                                },
                              ),
                              Divider(height: 1, thickness: 0.5),
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.reply, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text("Trả lời tin nhắn"),
                                  ],
                                ),
                                onTap: () {
                                  widget.onReplyMessage(message);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: message['avatar'] == null || message['avatar'].isEmpty
                              ? CircleAvatar(
                            radius: 10.0,
                            backgroundColor: Colors.grey[300],
                            child: Icon(Icons.person, color: Colors.white, size: 10),
                          )
                              : CircleAvatar(
                            radius: 10.0,
                            backgroundImage: NetworkImage(message['avatar']),
                          ),
                        ),
                      Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 50,
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IntrinsicWidth(
                                  child: Container(
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: message['typeChat'] == 'sticker' ||
                                          message['typeChat'] == 'image' ||
                                          message['typeChat'] == 'video'
                                          ? Colors.transparent
                                          : message['typeChat'] == 'introduce'
                                          ? const Color(0xff13cc80)
                                          : (isMe ? const Color(0xFFB1EBC7) : Colors.white),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (message['replyText'] != null && message['replyText'].isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              _scrollToReplyMessage(message['replyTo']);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(8.0),
                                              margin: const EdgeInsets.only(bottom: 8.0),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(6.0),
                                              ),
                                              child: Text(
                                                message['replyText'],
                                                style: const TextStyle(color: Colors.black87, fontStyle: FontStyle.italic),
                                              ),
                                            ),
                                          ),
                                        if (widget.typeRoom && !isMe)
                                          Text(
                                            message['name'],
                                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        _buildMessageContent(message),
                                        if (message['typeChat'] != 'sticker' && message['typeChat'] != 'image' && message['typeChat'] != 'video')
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              message['time'],
                                              style: TextStyle(
                                                color: message['typeChat'] == 'introduce' ? Colors.white : Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (message['typeChat'] != 'sticker')
                                  Positioned(
                                    left: isMe ? (message['typeChat'] == 'image' || message['typeChat'] == 'video' ? 20 : 10) : null,
                                    right: isMe ? null : (message['typeChat'] == 'image' || message['typeChat'] == 'video') ? 20 : 10,
                                    bottom: (message['typeChat'] == 'image' || message['typeChat'] == 'video') ? 5 : -8,
                                    child: GestureDetector(
                                      onTap: () {
                                        String messageId = message['id']?.toString() ?? "";

                                        // Lấy danh sách reaction được sắp xếp theo số lượng nhiều nhất
                                        List<MapEntry<String, int>> sortedReactions = [];

                                        if (message['reactions'] is Map) {
                                          Map<String, dynamic> reactions = Map<String, dynamic>.from(message['reactions']);
                                          Map<String, int> mergedReactions = {};

                                          // Tính tổng số lượng mỗi reaction
                                          reactions.forEach((reactionType, users) {
                                            if (users is Map) {
                                              int totalCount = users.values.fold(0, (sum, value) {
                                                if (value is int) return sum + value;
                                                if (value is String) return sum + (int.tryParse(value) ?? 0);
                                                return sum;
                                              });

                                              if (totalCount > 0) {
                                                mergedReactions[reactionType] = totalCount;
                                              }
                                            }
                                          });

                                          sortedReactions = mergedReactions.entries.toList()
                                            ..sort((a, b) => b.value.compareTo(a.value));
                                        }

                                        // Nếu có reaction, lấy reaction có số lượng nhiều nhất, nếu không thì mặc định là "heart"
                                        String topReaction = sortedReactions.isNotEmpty ? sortedReactions.first.key : 'heart';

                                        // Cập nhật reaction với loại phổ biến nhất
                                        updateReaction(widget.chatRoomId, messageId, widget.userId, topReaction);
                                      },
                                      onLongPress: () {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          builder: (BuildContext context) {
                                            return GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => Navigator.pop(context),
                                              child: Padding(
                                                padding: const EdgeInsets.only(bottom: 50),
                                                child: Align(
                                                  alignment: Alignment.bottomCenter,
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(30),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black26,
                                                            blurRadius: 10,
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          _reactionButton("❤️", () => updateReaction(widget.chatRoomId, message['id'], widget.userId, 'heart')),
                                                          _reactionButton("👍", () => updateReaction(widget.chatRoomId, message['id'], widget.userId,'like')),
                                                          _reactionButton("😂", () => updateReaction(widget.chatRoomId, message['id'], widget.userId,'haha')),
                                                          _reactionButton("😮", () => updateReaction(widget.chatRoomId, message['id'], widget.userId,'wow')),
                                                          _reactionButton("😢", () => updateReaction(widget.chatRoomId, message['id'], widget.userId,'sad')),
                                                          _reactionButton("😡", () => updateReaction(widget.chatRoomId, message['id'], widget.userId,'angry')),
                                                          _reactionButton("🗑️", () => updateReaction(widget.chatRoomId, message['id'], widget.userId,'remove')),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Builder(
                                        builder: (context) {
                                          int totalReactions = 0;
                                          List<MapEntry<String, int>> sortedReactions = [];

                                          if (message['reactions'] is Map) {
                                            Map<String, dynamic> reactions = Map<String, dynamic>.from(message['reactions']);
                                            Map<String, int> mergedReactions = {};

                                            // Duyệt qua từng loại reaction và tính tổng số lượng
                                            reactions.forEach((reactionType, users) {
                                              if (users is Map) {
                                                int totalCount = users.values.fold(0, (sum, value) {
                                                  if (value is int) return sum + value;
                                                  if (value is String) return sum + (int.tryParse(value) ?? 0);
                                                  return sum;
                                                });

                                                if (totalCount > 0) {
                                                  mergedReactions[reactionType] = totalCount;
                                                }
                                              }
                                            });

                                            // Sắp xếp theo số lượng giảm dần
                                            sortedReactions = mergedReactions.entries.toList()
                                              ..sort((a, b) => b.value.compareTo(a.value));

                                            // Tổng số reactions
                                            totalReactions = sortedReactions.fold(0, (sum, e) => sum + e.value);
                                          }

                                          // Lấy các reaction nhiều nhất
                                          List<String> topReactions = sortedReactions.map((e) => e.key).toList();

                                          // Bản đồ reaction -> emoji
                                          final Map<String, String> emojiMap = {
                                            'heart': '❤️',
                                            'haha': '😂',
                                            'sad': '😢',
                                            'angry': '😡',
                                            'wow': '😮',
                                            'like': '👍',
                                          };

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFAFAFA),
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (topReactions.isEmpty)
                                                  Icon(
                                                    Icons.favorite_border,
                                                    color: Colors.grey,
                                                    size: 13,
                                                  )
                                                else ...[
                                                  ...topReactions.take(2).map((reaction) => Padding(
                                                    padding: const EdgeInsets.only(left: 2),
                                                    child: Text(
                                                      emojiMap[reaction] ?? '❓',
                                                      style: TextStyle(fontSize: 11),
                                                    ),
                                                  )),
                                                  if (totalReactions > 0)
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 2),
                                                      child: Text(
                                                        totalReactions.toString(),
                                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                                      ),
                                                    ),
                                                ],
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isMe && isSelected && message['typeChat'] != 'image' && message['typeChat'] != 'video')
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                message['status'] ?? 'Đã gửi',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    )
    );
  }

  Widget _reactionButton(String emoji, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: Text(emoji, style: TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> message) {
    String type = message['typeChat'];
    String text = message['text'] ?? "";

    if (type == 'text' && searchQuery.isNotEmpty && text.toLowerCase().contains(searchQuery.toLowerCase())) {
      List<TextSpan> textSpans = [];
      String lowerText = text.toLowerCase();
      int startIndex = 0;

      while (startIndex < lowerText.length) {
        int matchIndex = lowerText.indexOf(searchQuery.toLowerCase(), startIndex);

        if (matchIndex == -1) {
          textSpans.add(TextSpan(text: text.substring(startIndex)));
          break;
        }

        // Thêm phần không khớp
        textSpans.add(TextSpan(text: text.substring(startIndex, matchIndex)));

        // Thêm phần bôi vàng
        textSpans.add(TextSpan(
          text: text.substring(matchIndex, matchIndex + searchQuery.length),
          style: TextStyle(color: Colors.black, backgroundColor: Colors.limeAccent),
        ));

        startIndex = matchIndex + searchQuery.length;
      }

      return RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black, fontSize: 16),
          children: textSpans,
        ),
      );
    }

    switch (type) {
      case 'text':
        return Text(
          message['text'] ?? '',
          style: const TextStyle(color: Colors.black, fontSize: 16),
        );

      case 'sticker':
        return Image.network(
          message['urlFile'],
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        );

      case 'audio':
        return Row(
          children: [
            GestureDetector(
              onTap: () => _togglePlayPause(message['urlFile']),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 8),
            Text(
              _formatDuration(_totalDuration),
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );

      case 'call':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  message['statuss'] == 'missed' ? Icons.call_end : Icons.call,
                  color: message['statuss'] == 'missed' ? Colors.red : Colors.green, size: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  "Cuộc gọi ${message['statuss'] == 'missed' ? 'bị nhỡ' : 'thoại'}",
                  style: TextStyle(
                    color: message['statuss'] == 'missed' ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (message['totalTime'] != null && message['statuss'] != 'missed')
              Padding(
                padding: const EdgeInsets.only(left: 23),
                child: Text(
                  message['totalTime'],
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        );

      case 'videoCall':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  message['statuss'] == 'missed' ? Icons.videocam_off : Icons.videocam,
                  color: message['statuss'] == 'missed' ? Colors.red : Colors.green, size: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  "Cuộc gọi ${message['statuss'] == 'missed' ? 'bị nhỡ' : 'video'}",
                  style: TextStyle(
                    color: message['statuss'] == 'missed' ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (message['totalTime'] != null && message['statuss'] != 'missed')
              Padding(
                padding: const EdgeInsets.only(left: 23),
                child: Text(
                  message['totalTime'],
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        );

      case 'image':
        return GestureDetector(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => FullScreenImageView(
                  chatRoomID: widget.chatRoomId,
                  userID: widget.userId,
                  messageID: message['id'],
                  senderID: message['senderId'],
                  time: message['timestamp'],
                  imageUrl: message['urlFile'],
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 250,
                maxHeight: 300,
              ),
              child: Image.network(
                message['urlFile'] ?? '',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                const Text("Hình ảnh không khả dụng"),
              ),
            ),
          ),
        );

      case 'video':
        return GestureDetector(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => FullScreenVideoView(
                  senderID: message['senderId'],
                  time: message['timestamp'],
                  videoUrl: message['urlFile'],
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 250,
                maxHeight: 300,
              ),
              child: FutureBuilder<String?>(
                future: getVideoThumbnail(message['urlFile']),
                builder: (context, snapshot) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hiển thị ảnh thumbnail hoặc fallback khi lỗi
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Container(
                          width: 250,
                          height: 300,
                          color: Colors.black26,
                          child: const Icon(Icons.videocam, size: 50, color: Colors.white),
                        )
                      else if (snapshot.hasError || snapshot.data == null)
                        Container(
                          width: 250,
                          height: 300,
                          color: Colors.black26,
                          child: const Icon(Icons.error, size: 50, color: Colors.white),
                        )
                      else
                        Image.file(
                          File(snapshot.data!), // Load ảnh từ file
                          fit: BoxFit.cover,
                          width: 250,
                          height: 300,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 250,
                            height: 300,
                            color: Colors.black26,
                            child: const Icon(Icons.videocam, size: 50, color: Colors.white),
                          ),
                        ),

                      // Nút Play nằm đè lên ảnh thumbnail
                      const Icon(
                        Icons.play_circle_fill,
                        size: 50,
                        color: Colors.white,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

      case 'word':
        return _buildFileMessage(
            FontAwesomeIcons.fileWord, message['text'], message['urlFile'], Colors.blue);

      case 'ppt':
        return _buildFileMessage(
            FontAwesomeIcons.filePowerpoint, message['text'], message['urlFile'], Colors.red);

      case 'excel':
        return _buildFileMessage(
            FontAwesomeIcons.fileExcel, message['text'], message['urlFile'], Colors.green);

      case 'pdf':
        return _buildFileMessage(
            FontAwesomeIcons.filePdf, message['text'], message['urlFile'], Color(0xFFf14038));

      case 'link':
        return LinkPreview(messageText: message['text'] ?? '');

      case 'introduce':
        return FutureBuilder<Map<String, String>>(
          future: _fetchUserInfo(message['text'] ?? ''),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator()); // Hiển thị khi đang tải dữ liệu
            }
            final String avatarUrl = snapshot.data!['avatar'] ?? '';
            final String fullName = snapshot.data!['fullName'] ?? 'Người dùng';
            final String email = snapshot.data!['email'] ?? 'Không có email';

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, // Căn sát trái
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10), // Thêm padding nhỏ để không quá sát viền
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        backgroundColor: avatarUrl.isEmpty ? Colors.grey : Colors.transparent,
                        child: avatarUrl.isEmpty ? Icon(Icons.person, color: Colors.white, size: 30) : null,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              email,
                              style: TextStyle(fontSize: 14, color: Colors.grey[200]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.message, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Nhắn tin', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );

      default:
        return const Text("Không hỗ trợ loại tin nhắn này");
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      // Yêu cầu quyền truy cập bộ nhớ ngoài
      if (await Permission.storage.request().isGranted) {
        String savePath = "/storage/emulated/0/Download/$fileName"; // Lưu vào thư mục Download

        Dio dio = Dio();
        await dio.download(url, savePath, onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = (received / total * 100);
            print("Đang tải: ${progress.toStringAsFixed(0)}%");
          }
        });

        print("File đã tải xong: $savePath");
      } else {
        print("Quyền bị từ chối!");
      }
    } catch (e) {
      print("Lỗi khi tải file: $e");
    }
  }

  Widget _buildFileMessage(IconData icon, String fileName, String fileUrl, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            fileName,
            style: TextStyle(color: iconColor, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(Icons.cloud_download, color: iconColor),
          onPressed: () async {
            await _downloadFile(fileUrl, fileName);
          },
        ),
      ],
    );
  }
}