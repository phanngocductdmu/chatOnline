import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JustVisited extends StatefulWidget {
  const JustVisited({super.key});
  @override
  State<JustVisited> createState() => JustVisitedState();
}

class JustVisitedState extends State<JustVisited> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> friendsList = [];
  String? idUser;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getString('userId');
    });

    if (idUser != null) {
      listenToOnlineFriends(idUser!);
    }
  }

  void listenToOnlineFriends(String userId) {
    _database.child('friends/$userId').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? friendsData = event.snapshot.value as Map<dynamic, dynamic>?;

        List<Map<String, dynamic>> tempList = [];

        friendsData?.forEach((friendId, _) {
          _database.child('users/$friendId').onValue.listen((userEvent) {
            Map<dynamic, dynamic>? userData = userEvent.snapshot.value as Map<dynamic, dynamic>?;

            if (userData != null && userData['status']?['online'] == true) {
              tempList.add({
                'id': friendId,
                'fullName': userData['fullName'] ?? 'Không có tên',
                'avatar': userData['AVT'] ?? '',
              });
            }
            setState(() {
              friendsList = List.from(tempList);
            });
          });
        });
      } else {
        setState(() {
          friendsList = [];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: friendsList.isEmpty
          ? const Center(child: Text("Không có bạn bè nào online"))
          : Column(
        children: [
          for (var friend in friendsList) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey,
                    backgroundImage: friend['avatar'] != null && friend['avatar'].isNotEmpty
                        ? NetworkImage(friend['avatar'])
                        : null,
                    child: (friend['avatar'] == null || friend['avatar'].isEmpty)
                        ? const Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                friend['fullName'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(
              thickness: 1,
              height: 1,
              color: Color(0xFFF3F4F6),
            ),
          ]
        ],
      ),
    );
  }
}
