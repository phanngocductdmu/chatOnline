import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'mess.dart';
import 'Contacts.dart';
import 'User/user.dart';
import 'package:chatonline/discover/discover.dart';
import 'package:chatonline/diary/diary.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    Mess(),
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
            .elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        height: 80,
        child: BottomNavigationBar(
          backgroundColor: Colors.white, // Màu nền trắng
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
                color: _selectedIndex == 0 ? Colors.green : Colors.grey,
              ),
              label: 'message'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/image/un_danhba.png',
                width: 24,
                height: 24,
                color: _selectedIndex == 1 ? Colors.green : Colors.grey,
              ),
              label: 'contacts'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/image/un_khampha.png',
                width: 22,
                height: 22,
                color: _selectedIndex == 2 ? Colors.green : Colors.grey,
              ),
              label: 'discover'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/image/un_nhatky.png',
                width: 24,
                height: 24,
                color: _selectedIndex == 3 ? Colors.green : Colors.grey,
              ),
              label: 'diary'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.account_circle,
                size: 25,
                color: _selectedIndex == 4 ? Colors.green : Colors.grey,
              ),
              label: 'user'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
