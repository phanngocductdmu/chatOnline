import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';

class HandDetector {
  final handDetector = GoogleMlKit.vision.objectDetector(
    options: ObjectDetectorOptions(
      classifyObjects: false,
      multipleObjects: true,
      mode: DetectionMode.stream,
    ),
  );

  int fistCount = 0;
  DateTime? firstFistTime;
  bool isHolding = false;

  Future<bool> detectHandGesture(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final objects = await handDetector.processImage(inputImage);

    bool isFistDetected = objects.isNotEmpty; // Giả sử có bàn tay là nắm tay
    return isFistDetected;
  }

  bool handleFistGesture(bool isFist) {
    final currentTime = DateTime.now();

    if (isFist) {
      if (fistCount == 0) {
        firstFistTime = currentTime;
        fistCount = 1;
        isHolding = true;
        print("✅ Nắm tay lần 1");
      } else if (fistCount == 1 && !isHolding && currentTime.difference(firstFistTime!).inSeconds <= 2) {
        fistCount = 2;
        print("✅ Nắm tay lần 2");
      } else if (fistCount == 2 && !isHolding && currentTime.difference(firstFistTime!).inSeconds <= 2) {
        print("✅ Nắm tay lần 3! Tắt video call.");
        return true; // Trả về true để tắt video call
      }
    } else {
      isHolding = false;
    }

    if (fistCount == 1 && currentTime.difference(firstFistTime!).inSeconds > 2) {
      fistCount = 0;
      firstFistTime = null;
      print("❌ Quá 2 giây! Reset bộ đếm.");
    }

    return false;
  }
}
