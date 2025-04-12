import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'addGroup.dart';

class GroupMembers extends StatefulWidget {
  final String userId;
  final String chatRoomId;
  final List<String> member;
  final int numMembers;
  const GroupMembers({
    super.key,
    required this.userId,
    required this.chatRoomId,
    required this.member,
    required this.numMembers,
  });

  @override
  GroupMembersState createState() => GroupMembersState();
}

class GroupMembersState extends State<GroupMembers> {
  List<Map<String, String>> friends = [];
  List<Map<String, String>> filteredFriends = [];
  List<String> selectedFriends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedFriends = List.from(widget.member);
    _loadMembersWithFriendStatus();
  }


  Future<void> _loadMembersWithFriendStatus() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final DatabaseReference friendsRef = ref.child('friends/${widget.userId}');
    final friendSnapshot = await friendsRef.get();
    Map<dynamic, dynamic> myFriends = {};
    if (friendSnapshot.exists) {
      myFriends = friendSnapshot.value as Map<dynamic, dynamic>;
    }
    List<Map<String, String>> memberData = [];
    for (String memberId in widget.member) {
      if (memberId == widget.userId) continue;
      final info = await getMyInfo(memberId);
      if (info != null) {
        memberData.add({
          'id': memberId,
          'name': info['fullName']!,
          'AVT': info['avt']!,
          'isFriend': myFriends.containsKey(memberId) ? 'true' : 'false',
        });
      }
    }

    setState(() {
      friends = memberData;
      isLoading = false;
    });
  }

  Future<Map<String, String>?> getMyInfo(String userId) async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$userId");
    DatabaseEvent event = await userRef.once();

    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> userData = event.snapshot.value as Map;
      return {
        'fullName': userData['fullName'] ?? 'Unknown',
        'avt': userData['AVT'] ?? '',
      };
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thành viên (${widget.numMembers})', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 27),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddGroup(
                    chatRoomId: widget.chatRoomId,
                    userId: widget.userId,
                    member: List<String>.from(widget.member),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {

            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(15, 15, 15, 0),
            child: Text(
              "Thành viên:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final member = friends[index];
                final isFriend = member['isFriend'] == 'true';

                return ListTile(
                  leading: member['AVT']!.isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(member['AVT']!))
                      : CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  title: Text(member['name'] ?? 'Không xác định'),
                  trailing: !isFriend
                      ? Icon(Icons.person_add_alt_outlined, color: Colors.green)
                      : null,
                );
              },
            ),
          )
        ],
      ),
    );
  }
}