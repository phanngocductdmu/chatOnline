import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'createNewReminder.dart';

class GroupCalendar extends StatefulWidget {
  final String userId;
  final String chatRoomId;

  const GroupCalendar({
    super.key,
    required this.userId,
    required this.chatRoomId,
  });

  @override
  GroupCalendarState createState() => GroupCalendarState();
}

class GroupCalendarState extends State<GroupCalendar> {
  List<Map<String, String>> friends = [];
  List<Map<String, String>> filteredFriends = [];
  List<String> selectedFriends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
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
        title: Text('Lịch nhóm', style: TextStyle(color: Colors.white, fontSize: 18)),
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
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {

            },
          ),
        ],
      ),
      body: Container(
        color: Color(0xFFf5f6f8),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 15),
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 48,
                      color: Colors.pink,
                    ),
                    SizedBox(height: 16),
                    FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Text(
                        'Giúp cả nhóm ghi nhớ các sự kiện, sinh nhật và ngày kỷ niệm quan trọng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => CreateNewReminder(userId: widget.userId, chatRoomId: widget.chatRoomId)));
              },
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16), // thêm padding ngang cho đẹp
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nhắc hẹn sắp tới', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.1),
                            shape: BoxShape.circle, // bo tròn
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.pink,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tạo nhắc hẹn',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Gặp mặt, đi ăn, du lịch,...',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey
                              ),
                            ),
                          ],
                        )
                      ],
                    ),

                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: null,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16), // thêm padding ngang cho đẹp
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ngày kỷ niệm hằng năm', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.pink,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tạo kỷ niệm',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Sinh nhật, dấu mốc,...',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}