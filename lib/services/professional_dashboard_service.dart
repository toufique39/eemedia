import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalDashboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> getAnalytics(String userId) async {
    final postsSnapshot = await _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .get();

    final reelsSnapshot = await _firestore
        .collection('reels')
        .where('userId', isEqualTo: userId)
        .get();

    int totalLikes = 0;
    int totalViews = 0;

    for (final post in postsSnapshot.docs) {
      final reactions = Map<String, dynamic>.from(
        post.data()['reactions'] ?? {},
      );

      totalLikes += reactions.length;
    }

    for (final reel in reelsSnapshot.docs) {
      final data = reel.data();

      totalLikes += (data['likesCount'] ?? 0) as int;

      totalViews += (data['views'] ?? 0) as int;
    }

    return {
      "posts": postsSnapshot.docs.length,
      "reels": reelsSnapshot.docs.length,
      "likes": totalLikes,
      "views": totalViews,
    };
  }
}
