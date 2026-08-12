import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseStorageService {
  static final _supabase = Supabase.instance.client;

  static Future<String?> uploadPostImage(File imageFile) async {
    print("========== SUPABASE ==========");

    print(_supabase.auth.currentSession);

    print(_supabase.auth.currentSession);

    print(_supabase.auth.currentUser);
    print(_supabase.auth.currentSession?.accessToken);
    print("==============================");
    try {
      final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('FILE PATH: ${imageFile.path}');
      print('FILE EXISTS: ${await imageFile.exists()}');

      final response = await _supabase.storage
          .from('posts')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      print('UPLOAD RESPONSE: $response');

      final imageUrl = _supabase.storage.from('posts').getPublicUrl(fileName);

      print('PUBLIC URL: $imageUrl');

      return imageUrl;
    } catch (e, stackTrace) {
      print('SUPABASE ERROR: $e');
      print('STACK TRACE: $stackTrace');

      rethrow;
    }
  }

  static Future<String?> uploadWebImage(Uint8List bytes) async {
    final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage
        .from('posts')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabase.storage.from('posts').getPublicUrl(fileName);
  }

  static Future<void> deletePostImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);

      print('FULL URL: $imageUrl');

      print('PATH SEGMENTS: ${uri.pathSegments}');

      final fileName = uri.pathSegments.last;

      print('Deleting: $fileName');

      final response = await _supabase.storage.from('posts').remove([fileName]);

      print('Supabase response: $response');
    } catch (e) {
      print('DELETE ERROR: $e');
    }
  }

  static Future<String?> uploadStoryImage(File imageFile) async {
    try {
      final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('stories')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('stories').getPublicUrl(fileName);
    } catch (e) {
      print('Story Upload Error: $e');

      return null;
    }
  }

  static Future<String?> uploadWebStoryImage(Uint8List bytes) async {
    try {
      final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('stories')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('stories').getPublicUrl(fileName);
    } catch (e) {
      print('Web Story Upload Error: $e');

      return null;
    }
  }

  static Future<void> deleteStoryImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);

      final fileName = uri.pathSegments.last;

      await _supabase.storage.from('stories').remove([fileName]);

      print(
        'Story image deleted: '
        '$fileName',
      );
    } catch (e) {
      print(
        'Delete story image error: '
        '$e',
      );
    }
  }

  static Future<String?> uploadReelVideo(File videoFile) async {
    try {
      final fileName = 'reel_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _supabase.storage
          .from('reels')
          .upload(
            fileName,
            videoFile,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('reels').getPublicUrl(fileName);
    } catch (e) {
      print('Reel Upload Error: $e');

      return null;
    }
  }

  static Future<String?> uploadWebReelVideo(Uint8List bytes) async {
    try {
      final fileName = 'reel_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _supabase.storage
          .from('reels')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('reels').getPublicUrl(fileName);
    } catch (e) {
      print('Web Reel Upload Error: $e');

      return null;
    }
  }

  static Future<String?> uploadProfileImageBytes(Uint8List bytes) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('profiles')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return _supabase.storage.from('profiles').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Profile Image Upload Error: $e');
      return null;
    }
  }

  static Future<String?> uploadCoverImageBytes(Uint8List bytes) async {
    try {
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('profiles')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return _supabase.storage.from('profiles').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Cover Image Upload Error: $e');
      return null;
    }
  }

  static Future<void> deleteProfileImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);

      if (uri.pathSegments.isEmpty) return;

      final fileName = uri.pathSegments.last;

      await _supabase.storage.from('profiles').remove([fileName]);

      debugPrint('Profile image deleted: $fileName');
    } catch (e) {
      debugPrint('Delete profile image error: $e');
    }
  }

  static Future<void> deleteCoverImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);

      if (uri.pathSegments.isEmpty) return;

      final fileName = uri.pathSegments.last;

      await _supabase.storage.from('profiles').remove([fileName]);

      debugPrint('Cover image deleted: $fileName');
    } catch (e) {
      debugPrint('Delete cover image error: $e');
    }
  }
}
