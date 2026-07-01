import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createCommentNotification({
  required String receiverId,
  required String senderName,
  required String postId,
  required String commentText,
}) async {
  if (receiverId.isEmpty) return;

  await FirebaseFirestore.instance.collection('notifications').add({
    'receiverId': receiverId,
    'senderName': senderName,
    'type': 'comment',

    'message': '$senderName commented: "$commentText" 💬',

    'postId': postId,

    'createdAt': Timestamp.now(),

    'isRead': false,
  });
}

Future<void> createFriendRequestNotification({
  required String receiverId,
  required String senderName,
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'receiverId': receiverId,
    'senderName': senderName,
    'type': 'friend_request',
    'message': '$senderName sent you a friend request 👥',
    'createdAt': Timestamp.now(),
    'isRead': false,
  });
}

Future<void> createMessageNotification({
  required String receiverId,
  required String senderName,
  required String chatId,
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'receiverId': receiverId,
    'senderName': senderName,
    'type': 'message',
    'message': '$senderName sent you a message 💬',
    'chatId': chatId,
    'createdAt': Timestamp.now(),
    'isRead': false,
  });
}

Future<void> markNotificationAsRead(String notificationId) async {
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(notificationId)
      .update({'isRead': true});
}

Future<void> deleteNotification(String notificationId) async {
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(notificationId)
      .delete();
}

Future<void> createReactionNotification({
  required String receiverId,
  required String senderId,
  required String senderName,
  required String postId,
  required String reaction,
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'receiverId': receiverId,

    'senderId': senderId,

    'senderName': senderName,

    'postId': postId,

    'type': 'reaction',

    'reaction': reaction,

    'isRead': false,

    'createdAt': FieldValue.serverTimestamp(),
  });
}
