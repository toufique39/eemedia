import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/features/auth/screens/full_screen_image_screen.dart';
import 'package:eemedia/features/home/widgets/reaction_helper.dart';
import 'package:eemedia/features/home/widgets/reaction_picker.dart';
import 'package:eemedia/services/reaction_service.dart';
import 'package:eemedia/services/supabase_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eemedia/features/auth/screens/comment_screen.dart';

class PostCard extends StatefulWidget {
  final String postId;

  final Map<String, dynamic> data;

  const PostCard({super.key, required this.postId, required this.data});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  Future<void> toggleLike(String postId) async {
    await toggleReaction(
      collection: 'posts',
      documentId: postId,
      reaction: 'like',
    );
    setState(() {});
  }

  final List<Map<String, String>> reactionsList = [
    {'emoji': '👍', 'type': 'like'},

    {'emoji': '❤️', 'type': 'love'},

    {'emoji': '😮', 'type': 'wow'},

    {'emoji': '😢', 'type': 'sad'},

    {'emoji': '😡', 'type': 'angry'},
    {'emoji': '🤣', 'type': 'haha'},
    {'emoji': '🐥', 'type': 'polti'},
  ];

  Future<void> showReactionPicker() async {
    await showDialog(
      context: context,
      builder: (_) {
        return ReactionPicker(
          onReactionSelected: (reaction) async {
            await toggleReaction(
              collection: 'posts',
              documentId: widget.postId,
              reaction: reaction,
            );
          },
        );
      },
    );
  }

  void showPostMenu(bool isMyPost) {
    showModalBottomSheet(
      context: context,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              if (isMyPost) ...[
                ListTile(
                  leading: const Icon(Icons.edit),

                  title: const Text('Edit Post'),

                  onTap: () {
                    Navigator.pop(context);

                    showEditPostDialog();
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),

                  title: const Text(
                    'Delete Post',
                    style: TextStyle(color: Colors.red),
                  ),

                  onTap: () {
                    Navigator.pop(context);
                    showDeleteDialog();

                    // STEP-20D
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.flag),

                  title: const Text('Report Post'),

                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.hide_source),

                  title: const Text('Hide Post'),

                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> showEditPostDialog() async {
    final controller = TextEditingController(
      text: widget.data['content'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Edit Post'),

          content: TextField(
            controller: controller,
            maxLines: 30,
            decoration: const InputDecoration(
              hintText: "What's on your mind?",
              border: OutlineInputBorder(),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final newContent = controller.text.trim();

                if (newContent.isEmpty) {
                  return;
                }

                await updatePost(newContent);

                if (mounted) {
                  Navigator.pop(context);
                }
              },

              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updatePost(String content) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
            'content': content,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post updated')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> showDeleteDialog() async {
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Post'),

          content: const Text('Are you sure you want to delete this post?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

              onPressed: () {
                Navigator.pop(context);
                deletePost();
              },

              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deletePost() async {
    try {
      final imageUrl = widget.data['imageUrl'] as String?;

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .delete();

      if (imageUrl != null && imageUrl.toString().isNotEmpty) {
        await SupabaseStorageService.deletePostImage(imageUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final postOwnerId = widget.data['userId'] ?? '';

    final isMyPost = currentUserId == postOwnerId;

    final reactions = Map<String, dynamic>.from(widget.data['reactions'] ?? {});
    Map<String, int> reactionSummary = {};

    for (var reaction in reactions.values) {
      reactionSummary[reaction] = (reactionSummary[reaction] ?? 0) + 1;
    }
    final sortedReactions = reactionSummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topReactions = sortedReactions.take(3).map((e) => e.key).toList();
    final postUser = widget.data['userData'] as Map<String, dynamic>? ?? {};

    final postUserName = postUser['name'] ?? 'Unknown User';

    final postUsername = postUser['username'] ?? '';

    final isOnline = postUser['isOnline'] ?? false;
    final imageUrl = widget.data['imageUrl'] as String?;
    final hasValidImage =
        imageUrl != null &&
        imageUrl.trim().isNotEmpty &&
        imageUrl.startsWith('https://');

    String formatPostTime(dynamic timestamp) {
      if (timestamp == null) {
        return '';
      }

      final date = (timestamp as Timestamp).toDate();

      final now = DateTime.now();

      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }

    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 USER INFO
            ListTile(
              contentPadding: EdgeInsets.zero,

              leading: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  "https://ui-avatars.com/api/?name=$postUserName&background=random",
                ),
              ),

              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      postUserName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '${formatPostTime(widget.data['createdAt'])}'
                    '${widget.data['updatedAt'] != null ? ' · Edited' : ''}',

                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  IconButton(
                    icon: const Icon(Icons.more_horiz),

                    onPressed: () {
                      showPostMenu(isMyPost);
                    },
                  ),
                ],
              ),

              subtitle: Row(
                children: [
                  Text(
                    '@$postUsername',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    Icons.circle,
                    size: 10,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Post Content
            Text(
              widget.data['content'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),

            // 🔹 Post Image
            if (hasValidImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Hero(
                  tag: imageUrl,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              FullScreenImageScreen(imageUrl: imageUrl),
                        ),
                      );
                    },

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,

                        width: double.infinity,

                        height: 300,

                        fit: BoxFit.cover,

                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            if (topReactions.isNotEmpty) ...[
              const SizedBox(height: 10),

              Row(
                children: [
                  ...topReactions.map((reaction) {
                    return Container(
                      margin: const EdgeInsets.only(right: 4),

                      child: CircleAvatar(
                        radius: 10,

                        backgroundColor: Colors.white,

                        child: Text(
                          ReactionHelper.getReactionEmoji(reaction),

                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(width: 4),

                  Text(
                    '${reactions.length} ${reactions.length == 1 ? 'Reaction' : 'Reactions'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
            // 🔥 ACTION ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // ❤️ LIKE
                GestureDetector(
                  onTap: () async {
                    await toggleReaction(
                      collection: 'posts',
                      documentId: widget.postId,
                      reaction: 'like',
                    );
                  },

                  onLongPress: () {
                    showReactionPicker();
                  },

                  child: Row(
                    children: [
                      Text(
                        ReactionHelper.getReactionEmoji(
                          reactions[FirebaseAuth.instance.currentUser!.uid],
                        ),

                        style: const TextStyle(fontSize: 22),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        ReactionHelper.getReactionLabel(
                          reactions[FirebaseAuth.instance.currentUser!.uid],
                        ),

                        style: TextStyle(
                          color: ReactionHelper.getReactionColor(
                            reactions[FirebaseAuth.instance.currentUser!.uid],
                          ),

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Text('${reactions.length}'),
                    ],
                  ),
                ),
                // 💬 COMMENT
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,

                      isScrollControlled: true,

                      builder: (_) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,

                          child: CommentScreen(postId: widget.postId),
                        );
                      },
                    );
                  },

                  child: const Icon(Icons.comment_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
