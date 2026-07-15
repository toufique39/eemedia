import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RecommendationApiService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';

    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://172.17.114.149:8000';
    }

    return 'http://localhost:8000';
  }

  static Future<List<String>> getRecommendedReelIds({
    required String userId,
    int limit = 50,
    int retries = 2,
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final url = Uri.parse('$_baseUrl/api/v1/recommendations/reels');

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'user_id': userId, 'limit': limit}),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode != 200) {
          debugPrint(
            'Recommendation API Error [${response.statusCode}]: ${response.body}',
          );
          return [];
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (!data.containsKey('recommended_reel_ids')) {
          debugPrint('Unexpected API response format: $data');
          return [];
        }

        final rawIds = data['recommended_reel_ids'];
        if (rawIds is! List) {
          debugPrint('recommended_reel_ids is not a List: $rawIds');
          return [];
        }

        final List<String> ids = rawIds.whereType<String>().toList();

        debugPrint('RECOMMENDED REEL IDS FETCHED: ${ids.length} items');
        return ids;
      } on TimeoutException catch (e) {
        debugPrint('Attempt ${attempt + 1}: Timeout — $e');
        if (attempt == retries) return [];

        await Future.delayed(Duration(seconds: attempt + 1));
      } on FormatException catch (e) {
        debugPrint('JSON parse error: $e');
        return [];
      } catch (e) {
        debugPrint('Attempt ${attempt + 1}: Error — $e');
        if (attempt == retries) return [];
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    return [];
  }
}
