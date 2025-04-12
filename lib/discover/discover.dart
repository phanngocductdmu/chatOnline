import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatonline/Search/TimKiem.dart';
import 'adsApp.dart';
import 'adsGame.dart';


class Discover extends StatefulWidget {
  const Discover({super.key});

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> with SingleTickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? idDiscover;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDiscoverId();
  }


  Future<void> _loadDiscoverId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idDiscover = prefs.getString('userId');
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButton(
                icon: Icon(Icons.search),
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
            title: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TimKiem()),
                );
              },
              child: Text(
                'search'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 19,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.qr_code),
                onPressed: () {},
              ),
            ],
            iconTheme: IconThemeData(color: Colors.white),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.green[700],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green[700],
              tabs: [
                Tab(text: 'game'.tr()),
                Tab(text: 'app'.tr()),
              ],
            ),
            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AdsGame(),
                  AdsApp(),
                ],
              )
            ),
          ],
        ),
      ),
    );
  }
}
