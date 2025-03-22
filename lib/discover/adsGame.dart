import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdsGame extends StatefulWidget {
  const AdsGame({super.key});

  @override
  _AdsGameState createState() => _AdsGameState();
}

class _AdsGameState extends State<AdsGame> {
  List<dynamic> games = [];

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final response = await http.get(
      Uri.parse('https://api.rawg.io/api/games?page_size=10'),
      headers: {'User-Agent': 'chatonline/1.0'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        games = data['results'];
      });
    } else {
      print('Lỗi khi lấy dữ liệu: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  game['background_image'] ?? 'https://via.placeholder.com/100',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(game['name'] ?? 'No Name',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Xử lý tải game
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
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
