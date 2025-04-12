import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class CreateNewReminder extends StatefulWidget {
  final String userId;
  final String chatRoomId;

  const CreateNewReminder({
    super.key,
    required this.userId,
    required this.chatRoomId,
  });

  @override
  CreateNewReminderState createState() => CreateNewReminderState();
}

class CreateNewReminderState extends State<CreateNewReminder> {
  DateTime? _selectedDateTime;
  String selectedRepeat = 'Không lặp';
  final TextEditingController _titleController = TextEditingController();
  String title = '';

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {});
    });
  }

  bool get isFormComplete {
    return title.isNotEmpty && _selectedDateTime != null && selectedRepeat.isNotEmpty;
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              timePickerTheme: TimePickerThemeData(
                dialHandColor: Colors.green,
                dialBackgroundColor: Colors.green.shade100,
                hourMinuteTextColor: Colors.black,
                hourMinuteColor: Colors.green.shade100,
              ),
              colorScheme: ColorScheme.light(
                primary: Colors.green,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        if (pickedDateTime.isBefore(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể chọn thời gian trong quá khứ')),
          );
          return;
        }

        setState(() {
          _selectedDateTime = pickedDateTime;
        });
      }
    }
  }

  void _showRepeatBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle drag bar
              Container(
                width: 40,
                height: 5,
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                'Lặp lại',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Divider(),
              _buildRepeatOption(
                icon: Icons.block,
                label: 'Không lặp',
                onTap: () {
                  setState(() => selectedRepeat = 'Không lặp');
                  Navigator.pop(context);
                },
              ),
              _buildRepeatOption(
                icon: Icons.calendar_today,
                label: 'Hằng ngày',
                onTap: () {
                  setState(() => selectedRepeat = 'Hằng ngày');
                  Navigator.pop(context);
                },
              ),
              _buildRepeatOption(
                icon: Icons.calendar_view_week,
                label: 'Hằng tuần',
                onTap: () {
                  setState(() => selectedRepeat = 'Hằng tuần');
                  Navigator.pop(context);
                },
              ),
              _buildRepeatOption(
                icon: Icons.calendar_view_month,
                label: 'Hằng tháng',
                onTap: () {
                  setState(() => selectedRepeat = 'Hằng tháng');
                  Navigator.pop(context);
                },
              ),
              _buildRepeatOption(
                icon: Icons.event_repeat,
                label: 'Hằng năm',
                onTap: () {
                  setState(() => selectedRepeat = 'Hằng năm');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRepeatOption({required IconData icon, required String label, required VoidCallback onTap,}) {
    return ListTile(leading: Icon(icon, color: Colors.green), title: Text(label, style: TextStyle(fontSize: 16)), onTap: onTap,);
  }

  String formatDateTime(DateTime dateTime) {
    final String weekday = DateFormat.EEEE('vi_VN').format(dateTime);
    final String date = DateFormat('d/M/y').format(dateTime);
    final String time = DateFormat('HH:mm').format(dateTime);
    return '$weekday, $date $time';
  }

  Future<void> sendMessage() async {
    final database = FirebaseDatabase.instance.ref();
    final messagePath = 'chats/${widget.chatRoomId}/messages';
    final messagesRef = database.child(messagePath);

    final newMessageRef = messagesRef.push();
    await newMessageRef.set({
      'senderId': widget.userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'typeChat': 'reminder',
      'text': title,
      'repeat': selectedRepeat,
      'reminderTime': _selectedDateTime!.millisecondsSinceEpoch
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo nhắc hẹn mới', style: TextStyle(color: Colors.white, fontSize: 18)),
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
          icon: Icon(Icons.close, color: Colors.white, size: 27),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: isFormComplete ? () {
                sendMessage();
              } : null,
              child: Text(
                'Xong',
                style: TextStyle(
                  color: isFormComplete ? Colors.white : Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      title = value.trim();
                    });
                  },
                  cursorColor: Colors.green,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề nhắc hẹn',
                    labelStyle: TextStyle(color: Colors.green),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ),
              Divider(color: Colors.grey[300]),
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.access_time, color: Colors.pink),
                      title: Text('Thời gian'),
                      trailing: Text(
                        _selectedDateTime != null
                            ? formatDateTime(_selectedDateTime!)
                            : 'Chưa chọn',
                        style: TextStyle(color: Colors.black54),
                      ),
                      onTap: () {
                        _selectDateTime(context);
                      },
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey[300]),
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.repeat, color: Colors.pink),
                      title: Text('Lặp lại'),
                      trailing: Text(selectedRepeat),
                      onTap: () {
                        _showRepeatBottomSheet(context);
                      },
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }
}