import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomePage.dart';
import 'package:chatonline/firebase/auth_service.dart';
import 'package:chatonline/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'b');
  final _passwordController = TextEditingController(text: 'b');
  bool _isPasswordVisible = false;
  bool _isLoggedIn = false;
  void _login() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      String email = _emailController.text;
      String password = _passwordController.text;

      bool isAuthenticated = await AuthService().signInWithUsernameAndPassword(email, password);

      setState(() {
        _isLoggedIn = isAuthenticated;
      });

      if (_isLoggedIn) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
              (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tài khoản hoặc mật khẩu sai")));
      }
    } catch (e) {
      if (e is FirebaseException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi Firebase: ${e.message ?? 'Không xác định'}")),
        );
        print("Lỗi Firebase: ${e.message ?? 'Không xác định'}");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã xảy ra lỗi: $e")),
        );
        print("Lỗi: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isInputValid =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {});
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => MyApp(),));
                },
              ),
            ),
            leadingWidth: 40,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: Text(
              'login'.tr(),
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 19),
            ),
            iconTheme: IconThemeData(color: Colors.white),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
        body: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFF1F5F6),
                ),
                child: Text(
                  'title_login'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB2B5BA),
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    SizedBox(height: 5),
                    TextField(
                      controller: _emailController,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                      cursorColor: Colors.green,
                      decoration: InputDecoration(
                        hintText: 'username'.tr(),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0E4E7)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF11998e)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _emailController.clear();
                            _passwordController
                                .clear();
                          },
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                      cursorColor: Colors.green,
                      decoration: InputDecoration(
                        hintText: 'password'.tr(),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0E4E7)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF11998e)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons
                                .visibility, // Biểu tượng "Ẩn" hoặc "Hiện"
                            color: _isPasswordVisible
                                ? Colors.grey
                                : Colors.grey, // Đổi màu theo trạng thái
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible =
                              !_isPasswordVisible; // Toggle mật khẩu hiển thị
                            });
                          },
                        ),
                      ),
                      obscureText:
                      !_isPasswordVisible, // Ẩn/hiện mật khẩu tùy theo trạng thái
                      keyboardType: TextInputType.visiblePassword,
                    ),
                    SizedBox(height: 30),
                    Container(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () {
                          // Thực hiện hành động khi nhấn vào "Lấy lại mật khẩu"
                        },
                        child: Text(
                          'retrieve_password'.tr(),
                          style: TextStyle(
                            color: Color(0xFF11998e), // Màu xanh lá
                            fontSize: 14, // Kích thước chữ
                            fontWeight: FontWeight.w500, // Độ đậm
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: isInputValid
              ? _login
              : null, // Gọi hàm đăng nhập khi nhấn nếu nhập đủ
          backgroundColor: isInputValid
              ? Color(0xFF11998e)
              : Color(0xFFC4E0D1), // Thay đổi màu nút
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Đảm bảo nút tròn
          ),
          child: Icon(
            Icons.arrow_forward,
            color:
            isInputValid ? Colors.white : Colors.grey, // Thay đổi màu icon
          ),
        ),
      ),
    );
  }
}