import 'package:flutter/material.dart';

class AdsApp extends StatelessWidget {
  const AdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Danh sách ứng dụng mẫu
    final List<Map<String, String>> apps = [
      {
        'name': 'Facebook',
        'image': 'https://via.placeholder.com/100',
      },
      {
        'name': 'Zalo',
        'image': 'https://via.placeholder.com/100',
      },
      {
        'name': 'TikTok',
        'image': 'https://via.placeholder.com/100',
      },
      {
        'name': 'YouTube',
        'image': 'https://via.placeholder.com/100',
      },
    ];

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  app['image']!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(app['name']!,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Xử lý tải ứng dụng
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text('Tải', style: TextStyle(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}
