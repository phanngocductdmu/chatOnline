import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'dart:io';

class LinkPreview extends StatefulWidget {
  final String messageText;

  const LinkPreview({Key? key, required this.messageText}) : super(key: key);

  @override
  _LinkPreviewState createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  String? imageUrl;
  String? faviconUrl; // 🛠️ Biến lưu favicon
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    final Uri? url = Uri.tryParse(widget.messageText);
    if (url == null) {
      setState(() => isLoading = false);
      return;
    }

    // 🛠️ Đặt lại state trước khi fetch metadata
    setState(() {
      imageUrl = null;
      faviconUrl = null;
      isLoading = true;
    });

    try {
      var response = await MetadataFetch.extract(url.toString());
      var metadataMap = response?.toMap() ?? {}; // Chuyển metadata thành Map

      print("Metadata response: $metadataMap"); // Debug

      setState(() {
        imageUrl = metadataMap['image']; // Lấy ảnh preview nếu có
        faviconUrl = _extractFavicon(metadataMap, url); // Lấy favicon từ metadata hoặc fallback
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Lỗi lấy metadata: $e");
    }
  }


  String _extractFavicon(Map<String, dynamic> metadata, Uri url) {
    if (metadata.containsKey('favicon')) {
      return metadata['favicon'];
    }
    return "https://www.google.com/s2/favicons?domain=${url.host}&sz=64";
  }

  @override
  Widget build(BuildContext context) {
    final Uri? url = Uri.tryParse(widget.messageText);

    return url != null
        ? GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          print("Không thể mở liên kết: ${widget.messageText}");
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              height: 50,
              width: 50,
              child: Center(child: CircularProgressIndicator(color: Colors.green)),
            )
          else if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl!,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 50);
                },
              ),
            )
          else if (faviconUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  faviconUrl!,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 50);
                  },
                ),
              ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.messageText,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 16,
                decoration: TextDecoration.underline,
                decorationColor: Colors.blueAccent,
              ),
            ),
          ),
        ],
      ),
    )
        : const Text("Liên kết không hợp lệ", style: TextStyle(color: Colors.red));
  }
}
