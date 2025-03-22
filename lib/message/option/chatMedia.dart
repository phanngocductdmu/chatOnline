import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ChatMedia extends StatefulWidget {
  final String idChatRoom, idUser;

  const ChatMedia({
    super.key,
    required this.idChatRoom,
    required this.idUser,
  });

  @override
  State<ChatMedia> createState() => _ChatMediaState();
}

class _ChatMediaState extends State<ChatMedia> {
  String selectedType = 'image';
  Map<String, IconData> mediaTypes = {
    'image': Icons.image,
    'video': Icons.video_library,
    'audio': Icons.audiotrack,
    'pdf': Icons.picture_as_pdf,
    'ppt': Icons.slideshow,
    'excel': Icons.table_chart,
    'link': Icons.link,
  };

  Future<List<String>> fetchMedia() async {
    DatabaseReference messagesRef =
    FirebaseDatabase.instance.ref("chats/${widget.idChatRoom}/messages");
    DataSnapshot snapshot = await messagesRef.get();
    List<String> filteredUrls = [];

    if (snapshot.exists) {
      for (var child in snapshot.children) {
        Map<dynamic, dynamic> data = child.value as Map<dynamic, dynamic>;
        if (data['typeChat'] == selectedType && data['urlFile'] != null) {
          filteredUrls.add(data['urlFile']);
        }
      }
    }
    return filteredUrls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ảnh, file, link', style: TextStyle(color: Colors.white, fontSize: 18)),
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
      ),
      body: Column(
        children: [
          // Thanh lựa chọn loại dữ liệu
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: mediaTypes.keys.map((type) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedType = type;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    decoration: BoxDecoration(
                      color: selectedType == type ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(mediaTypes[type], size: 20, color: selectedType == type ? Colors.white : Colors.black),
                        SizedBox(width: 5),
                        Text(
                          type.toUpperCase(),
                          style: TextStyle(color: selectedType == type ? Colors.white : Colors.black),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Danh sách nội dung hiển thị
          Expanded(
            child: FutureBuilder<List<String>>(
              future: fetchMedia(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Không có dữ liệu"));
                }

                List<String> mediaUrls = snapshot.data!;
                return GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: mediaUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // TODO: Hiển thị ảnh, mở video, phát âm thanh
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: selectedType == 'image'
                            ? Image.network(mediaUrls[index], fit: BoxFit.cover)
                            : Container(
                          color: Colors.grey[300],
                          child: Icon(mediaTypes[selectedType], size: 40, color: Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
