import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/services/supabase_storage_service.dart';

class StoryCleanupService {
  static Future<void> cleanupExpiredStories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stories')
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final imageUrl = data['imageUrl'] ?? '';

        // Delete image
        if (imageUrl.isNotEmpty) {
          await SupabaseStorageService.deleteStoryImage(imageUrl);
        }

        // Delete Firestore doc
        await doc.reference.delete();
      }

      print(
        'Expired stories cleaned: '
        '${snapshot.docs.length}',
      );
    } catch (e) {
      print('Story cleanup error: $e');
    }
  }
}
