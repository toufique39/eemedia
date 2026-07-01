import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/features/auth/screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsListScreen extends StatelessWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Friends'),
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

          final userData =
              userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

          final List friends = userData['friends'] ?? [];

          if (friends.isEmpty) {
            return const Center(child: Text('No friends yet'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(
                  FieldPath.documentId,
                  whereIn: friends.length > 10
                      ? friends.sublist(0, 10)
                      : friends,
                )
                .snapshots(),
            builder: (context, friendsSnapshot) {
              if (!friendsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = friendsSnapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final friendDoc = docs[index];
                  final data = friendDoc.data() as Map<String, dynamic>;

                  final name = data['name'] ?? 'User';
                  final username = data['username'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://ui-avatars.com/api/?name=$name&background=random',
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text('@$username'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(
                            userId: friendDoc.id,
                            userData: data,
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
}
