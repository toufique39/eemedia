import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RecommendationApiService {
  // ✅ environment variable থেকে IP নাও
  static const String _pcIpAddress = String.fromEnvironment(
    'API_IP',
    defaultValue: '172.17.115.191',
  );

  static const bool _isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  static String get _baseUrl {
    // ✅ production এ HTTPS
    if (_isProduction) return 'https://your-api.com';

    if (kIsWeb) return 'http://localhost:8000';

    // ✅ Platform আলাদা করো
    if (!kIsWeb) {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
      if (Platform.isIOS) return 'http://localhost:8000';
    }

    return 'http://$_pcIpAddress:8000';
  }

  static Future<List<String>> getRecommendedReelIds({
    required String userId,
    int limit = 20,
    int retries = 2, // ✅ retry
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

        // ✅ response structure validate করো
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
        // ✅ exponential backoff
        await Future.delayed(Duration(seconds: attempt + 1));
      } on FormatException catch (e) {
        debugPrint('JSON parse error: $e');
        return []; // retry করার দরকার নেই
      } catch (e) {
        debugPrint('Attempt ${attempt + 1}: Error — $e');
        if (attempt == retries) return [];
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    return [];
  }
}
