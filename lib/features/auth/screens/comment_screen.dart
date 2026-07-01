import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eemedia/features/home/widgets/reply_widget.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> addComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser!;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final userData = userDoc.data() ?? {};

    await FirebaseFirestore.instance.collection('comments').add({
      'postId': widget.postId,
      'userId': currentUser.uid,
      'name': userData['name'] ?? 'Unknown',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),

            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const Divider(),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('comments')
                    .where('postId', isEqualTo: widget.postId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data!.docs;

                  if (comments.isEmpty) {
                    return const Center(child: Text('No comments yet'));
                  }

                  return ListView.builder(
                    itemCount: comments.length,

                    itemBuilder: (context, index) {
                      final data =
                          comments[index].data() as Map<String, dynamic>;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),

                            title: Text(data['name'] ?? ''),

                            subtitle: Text(data['text'] ?? ''),
                          ),

                          ReplyWidget(
                            commentId: comments[index].id,

                            postId: widget.postId,
                          ),

                          const Divider(),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,

                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: addComment,

                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
