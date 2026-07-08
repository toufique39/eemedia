import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  static Future<void> classifyReel({
    required String reelId,
    required String videoUrl,
  }) async {
    try {
      debugPrint("AI REQUEST START");
      debugPrint("ReelId = $reelId");
      debugPrint("VideoUrl = $videoUrl");
      debugPrint("AI REQUEST START");
      debugPrint("kIsWeb = $kIsWeb");
      debugPrint("BASE URL = $baseUrl");
      final response = await http.post(
        Uri.parse("$baseUrl/api/v1/ai/classify-reel"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"reel_id": reelId, "video_url": videoUrl}),
      );

      debugPrint("Status Code = ${response.statusCode}");
      debugPrint("Response = ${response.body}");
      debugPrint("AI REQUEST END");
    } catch (e, stack) {
      debugPrint("AI ERROR = $e");
      debugPrint(stack.toString());
    }
  }
}
