import 'package:flutter/material.dart';

class MessageItem extends StatelessWidget {
  final String userName;
  final String message;
  final String time;
  final String avatarUrl;
  final String status;
  final String senderId;
  final String currentUserId;
  final bool typeRoom;
  final String groupAvatar;
  final String groupName;
  final VoidCallback onTap;

  const MessageItem({
    super.key,
    required this.userName,
    required this.message,
    required this.time,
    required this.avatarUrl,
    required this.status,
    required this.senderId,
    required this.currentUserId,
    required this.typeRoom,
    required this.groupAvatar,
    required this.groupName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isMyMessage = senderId == currentUserId;
    bool isUnread = !isMyMessage && (status == 'Đã gửi' || status == 'Đã nhận');

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: typeRoom
                ? (groupAvatar.isNotEmpty
                ? CircleAvatar(
              backgroundImage: NetworkImage(groupAvatar),
              radius: 25,
            )
                : SizedBox(
              width: 50,
              height: 50,
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.group, color: Colors.white, size: 30),
              ),
            ))
                : (avatarUrl.isNotEmpty
                ? CircleAvatar(
              backgroundImage: NetworkImage(avatarUrl),
              radius: 25,
            )
                : SizedBox(
              width: 50,
              height: 50,
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
            )),
            title: Text(
              typeRoom ? groupName : userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              message,
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                color: isMyMessage ? Colors.grey : (isUnread ? Colors.black : Colors.grey[600]),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (isUnread) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.circle, size: 8, color: Colors.red),
                ],
              ],
            ),
            onTap: onTap,
          ),
          const Divider(
            thickness: 1,
            height: 1,
            color: Color(0xFFF3F4F6),
          ),
        ],
      ),
    );
  }
}
