import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ScreenTimeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int entertainmentLimitSeconds = 60;

  static String _todayKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static String _getCategoryField(String category) {
    switch (category.toLowerCase()) {
      case 'entertainment':
        return 'entertainmentSeconds';

      case 'education':
        return 'educationSeconds';

      case 'news':
        return 'newsSeconds';

      default:
        return 'otherSeconds';
    }
  }

  static Future<void> addWatchTime({
    required String category,
    required int watchedSeconds,
  }) async {
    if (await _isProfessional()) {
      debugPrint("Professional account → Screen time skipped");
      return;
    }
    if (watchedSeconds <= 0) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final docRef = _firestore.collection('user_screen_time').doc(user.uid);

    final today = _todayKey();

    final doc = await docRef.get();

    if (!doc.exists || doc.data()?['date'] != today) {
      await docRef.set({
        'date': today,
        'entertainmentSeconds': 0,
        'educationSeconds': 0,
        'newsSeconds': 0,
        'otherSeconds': 0,
        'totalReelSeconds': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final categoryField = _getCategoryField(category);

    await docRef.update({
      categoryField: FieldValue.increment(watchedSeconds),
      'totalReelSeconds': FieldValue.increment(watchedSeconds),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('SCREEN TIME SAVED → $category : $watchedSeconds seconds');
  }

  static Future<int> getEntertainmentSeconds() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return 0;

    final doc = await _firestore
        .collection('user_screen_time')
        .doc(user.uid)
        .get();

    if (!doc.exists) return 0;

    final data = doc.data() ?? {};

    if (data['date'] != _todayKey()) {
      return 0;
    }

    return (data['entertainmentSeconds'] ?? 0) as int;
  }

  static Future<bool> hasReachedEntertainmentLimit() async {
    if (await _isProfessional()) {
      return false;
    }

    final entertainmentSeconds = await getEntertainmentSeconds();

    return entertainmentSeconds >= entertainmentLimitSeconds;
  }

  static Future<int> getRemainingEntertainmentSeconds() async {
    if (await _isProfessional()) {
      return 999999;
    }

    final entertainmentSeconds = await getEntertainmentSeconds();

    final remaining = entertainmentLimitSeconds - entertainmentSeconds;

    return remaining > 0 ? remaining : 0;
  }

  static Future<bool> _isProfessional() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) return false;

    final accountType = (doc.data()?['accountType'] ?? 'student')
        .toString()
        .toLowerCase();

    return accountType == 'professional';
  }

  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes == 0) {
      return "${remainingSeconds}s";
    }

    return "${minutes}m ${remainingSeconds}s";
  }
}
