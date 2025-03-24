import 'package:flutter/material.dart';
import 'ChangeCoverImage.dart';
import '../diary/seeMedia.dart';

class ShowCoverImageOptions extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> imageCoverData;
  final String idUser;

  const ShowCoverImageOptions({
    super.key,
    required this.userData,
    required this.imageCoverData,
    required this.idUser
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
          // Tiêu đề "Ảnh bìa"
          const Text(
            "Tùy chọn ảnh bìa",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildOption(context, Icons.visibility, "Xem ảnh bìa", () {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => SeeMedia(
                  fullName: userData['fullName'],
                  avt: userData['AVT'],
                  idUser: idUser,
                  post: imageCoverData,
                ))
            );
          }),
          _buildOption(context, Icons.image, "Thay đổi ảnh bìa", () {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChangeCoverImage(
                    idUser: idUser
                ))
            );
          }),
        ],
      ),
    );
  }
}
