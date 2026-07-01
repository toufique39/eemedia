import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        shadowColor: Colors.lightBlueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }
          final notifications = snapshot.data!.docs;
          notifications.sort((a, b) {
            final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notificationData =
                  notifications[index].data() as Map<String, dynamic>;

              final senderName = notificationData['senderName'] ?? "Someone";
              final type = notificationData['type'] ?? "unknown";
              final reaction = notificationData['reaction'] ?? "reaction";

              return ElevatedButton(
                onPressed: () {
                  // Mark as read
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notifications[index].id)
                      .update({'isRead': true});

                  if (notificationData['type'] == 'reaction') {
                    // Navigate to post details (not implemented here)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigate to post details')),
                    );
                  } else if (type == 'comment') {
                    // Navigate to post details (not implemented here)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigate to post details')),
                    );
                  } else if (type == 'friend_request') {
                    // Navigate to friend requests screen
                    Navigator.pushNamed(context, '/friend-requests');
                  }
                },
                child: ListTile(
                  leading: type == 'reaction'
                      ? CircleAvatar(
                          child: Text(
                            (notificationData['reaction'] == 'like')
                                ? '👍'
                                : (notificationData['reaction'] == 'love')
                                ? '❤️'
                                : (notificationData['reaction'] == 'haha')
                                ? '😂'
                                : (notificationData['reaction'] == 'polti')
                                ? '🐥'
                                : (notificationData['reaction'] == 'sad')
                                ? '😢'
                                : (notificationData['reaction'] == 'angry')
                                ? '😠'
                                : '👍',
                          ),
                        )
                      : type == 'comment'
                      ? const Icon(Icons.comment)
                      : type == 'friend_request'
                      ? const Icon(Icons.person_add)
                      : type == 'Message'
                      ? const Icon(Icons.message)
                      : const Icon(Icons.notifications),

                  title: Text(
                    type == 'reaction'
                        ? "$senderName reacted to your post with $reaction"
                        : type == 'comment'
                        ? "$senderName commented on your post"
                        : type == 'friend_request'
                        ? "$senderName sent you a friend request"
                        : type == 'Message'
                        ? "$senderName sent you a message"
                        : "You have a new notification",
                    style: TextStyle(
                      fontWeight: notificationData['isRead'] == true
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  trailing: notificationData['isRead'] == true
                      ? null
                      : const Icon(Icons.circle, color: Colors.blue, size: 10),

                  textColor: notificationData['isRead'] == true
                      ? Colors.grey
                      : Colors.black,
                  iconColor: notificationData['isRead'] == true
                      ? Colors.grey
                      : Colors.blueAccent,

                  subtitle: Text(
                    notificationData['createdAt'] != null
                        ? (notificationData['createdAt'] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                              .substring(0, 16)
                        : 'Just now',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
