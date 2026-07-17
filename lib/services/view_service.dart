import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> addView({required String reelId}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    final viewDocId = "${reelId}_${user.uid}";

    final viewRef = _firestore.collection("reel_views").doc(viewDocId);

    final exists = await viewRef.get();

    if (exists.exists) {
      return false;
    }

    final batch = _firestore.batch();

    batch.set(viewRef, {
      "reelId": reelId,
      "userId": user.uid,
      "viewedAt": FieldValue.serverTimestamp(),
    });

    final reelRef = _firestore.collection("reels").doc(reelId);

    batch.update(reelRef, {
      "views": FieldValue.increment(1),
      "uniqueViewers": FieldValue.increment(1),
    });

    await batch.commit();

    return true;
  }
}
