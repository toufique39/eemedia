import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostPrivacyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current user's accepted friends
  static Future<Set<String>> getFriendIds() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return {};
    }

    final userId = currentUser.uid;

    final sent = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    final received = await _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    final friendIds = <String>{};

    for (final doc in sent.docs) {
      final data = doc.data();

      final friendId = data['receiverId']?.toString();

      if (friendId != null && friendId.isNotEmpty) {
        friendIds.add(friendId);
      }
    }

    for (final doc in received.docs) {
      final data = doc.data();

      final friendId = data['senderId']?.toString();

      if (friendId != null && friendId.isNotEmpty) {
        friendIds.add(friendId);
      }
    }

    return friendIds;
  }

  static bool canViewPost({
    required Map<String, dynamic> postData,
    required String currentUserId,
    required Set<String> friendIds,
  }) {
    final ownerId = postData['userId']?.toString() ?? '';

    final visibility = (postData['visibility'] ?? 'everyone')
        .toString()
        .toLowerCase();

    if (ownerId == currentUserId) {
      return true;
    }

    if (visibility == 'everyone') {
      return true;
    }

    if (visibility == 'friends') {
      return friendIds.contains(ownerId);
    }

    return false;
  }
}
