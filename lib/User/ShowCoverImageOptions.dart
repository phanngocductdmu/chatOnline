import 'package:flutter/material.dart';

class ShowCoverImageOptions extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ShowCoverImageOptions({Key? key, required this.userData}) : super(key: key);

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
          _buildOption(context, Icons.visibility, "Xem ảnh bìa", () {}),
          _buildOption(context, Icons.camera_alt, "Chụp ảnh mới", () {}),
          _buildOption(context, Icons.image, "Chọn ảnh trên máy", () {}),
        ],
      ),
    );
  }
}
