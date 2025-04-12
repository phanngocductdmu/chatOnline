import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'emailAuthentication.dart';
import 'dart:math';


class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  CreateAccountState createState() => CreateAccountState();
}

class CreateAccountState extends State<CreateAccount> {
  final TextEditingController _emailController = TextEditingController();

  bool agreeToTestTerms = false;
  bool agreeToSocialTerms = false;

  bool isFormValid(String email) {
    final emailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailValid.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hợp lệ')),
      );
      return false;
    }
    if (!agreeToTestTerms || !agreeToSocialTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn phải đồng ý với tất cả các điều khoản')),
      );
      return false;
    }
    return true;
  }

  String generate6DigitCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  Future<void> checkEmailAndProceed(String email) async {
    final dbRef = FirebaseDatabase.instance.ref().child('users');
    final snapshot = await dbRef.get();
    bool emailExists = false;
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, user) {
        if (user['email'] == email) {
          emailExists = true;
        }
      });
    }

    if (emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email đã được đăng ký')),
      );
    } else {
      String otpCode = generate6DigitCode();
      print('Mã OTP: $otpCode'); // Gửi email ở đây nếu cần

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: email,
            otpCode: otpCode,
          ),
        ),
      );
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Nhập Email',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelStyle: TextStyle(color: Color(0xFF38EF7D)),
                hintText: 'nhập email của bạn',
                hintStyle: TextStyle(color: Colors.green),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF38EF7D), width: 2),
                ),
              ),
              cursorColor: Colors.green,
            ),
            const SizedBox(height: 16),

            // Checkbox 1
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: agreeToTestTerms,
                  activeColor: Color(0xFF38EF7D),
                  onChanged: (value) {
                    setState(() {
                      agreeToTestTerms = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        const TextSpan(text: 'Tôi đồng ý với các '),
                        TextSpan(
                          text: 'điều khoản của test',
                          style: const TextStyle(
                            color: Color(0xFF38EF7D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Checkbox 2
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: agreeToSocialTerms,
                  activeColor: Color(0xFF38EF7D),
                  onChanged: (value) {
                    setState(() {
                      agreeToSocialTerms = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        const TextSpan(text: 'Tôi đồng ý với các '),
                        TextSpan(
                          text: 'điều khoản mạng xã hội',
                          style: const TextStyle(
                            color: Color(0xFF38EF7D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Nút tiếp tục
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  String email = _emailController.text.trim();

                  if (isFormValid(email)) {
                    checkEmailAndProceed(email);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38EF7D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Tiếp tục',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
