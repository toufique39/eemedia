import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String> getFriendStatus(String otherUserId) async {
  final currentUser = FirebaseAuth.instance.currentUser!;

  // 1. Already friends?
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .get();

  final List friends = userDoc.data()?['friends'] ?? [];

  if (friends.contains(otherUserId)) {
    return 'friends';
  }

  // 2. Sent request?
  final sentRequest = await FirebaseFirestore.instance
      .collection('friend_requests')
      .where('senderId', isEqualTo: currentUser.uid)
      .where('receiverId', isEqualTo: otherUserId)
      .where('status', isEqualTo: 'pending')
      .get();

  if (sentRequest.docs.isNotEmpty) {
    return 'sent';
  }

  // 3. Received request?
  final receivedRequest = await FirebaseFirestore.instance
      .collection('friend_requests')
      .where('senderId', isEqualTo: otherUserId)
      .where('receiverId', isEqualTo: currentUser.uid)
      .where('status', isEqualTo: 'pending')
      .get();

  if (receivedRequest.docs.isNotEmpty) {
    return 'received';
  }

  // 4. No relationship
  return 'none';
}

Future<String> sendFriendRequest(String receiverId) async {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final currentUserDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .get();
  final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
  final senderName = currentUserData['name'] ?? 'Someone';

  // Check if request already exists
  final existingRequest = await FirebaseFirestore.instance
      .collection('friend_requests')
      .where('senderId', isEqualTo: currentUser.uid)
      .where('receiverId', isEqualTo: receiverId)
      .where('status', isEqualTo: 'pending')
      .get();

  if (existingRequest.docs.isNotEmpty) {
    return 'Request already sent';
  }

  // Create friend request
  await FirebaseFirestore.instance.collection('friend_requests').add({
    'senderId': currentUser.uid,
    'receiverId': receiverId,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Create notification for the receiver
  await createFriendRequestNotification(
    receiverId: receiverId,
    senderName: senderName,
  );

  return 'Friend request sent';
}

Future<void> acceptFriendRequest(String requestId) async {
  final requestRef = FirebaseFirestore.instance
      .collection('friend_requests')
      .doc(requestId);

  final requestDoc = await requestRef.get();

  if (!requestDoc.exists) {
    throw Exception('Friend request not found');
  }

  final data = requestDoc.data();

  if (data == null) {
    throw Exception('Friend request data not found');
  }

  final senderId = data['senderId']?.toString();
  final receiverId = data['receiverId']?.toString();

  if (senderId == null ||
      receiverId == null ||
      senderId.isEmpty ||
      receiverId.isEmpty) {
    throw Exception('Invalid friend request data');
  }

  // Mark request as accepted
  await requestRef.update({'status': 'accepted'});

  // Add sender to receiver's friends
  await FirebaseFirestore.instance.collection('users').doc(receiverId).set({
    'friends': FieldValue.arrayUnion([senderId]),
  }, SetOptions(merge: true));

  // Add receiver to sender's friends
  await FirebaseFirestore.instance.collection('users').doc(senderId).set({
    'friends': FieldValue.arrayUnion([receiverId]),
  }, SetOptions(merge: true));
}

Future<void> rejectFriendRequest(String requestId) async {
  await FirebaseFirestore.instance
      .collection('friend_requests')
      .doc(requestId)
      .update({'status': 'rejected'});
}

Future<void> unfriend(String otherUserId) async {
  final currentUser = FirebaseAuth.instance.currentUser!;

  final batch = FirebaseFirestore.instance.batch();

  final currentUserRef = FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid);

  final otherUserRef = FirebaseFirestore.instance
      .collection('users')
      .doc(otherUserId);

  // Remove each other from friends array
  batch.update(currentUserRef, {
    'friends': FieldValue.arrayRemove([otherUserId]),
  });

  batch.update(otherUserRef, {
    'friends': FieldValue.arrayRemove([currentUser.uid]),
  });

  await batch.commit();
}
