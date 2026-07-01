import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> toggleReaction({
  required String collection,
  required String documentId,
  required String reaction,
}) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser!;

    final docRef = FirebaseFirestore.instance
        .collection(collection)
        .doc(documentId);

    final doc = await docRef.get();

    if (!doc.exists) return;

    final ownerId = doc['userId'] as String? ?? '';

    final currentUserData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final senderName = currentUserData.data()?['name'] ?? 'Someone';

    final data = doc.data() as Map<String, dynamic>;

    Map<String, dynamic> reactions = Map<String, dynamic>.from(
      data['reactions'] ?? {},
    );

    final currentReaction = reactions[currentUser.uid];

    if (currentReaction == reaction) {
      reactions.remove(currentUser.uid);
    } else {
      reactions[currentUser.uid] = reaction;
    }

    await docRef.update({'reactions': reactions});

    if (ownerId != currentUser.uid && currentReaction != reaction) {
      if (collection == 'posts') {
        await createReactionNotification(
          receiverId: ownerId,
          senderId: currentUser.uid,
          senderName: senderName,
          postId: documentId,
          reaction: reaction,
        );
      }

      // Reels notification later
    }
  } catch (e) {
    print('Reaction Error: $e');
  }
}
