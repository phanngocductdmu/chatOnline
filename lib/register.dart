import 'package:flutter/material.dart';

class FillInfoScreen extends StatefulWidget {
  final String email;
  const FillInfoScreen({super.key, required this.email});

  @override
  State<FillInfoScreen> createState() => _FillInfoScreenState();
}

class _FillInfoScreenState extends State<FillInfoScreen> {
  bool isMale = false;
  bool isFemale = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Điền thông tin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nhập tên đăng nhập:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            _buildTextField(),
            const SizedBox(height: 12),
            const Text(
              'Nhập mật khẩu:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            _buildTextField(isPassword: true),
            const SizedBox(height: 12),
            const Text(
              'Nhập lại mật khẩu:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            _buildTextField(isPassword: true),
            const SizedBox(height: 12),
            const Text(
              'Nhập tên của bạn:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            _buildTextField(),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: isMale,
                  onChanged: (value) {
                    setState(() {
                      isMale = value!;
                      isFemale = false;
                    });
                  },
                  activeColor: Colors.green,
                ),
                const Text('Nam'),
                const SizedBox(width: 20),
                Checkbox(
                  value: isFemale,
                  onChanged: (value) {
                    setState(() {
                      isFemale = value!;
                      isMale = false;
                    });
                  },
                  activeColor: Colors.green,
                ),
                const Text('Nữ'),
              ],
            ),

            const Spacer(),

            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38EF7D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      cursorColor: Colors.green,
      decoration: InputDecoration(
        hintStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF38EF7D)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
          const BorderSide(color: Color(0xFF38EF7D), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
