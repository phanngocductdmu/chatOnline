import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chatonline/message/option/personalPage/personalPageF.dart';

class SearchItem extends StatelessWidget {
  final String avatarUrl;
  final String fullName;
  final VoidCallback onPressed;
  final String idUser;
  final String idFriend;
  final bool isFriend;

  const SearchItem({
    super.key,
    required this.avatarUrl,
    required this.fullName,
    required this.onPressed,
    required this.idUser,
    required this.idFriend,
    required this.isFriend,
  });

  void _sendFriendRequest(BuildContext context) {
    final DatabaseReference friendRequestRef = FirebaseDatabase.instance.ref("friendInvitation");

    final Map<String, dynamic> friendRequestData = {
      "from": idUser,
      "to": idFriend,
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Container(
        height: 67,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) =>
                PersonalPage(
                  idUser: idUser,
                  idChatRoom: "",
                  nickName: fullName,
                  idFriend: idFriend,
                  avt: avatarUrl,
                  isFriend: isFriend,
                )));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatarUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    avatarUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
                    : SizedBox(
                  width: 50,
                  height: 50,
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    fullName,
                    style: TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _sendFriendRequest(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color(0xff97d6c4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'make_friend'.tr(),
                      style: TextStyle(
                        color: Color(0xFF11998e),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ),
    );
  }
}

class SearchItemChatRooms extends StatelessWidget {
  final String groupAvatar;
  final String groupName;
  final VoidCallback onTap;
  final VoidCallback onTapPersonal;
  const SearchItemChatRooms({
    super.key, required this.groupAvatar, required this.groupName, required this.onTap, required this.onTapPersonal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: GestureDetector(
        onTap: onTapPersonal,
        child: Container(
          height: 67,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                groupAvatar.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    groupAvatar,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
                    : SizedBox(
                  width: 50,
                  height: 50,
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    groupName,
                    style: TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color(0xff97d6c4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'texting'.tr(),
                      style: TextStyle(
                        color: Color(0xFF11998e),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}