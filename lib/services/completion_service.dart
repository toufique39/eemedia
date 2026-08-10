import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<double> saveCompletion({
    required String reelId,

    required int watchedSeconds,

    required int totalSeconds,
  }) async {
    if (totalSeconds <= 0) return 0;

    final percent = (watchedSeconds / totalSeconds) * 100;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return percent;

    await _firestore
        .collection("reel_completion")
        .doc("${reelId}_${user.uid}")
        .set({
          "reelId": reelId,

          "userId": user.uid,

          "watchedSeconds": watchedSeconds,

          "totalSeconds": totalSeconds,

          "completionRate": percent,

          "updatedAt": FieldValue.serverTimestamp(),
        });

    return percent;
  }
}
