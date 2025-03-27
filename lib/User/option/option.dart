import 'package:flutter/material.dart';
import '../information.dart';
import 'ChangeAvatar.dart';
import 'ChangeCoverImage.dart';
import 'bio.dart';

class Option extends StatefulWidget {
  final String idUser;
  final Map<String, dynamic> userData;

  const Option({
    super.key,
    required this.idUser,
    required this.userData,
  });

  @override
  State<Option> createState() => _OptionState();
}

class _OptionState extends State<Option> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(
          widget.userData['fullName'],
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Colors.white,
              child: Column(
                children: [
                  //thong tin
                  InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Information(idUser: widget.idUser, userData: widget.userData,)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Thông tin",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  //doi anh dai dien
                  InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(
                              builder: (context) => ChangeAvatar(idUser: widget.idUser),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Đổi ảnh đại diện",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
                  ),
                  //doi anh bia
                  InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(
                            builder: (context) => ChangeCoverImage(idUser: widget.idUser),
                          ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Đổi ảnh bìa",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Bio(idUser: widget.idUser, userData: widget.userData)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Cập nhật giới thiệu bản thân",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                    child: Text(
                      "Cài đặt",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF11998E),
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Information(idUser: widget.idUser, userData: widget.userData,)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Mã QR của tôi",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Information(idUser: widget.idUser, userData: widget.userData,)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Quyền riêng tư",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Information(idUser: widget.idUser, userData: widget.userData,)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Quản lý tải khoản",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFF3F4F6), // Màu xám nhạt theo mã hex
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Information(idUser: widget.idUser, userData: widget.userData,)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Cài đặt chung",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}