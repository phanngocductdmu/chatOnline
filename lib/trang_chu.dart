import 'package:flutter/material.dart';
import 'tin_nhan.dart';
import 'Contacts.dart';
import 'User/user.dart';
import 'package:chatonline/discover/discover.dart';
import 'package:chatonline/diary/diary.dart';


class TrangChu extends StatefulWidget {
  const TrangChu({super.key});

  @override
  State<TrangChu> createState() => TrangChuState();
}

class TrangChuState extends State<TrangChu> {
  int _selectedIndex = 0;

  // Danh sách các widget cho từng tab
  static const List<Widget> _widgetOptions = <Widget>[
    TinNhan(),
    DanhBa(),
    Discover(),
    Diary(),
    User(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions
            .elementAt(_selectedIndex), // Hiển thị widget của tab được chọn
      ),
      bottomNavigationBar: Container(
        height: 80,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex, // Đánh dấu tab hiện tại
          onTap: _onItemTapped, // Hàm gọi khi người dùng nhấn vào tab
          selectedItemColor: Colors.green, // Màu sắc của mục được chọn (xanh)
          unselectedItemColor: Colors.grey, // Màu sắc của mục chưa chọn (xám)
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/image/un_message.png',
                width: 24,
                height: 24,
                color:
                    _selectedIndex == 0 ? Colors.green : Colors.grey, // Đổi màu
              ),
              label: 'Tin nhắn',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/image/un_danhba.png',
                width: 24,
                height: 24,
                color:
                    _selectedIndex == 1 ? Colors.green : Colors.grey, // Đổi màu
              ),
              label: 'Danh bạ',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/image/un_khampha.png',
                width: 22,
                height: 22,
                color:
                    _selectedIndex == 2 ? Colors.green : Colors.grey, // Đổi màu
              ),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/image/un_nhatky.png',
                width: 24,
                height: 24,
                color:
                    _selectedIndex == 3 ? Colors.green : Colors.grey, // Đổi màu
              ),
              label: 'Nhật ký',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.account_circle,
                size: 25,
                color:
                    _selectedIndex == 4 ? Colors.green : Colors.grey, // Đổi màu
              ),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
