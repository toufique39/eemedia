import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/features/auth/screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eemedia/services/friend_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUserData =
              userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

          final List friends = List.from(currentUserData['friends'] ?? []);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =========================
                // PENDING FRIEND REQUESTS
                // =========================
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Friend Requests',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('friend_requests')
                      .where('receiverId', isEqualTo: currentUser.uid)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, requestSnapshot) {
                    if (!requestSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = requestSnapshot.data!.docs;

                    if (requests.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('No pending requests'),
                      );
                    }

                    return Column(
                      children: requests.map((request) {
                        final data = request.data() as Map<String, dynamic>;

                        final senderId = data['senderId'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(senderId)
                              .get(),
                          builder: (context, senderSnapshot) {
                            if (!senderSnapshot.hasData) {
                              return const SizedBox();
                            }

                            final senderData =
                                senderSnapshot.data!.data()
                                    as Map<String, dynamic>? ??
                                {};

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    'https://ui-avatars.com/api/?name=${senderData['name'] ?? 'U'}&background=random',
                                  ),
                                ),
                                title: Text(senderData['name'] ?? 'User'),
                                subtitle: Text(
                                  '@${senderData['username'] ?? ''}',
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfileScreen(
                                        userId: senderId,
                                        userData: senderData,
                                      ),
                                    ),
                                  );
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      ),
                                      onPressed: () async {
                                        await acceptFriendRequest(request.id);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        await rejectFriendRequest(request.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // =========================
                // SUGGESTED FRIENDS
                // =========================
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'People You May Know',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, usersSnapshot) {
                    if (!usersSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allUsers = usersSnapshot.data!.docs;
                    String userfriendStatus = 'none';

                    final suggestedUsers = allUsers
                        .where((doc) {
                          if (doc.id == currentUser.uid) {
                            return false;
                          }

                          if (friends.contains(doc.id)) {
                            return false;
                          }

                          return true;
                        })
                        .take(10)
                        .toList();

                    if (suggestedUsers.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('No suggestions available'),
                      );
                    }

                    return Column(
                      children: suggestedUsers.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                'https://ui-avatars.com/api/?name=${data['name'] ?? 'U'}&background=random',
                              ),
                            ),
                            title: Text(data['name'] ?? 'User'),
                            subtitle: Text('@${data['username'] ?? ''}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                    userId: doc.id,
                                    userData: data,
                                  ),
                                ),
                              );
                            },

                            trailing: ElevatedButton.icon(
                              onPressed: () async {
                                if (userfriendStatus == 'none') {
                                  await sendFriendRequest(doc.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Friend request sent'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You have already sent a request or are friends',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                userfriendStatus == 'none'
                                    ? Icons.person_add
                                    : userfriendStatus == 'sent'
                                    ? Icons.hourglass_top
                                    : Icons.person_off,
                                color: userfriendStatus == 'none'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              label: Text(
                                userfriendStatus == 'none'
                                    ? 'Add Friend'
                                    : 'Request Sent',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
