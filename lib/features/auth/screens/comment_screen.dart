import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/services/comment_service.dart';

import 'package:flutter/material.dart';
import 'package:eemedia/features/home/widgets/reply_widget.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String collection;
  final String documentId;

  const CommentScreen({
    super.key,
    required this.postId,
    required this.collection,
    required this.documentId,
  });

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

    await CommentService.addComment(
      collection: widget.collection,
      documentId: widget.documentId,
      text: text,
    );

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
                stream: CommentService.getComments(
                  collection: widget.collection,
                  documentId: widget.documentId,
                ),

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
