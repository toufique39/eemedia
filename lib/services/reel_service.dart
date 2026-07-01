import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReelService {
  static Future<void> toggleLike(String reelId, List<String> likes) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final reelRef = FirebaseFirestore.instance.collection('reels').doc(reelId);

    if (likes.contains(uid)) {
      await reelRef.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await reelRef.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  static Future<void> incrementViewCount(String reelId) async {
    final reelRef = FirebaseFirestore.instance.collection('reels').doc(reelId);

    await reelRef.update({'views': FieldValue.increment(1)});
  }

  static Future<void> incrementShareCount(String reelId) async {
    final reelRef = FirebaseFirestore.instance.collection('reels').doc(reelId);

    await reelRef.update({'shares': FieldValue.increment(1)});
  }

  static Future<void> incrementCommentCount(String reelId) async {
    final reelRef = FirebaseFirestore.instance.collection('reels').doc(reelId);

    await reelRef.update({'comments': FieldValue.increment(1)});
  }

  static Future<void> addComment(String reelId, String comment) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userSnapshot = await userRef.get();
    final username = userSnapshot.data()?['username'] ?? 'Unknown';

    final commentData = {
      'userId': uid,
      'username': username,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final commentsRef = FirebaseFirestore.instance
        .collection('reels')
        .doc(reelId)
        .collection('comments');

    await commentsRef.add(commentData);

    // Increment the comment count
    await incrementCommentCount(reelId);
  }

  static Future<void> deleteComment(String reelId, String commentId) async {
    final commentsRef = FirebaseFirestore.instance
        .collection('reels')
        .doc(reelId)
        .collection('comments');

    await commentsRef.doc(commentId).delete();

    // Decrement the comment count
    final reelRef = FirebaseFirestore.instance.collection('reels').doc(reelId);
    await reelRef.update({'comments': FieldValue.increment(-1)});
  }
}
