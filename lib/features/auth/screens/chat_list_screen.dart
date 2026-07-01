import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          return ListView.builder(
            itemCount: chats.length,

            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;

              final participants = List<String>.from(chat['participants']);

              // 🔥 Find other user
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
              );

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),

                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                  final userName = userData['name'] ?? 'User';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://ui-avatars.com/api/?name=$userName&background=random',
                      ),
                    ),

                    title: Text(userName),

                    subtitle: Text(
                      chat['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    trailing: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chats[index].id)
                          .collection('messages')
                          .where('senderId', isNotEqualTo: currentUser.uid)
                          .where('isRead', isEqualTo: false)
                          .snapshots(),
                      builder: (context, unreadSnapshot) {
                        final unreadCount =
                            unreadSnapshot.data?.docs.length ?? 0;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              formatTime(chat['lastMessageTime']),
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chats[index].id,

                            otherUserName: userName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // 🔥 TIME FORMAT
  String formatTime(dynamic timestamp) {
    if (timestamp == null) {
      return '';
    }

    final date = (timestamp as Timestamp).toDate();

    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');

    final suffix = hour >= 12 ? 'PM' : 'AM';

    final formattedHour = hour > 12 ? hour - 12 : hour;

    return '$formattedHour:$minute $suffix';
  }
}
