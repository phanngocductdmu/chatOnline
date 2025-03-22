import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportUserScreen extends StatefulWidget {
  final String idFriend;
  final String idUser;
  final String type;


  const ReportUserScreen({
    super.key,
    required this.idFriend,
    required this.idUser,
    required this.type,
  });

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String? selectedReason;
  bool isSubmitting = false;
  bool isOtherReason = false;
  bool canSubmit = false;

  final List<String> reportReasons = [
    "Spam",
    "Nội dung nhạy cảm",
    "Lừa đảo",
    "Nội dung không phù hợp",
    "Quấy rối",
    "Khác"
  ];


  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      if (isOtherReason) {
        canSubmit = _descriptionController.text.trim().isNotEmpty;
      } else {
        canSubmit = true;
      }
    });
  }

  void submitReport() async {
    if (isSubmitting || !canSubmit) return;

    setState(() {
      isSubmitting = true;
    });

    DatabaseReference ref = FirebaseDatabase.instance.ref("reports").push(); // Tạo ID mới

    await ref.set({
      "idUser": widget.idUser,
      "idFriend": widget.idFriend,
      "reason": selectedReason,
      "description": isOtherReason ? _descriptionController.text.trim() : "",
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "typeReport": widget.type,
    });

    setState(() {
      isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Báo cáo đã được gửi!")),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateButtonState);
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo xấu tài khoản", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 27),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chọn lý do báo cáo:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedReason,
              items: reportReasons.map((String reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedReason = value!;
                  isOtherReason = (selectedReason == "Khác");
                  _updateButtonState();
                });
              },
              hint: const Text("Vui lòng chọn lý do báo xấu"),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Mô tả chi tiết (tuỳ chọn):",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Nhập mô tả chi tiết nếu cần...",
                errorText: isOtherReason && _descriptionController.text.trim().isEmpty
                    ? "Vui lòng nhập mô tả chi tiết"
                    : null,
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: canSubmit && !isSubmitting ? submitReport : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit ? const Color(0xFF11998E) : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Gửi báo cáo",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
