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

    int totalViews = 0;

    int totalReactions = 0;

    int like = 0;
    int love = 0;
    int haha = 0;
    int wow = 0;
    int sad = 0;
    int angry = 0;
    int polti = 0;

    //---------------- POSTS ----------------//

    for (final post in postsSnapshot.docs) {
      final reactions = Map<String, dynamic>.from(
        post.data()['reactions'] ?? {},
      );

      totalReactions += reactions.length;

      for (final reaction in reactions.values) {
        switch (reaction) {
          case "like":
            like++;
            break;

          case "love":
            love++;
            break;

          case "haha":
            haha++;
            break;

          case "wow":
            wow++;
            break;

          case "sad":
            sad++;
            break;

          case "angry":
            angry++;
            break;

          case "polti":
            polti++;
            break;
        }
      }
    }

    //---------------- REELS ----------------//

    for (final reel in reelsSnapshot.docs) {
      final data = reel.data();

      totalViews += (data["views"] ?? 0) as int;

      final reactions = Map<String, dynamic>.from(data["reactions"] ?? {});

      totalReactions += reactions.length;

      for (final reaction in reactions.values) {
        switch (reaction) {
          case "like":
            like++;
            break;

          case "love":
            love++;
            break;

          case "haha":
            haha++;
            break;

          case "wow":
            wow++;
            break;

          case "sad":
            sad++;
            break;

          case "angry":
            angry++;
            break;

          case "polti":
            polti++;
            break;
        }
      }
    }

    return {
      "posts": postsSnapshot.docs.length,
      "reels": reelsSnapshot.docs.length,

      "views": totalViews,

      "totalReactions": totalReactions,

      "like": like,
      "love": love,
      "haha": haha,
      "wow": wow,
      "sad": sad,
      "angry": angry,
      "polti": polti,
    };
  }
}
