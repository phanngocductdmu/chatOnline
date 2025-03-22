import 'package:flutter/material.dart';
import 'package:chatonline/Search/TimKiem.dart';
import 'package:chatonline/Contacts/fiends.dart';
import 'package:chatonline/Contacts/group.dart';

class DanhBa extends StatefulWidget {
  const DanhBa({super.key});

  @override
  State<DanhBa> createState() => _DanhBaState();
}

class _DanhBaState extends State<DanhBa> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Tạo controller cho 3 tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideKeyboard,
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TimKiem()),
                );
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
          title: const Text(
            'Tìm kiếm',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 19,
            ),
          ),
          actions: [
            IconButton(
              icon: Image.asset(
                'assets/image/addfriend.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
              onPressed: () {
                print("Plus icon pressed");
              },
            ),
          ],
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Column(
          children: [
            // TabBar nằm ngoài AppBar, ngay dưới nó
            Container(
              color: Color(0xffFAFAFA), // Màu nền của TabBar
              child: TabBar(
                controller: _tabController,
                indicatorColor: Color(0xff11998E), // Màu của indicator khi tab được chọn
                indicatorWeight: 1,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black, // Màu chữ của tab khi được chọn
                unselectedLabelColor: Color(0xff707070), // Màu chữ của tab khi không được chọn
                tabs: const [
                  Tab(text: 'Bạn bè'),
                  Tab(text: 'Nhóm'),
                  Tab(text: 'Yêu thích'),
                ],
              ),
            ),
            // Nội dung các Tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Friends(),
                  Group(),
                  _buildTabContent('Danh sách yêu thích'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
