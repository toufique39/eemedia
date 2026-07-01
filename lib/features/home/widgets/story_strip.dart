import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/features/auth/screens/create_story_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eemedia/features/auth/screens/story_viewer_screen.dart';

class StoryStrip extends StatelessWidget {
  const StoryStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,

      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .orderBy('expiresAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stories = snapshot.data!.docs;
          Map<String, List<QueryDocumentSnapshot>> groupedStories = {};

          for (final story in stories) {
            final data = story.data() as Map<String, dynamic>;

            final userId = data['userId'] as String?;
            if (userId == null) continue;
            groupedStories.putIfAbsent(userId, () => []);

            groupedStories[userId]!.add(story);
          }

          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final groupedList = groupedStories.entries.toList();
          groupedList.sort((a, b) {
            if (a.key == currentUserId) return -1;
            if (b.key == currentUserId) return 1;
            return 0;
          });

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: groupedList.length + 1,
            itemBuilder: (context, index) {
              // Your Story
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(8),

                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => const CreateStoryScreen(),
                        ),
                      );
                    },

                    child: Column(
                      children: [
                        Stack(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              child: Icon(Icons.person),
                            ),

                            Positioned(
                              bottom: 0,
                              right: 0,

                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),

                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        const Text('story', overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }

              final userStories = groupedList[index - 1].value;
              final story = userStories.first.data() as Map<String, dynamic>;
              final userData = story['userData'] ?? {};
              final storyImageUrl = story['imageUrl']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.all(8),

                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          stories: userStories
                              .map((doc) => doc.data() as Map<String, dynamic>)
                              .toList(),
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },

                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: storyImageUrl.isNotEmpty
                            ? NetworkImage(storyImageUrl)
                            : null,
                        child: storyImageUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        userData['name'] ==
                                FirebaseAuth.instance.currentUser?.displayName
                            ? "Your Story"
                            : '${userData['name'] ?? 'Unknown'} (${userStories.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
