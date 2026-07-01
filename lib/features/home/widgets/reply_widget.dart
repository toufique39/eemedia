import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReplyWidget extends StatefulWidget {
  final String commentId;
  final String postId;

  const ReplyWidget({super.key, required this.commentId, required this.postId});

  @override
  State<ReplyWidget> createState() => _ReplyWidgetState();
}

class _ReplyWidgetState extends State<ReplyWidget> {
  bool showReplies = false;

  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> addReply() async {
    final text = _replyController.text.trim();

    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data() ?? {};

    await FirebaseFirestore.instance.collection('replies').add({
      'commentId': widget.commentId,
      'postId': widget.postId,
      'userId': user.uid,
      'name': userData['name'] ?? 'Unknown',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _replyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                showReplies = !showReplies;
              });
            },

            child: Text(showReplies ? 'Hide Replies' : 'View Replies'),
          ),

          if (showReplies) ...[
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('replies')
                  .where('commentId', isEqualTo: widget.commentId)
                  .orderBy('createdAt')
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final replies = snapshot.data!.docs;

                return Column(
                  children: replies.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      dense: true,

                      leading: const CircleAvatar(
                        radius: 14,
                        child: Icon(Icons.person, size: 14),
                      ),

                      title: Text(data['name'] ?? ''),

                      subtitle: Text(data['text'] ?? ''),
                    );
                  }).toList(),
                );
              },
            ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,

                    decoration: const InputDecoration(
                      hintText: 'Write a reply...',
                    ),
                  ),
                ),

                IconButton(onPressed: addReply, icon: const Icon(Icons.send)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
