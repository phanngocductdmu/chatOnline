import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SeePhotos extends StatefulWidget {
  final String idFriend, avt;

  const SeePhotos({
    super.key,
    required this.idFriend,
    required this.avt,
  });

  @override
  _SeePhotosState createState() => _SeePhotosState();
}

class _SeePhotosState extends State<SeePhotos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: const SizedBox(), // Xóa icon mặc định ở leading
        title: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Text(
            "Đóng",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        centerTitle: false,
        titleSpacing: -20,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showReportBottomSheet(context);
            },
          ),
        ],
      ),
      body: Center(
        child: widget.avt.isNotEmpty
            ? Image.network(widget.avt)
            : const Text(
          "Hình ảnh không khả dụng",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showReportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Xác nhận",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const Text(
                "Bạn muốn thông báo ảnh này có nội dung xấu?",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              _buildReportOption(context, "Nội dung nhạy cảm"),
              _buildReportOption(context, "Làm phiền"),
              _buildReportOption(context, "Spam hoặc lừa đảo"),
              _buildReportOption(context, "Lý do khác"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOption(BuildContext context, String reason) {
    return ListTile(
      title: Center(child: Text(reason)), // Căn giữa
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã báo cáo: $reason")),
        );
      },
    );
  }
}