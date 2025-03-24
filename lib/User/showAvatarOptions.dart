import 'package:flutter/material.dart';
import 'createMoments.dart';
import 'seeMomemts.dart';
import 'package:chatonline/diary/seeMedia.dart';
import 'ChangeAvatar.dart';

class ShowAvatarOptions extends StatelessWidget {
  final Map<String, dynamic> avatarData;
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> moments;
  final String idUser;
  final String avatarUrl;
  final bool hasMoment;

  const ShowAvatarOptions({
    super.key,
    required this.avatarData,
    required this.idUser,
    required this.hasMoment,
    required this.moments,
    required this.userData,
    required this.avatarUrl,
  });

  Widget _buildOption(BuildContext context, IconData icon, String text, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey),
          title: Text(
            text,
            style: TextStyle(color: Colors.black),
          ),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
        ),
        Divider(thickness: 1, color: Colors.grey[200], indent: 56),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Tùy chọn ảnh đại diện",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          if (hasMoment)
            _buildOption(context, Icons.visibility_outlined, "Xem khoảnh khắc", () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SeeMoments(
                    idUser: idUser,
                    moments: moments,
                    userData: userData,
                  ))
              );
            }),

          const SizedBox(height: 8),
          _buildOption(context, Icons.add_box_outlined, "Tạo khoảnh khắc", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CreateMoments(idUser: idUser,)));
          }),
          if(avatarUrl.isNotEmpty)
            _buildOption(context, Icons.visibility, "Xem ảnh đại diện", () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SeeMedia(
                    fullName: userData['fullName'],
                    avt: userData['AVT'],
                    idUser: idUser,
                    post: avatarData,
                  ))
              );
            }),

          _buildOption(context, Icons.image, "Thay đổi ảnh đại diện", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeAvatar(idUser: idUser)));
          }),
        ],
      ),
    );
  }
}