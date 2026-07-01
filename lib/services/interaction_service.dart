import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InteractionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> logInteraction({
    required String reelId,
    required String eventType,
    required num eventValue,
    required String category,
    required String subCategory,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('INTERACTION ERROR: User not logged in');
        return;
      }

      await _firestore.collection('interactions').add({
        'userId': user.uid,
        'itemId': reelId,
        'eventType': eventType,
        'eventValue': eventValue,
        'category': category,
        'subCategory': subCategory,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint(
        'INTERACTION SAVED → '
        'user=${user.uid}, '
        'reel=$reelId, '
        'event=$eventType, '
        'value=$eventValue',
      );
    } catch (e) {
      debugPrint('INTERACTION SAVE ERROR: $e');
    }
  }

  static Future<void> logReactionInteraction({
    required String reelId,
    required String reaction,
    required String category,
    required String subCategory,
  }) async {
    final reactionScore = _reactionScore(reaction);

    await logInteraction(
      reelId: reelId,
      eventType: reaction,
      eventValue: reactionScore,
      category: category,
      subCategory: subCategory,
    );
  }

  static int _reactionScore(String reaction) {
    switch (reaction.toLowerCase()) {
      case 'like':
        return 1;

      case 'love':
        return 3;

      case 'wow':
        return 2;

      case 'haha':
        return 2;

      case 'polti':
        return 2;

      case 'sad':
        return 1;

      case 'angry':
        return 1;

      default:
        return 1;
    }
  }
}
