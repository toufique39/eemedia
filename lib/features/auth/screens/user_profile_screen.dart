import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/features/auth/screens/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eemedia/services/friend_service.dart';
import 'package:eemedia/services/chat_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String friendStatus = 'none';

  @override
  void initState() {
    super.initState();
    loadFriendStatus();
  }

  Future<void> loadFriendStatus() async {
    friendStatus = await getFriendStatus(widget.userId);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openChat() async {
    final currentUser = FirebaseAuth.instance.currentUser!;

    final chatId = await ChatService.createChatIfNotExists(
      currentUserId: currentUser.uid,
      otherUserId: widget.userId,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          otherUserName: widget.userData['name'] ?? 'User',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userData['name'] ?? 'User';
    final username = widget.userData['username'] ?? '';
    final bio = widget.userData['bio'] ?? 'No bio yet';

    final List friends = widget.userData['friends'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, postSnapshot) {
          final postCount = postSnapshot.data?.docs.length ?? 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Cover area
                Container(height: 180, color: Colors.blue.shade100),

                Transform.translate(
                  offset: const Offset(0, -50),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundImage: NetworkImage(
                          'https://ui-avatars.com/api/?name=$name&background=random',
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        '@$username',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),

                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(bio, textAlign: TextAlign.center),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        (widget.userData['isOnline'] ?? false)
                            ? '🟢 Active now'
                            : 'Last seen recently',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),

                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${friends.length} Friends',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(' • '),
                          Text(
                            '$postCount Posts',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Friend Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (friendStatus == 'none') {
                                    final message = await sendFriendRequest(
                                      widget.userId,
                                    );

                                    if (!mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );

                                    await loadFriendStatus();
                                    return;
                                  }

                                  if (friendStatus == 'friends') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Unfriend'),
                                          content: const Text(
                                            'Remove this friend?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, false);
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, true);
                                              },
                                              child: const Text('Unfriend'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      await unfriend(widget.userId);
                                      await loadFriendStatus();
                                    }
                                  }
                                },
                                icon: Icon(
                                  friendStatus == 'none'
                                      ? Icons.person_add
                                      : friendStatus == 'sent'
                                      ? Icons.hourglass_top
                                      : friendStatus == 'friends'
                                      ? Icons.check
                                      : Icons.person,
                                ),
                                label: Text(
                                  friendStatus == 'none'
                                      ? 'Add Friend'
                                      : friendStatus == 'sent'
                                      ? 'Request Sent'
                                      : friendStatus == 'friends'
                                      ? 'Friends'
                                      : 'Respond',
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Message Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: openChat,
                                icon: const Icon(Icons.message),
                                label: const Text('Message'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
