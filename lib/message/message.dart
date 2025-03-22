import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'message_list.dart';
import 'message_input.dart';
import 'package:chatonline/message/call/call.dart';
import 'package:chatonline/message/call/video_call.dart';
import 'package:chatonline/message/option/optionMessage.dart';
import 'package:chatonline/message/optionGroup/optionGroup.dart';
import 'package:chatonline/message/optionGroup/addGroup.dart';
import 'package:chatonline/HomePage.dart';

class Message extends StatefulWidget {
  final String chatRoomId, idFriend, avt, fullName, userId, groupAvatar, groupName, description;
  final bool typeRoom, isFriend;
  final int numMembers;
  final List<String> member;

  const Message({
    super.key,
    required this.chatRoomId,
    required this.idFriend,
    required this.avt,
    required this.fullName,
    required this.userId,
    required this.typeRoom,
    required this.groupAvatar, 
    required this.groupName,
    required this.numMembers,
    required this.member,
    required this.description,
    required this.isFriend,
  });

  @override
  MessageState createState() => MessageState();
}

class MessageState extends State<Message> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _isTyping = false;
  bool isSearchActive = false;
  Map<String, dynamic>? selectedReplyMessage;


  void handleReplyMessage(Map<String, dynamic> message) {
    setState(() {
      selectedReplyMessage = message;
    });
  }

  @override
  void initState() {
    super.initState();
    _listenTypingStatus();
  }

  void _listenTypingStatus() {
    _database.child('typingStatus/${widget.chatRoomId}/${widget.idFriend}').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value == true) {
        setState(() => _isTyping = true);
      } else {
        setState(() => _isTyping = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 27, color: Colors.white),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => TrangChu()),
              (route) => route.isFirst,
          )
        ),
        title: GestureDetector(
          onTap: () async {
            if (widget.typeRoom) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OptionGroup(
                    idFriend: widget.idFriend,
                    idChatRoom: widget.chatRoomId,
                    groupName: widget.groupName,
                    idUser: widget.userId,
                    groupAvatar: widget.groupAvatar,
                    member: List<String>.from(widget.member),
                    description: widget.description,
                    onSearchToggle: (bool value) {
                      setState(() {
                        isSearchActive = value;
                      });
                    },
                  ),
                ),
              );
              if (result == true) {
                setState(() {
                  isSearchActive = result;
                });
              }
            } else {
              // Xử lý khi là chat riêng tư
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OptionMessage(
                    idFriend: widget.idFriend,
                    idChatRoom: widget.chatRoomId,
                    nickName: widget.fullName,
                    idUser: widget.userId,
                    avt: widget.avt,
                    onSearchToggle: (bool value) {
                      setState(() {
                        isSearchActive = value;
                      });
                    },
                  ),
                ),
              );
              if (result == true) {
                setState(() {
                  isSearchActive = result;
                });
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.typeRoom) ...[
                Text(widget.groupName, style: const TextStyle(fontSize: 17, color: Colors.white)),
                Text(
                  "${widget.numMembers.toString()} thành viên",
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ] else ...[
                Text(widget.fullName, style: const TextStyle(fontSize: 17, color: Colors.white)),
                if (_isTyping && widget.isFriend)
                  const Text(
                    "Đang soạn tin nhắn...",
                    style: TextStyle(fontSize: 13, color: Colors.white70, fontStyle: FontStyle.italic),
                  ),
              ],
              if (!widget.isFriend)
                const Text(
                  "NGƯỜI LẠ",
                  style: TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                ),
            ],
          )
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          widget.typeRoom
              ? IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white), // Icon thêm thành viên
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddGroup(
                    chatRoomId: widget.chatRoomId,
                    userId: widget.userId,
                    member: List<String>.from(widget.member),
                  ),
                ),
              );
            },
          )
              : Row(
            children: [
              IconButton(
                icon: const Icon(Icons.call, color: Colors.white), // Icon gọi thoại
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Call(
                        chatRoomId: widget.chatRoomId,
                        idFriend: widget.idFriend,
                        avt: widget.avt,
                        fullName: widget.fullName,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.videocam, color: Colors.white), // Icon gọi video
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCall(
                        chatRoomId: widget.chatRoomId,
                        idFriend: widget.idFriend,
                        avt: widget.avt,
                        fullName: widget.fullName,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => widget.typeRoom
                      ? OptionGroup(
                    idFriend: widget.idFriend,
                    idChatRoom: widget.chatRoomId,
                    groupName: widget.groupName,
                    idUser: widget.userId,
                    groupAvatar: widget.groupAvatar,
                    member: List<String>.from(widget.member),
                    description: widget.description,
                    onSearchToggle: (bool value) {
                      setState(() {
                        isSearchActive = value;
                      });
                    },
                  )
                      : OptionMessage(
                    idFriend: widget.idFriend,
                    idChatRoom: widget.chatRoomId,
                    nickName: widget.fullName,
                    idUser: widget.userId,
                    avt: widget.avt,
                    onSearchToggle: (bool value) {
                      setState(() {
                        isSearchActive = value;
                      });
                    },
                  ),
                ),
              );

              if (result == true) {
                setState(() {
                  isSearchActive = result;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MessageList(
              chatRoomId: widget.chatRoomId,
              userId: widget.userId,
              avt: widget.avt,
              isFriend: widget.isFriend,
              idFriend: widget.idFriend,
              onReplyMessage: (replyData) {
                setState(() {
                  selectedReplyMessage = replyData;
                });
              },
              isSearchActive: isSearchActive,
              onSearchToggle: (bool value) {
                setState(() {
                  isSearchActive = value;
                });
              },
              typeRoom: widget.typeRoom,
            ),
          ),
          MessageInput(
            chatRoomId: widget.chatRoomId,
            senderId: widget.userId,
            idFriend: widget.idFriend,
            selectedReplyMessage: selectedReplyMessage,
            isFriend: widget.isFriend,
            onClearReply: () {
            setState(() {
              selectedReplyMessage = null;
            });
          },),
        ],
      ),
    );
  }
}
