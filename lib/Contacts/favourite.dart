import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Favourite extends StatefulWidget {
  const Favourite({super.key});

  @override
  State<Favourite> createState() => FavouriteState();
}

class FavouriteState extends State<Favourite> {
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
      _fetchFriends(idUser!);
    }
  }

  void _fetchFriends(String userId) async {
    DatabaseEvent event = await _database.child('friends').once();
    Map<dynamic, dynamic>? friendsData = event.snapshot.value as Map<dynamic, dynamic>?;

    if (friendsData != null) {
      List<Map<String, String>> tempList = [];

      for (String friendId in friendsData.keys) {
        if (friendId == userId) continue;

        DatabaseEvent userEvent = await _database.child('users/$friendId').once();
        Map<dynamic, dynamic>? userData = userEvent.snapshot.value as Map<dynamic, dynamic>?;

        if (userData != null) {
          tempList.add({
            'id': friendId,
            'fullName': userData['fullName'] ?? 'Không có tên',
            'avatar': userData['AVT'] ?? '',
          });
        }
      }
      tempList.sort((a, b) => a['fullName']!.toLowerCase().compareTo(b['fullName']!.toLowerCase()));
      setState(() {
        friendsList = tempList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: friendsList.isEmpty
          ? const Center(child: SizedBox())
          : Column(
        children: [
          for (var friend in friendsList) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: friend['avatar'] != null && friend['avatar'].isNotEmpty
                    ? NetworkImage(friend['avatar'])
                    : null,
                child: (friend['avatar'] == null || friend['avatar'].isEmpty)
                    ? const Icon(Icons.person, size: 30, color: Colors.white)
                    : null,
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
