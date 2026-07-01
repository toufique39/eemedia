import 'package:eemedia/features/auth/screens/presence_service.dart';
import 'package:eemedia/features/home/widgets/story_strip.dart';
import 'package:eemedia/services/story_cleanup_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/features/home/widgets/post_card.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  Map<String, dynamic>? currentUserData;

  bool isLoadingUser = true;
  @override
  void initState() {
    super.initState();

    StoryCleanupService.cleanupExpiredStories();

    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      setState(() {
        currentUserData = doc.data();
        isLoadingUser = false;
      });
    } catch (e) {
      debugPrint('Load User Error: $e');

      if (!mounted) return;

      setState(() {
        isLoadingUser = false;
      });
    }
  }

  String get accountType => currentUserData?['accountType'] ?? 'student';

  bool get isStudent => accountType == 'student';

  bool get isProfessional => accountType == 'professional';

  String get userName => currentUserData?['name'] ?? '';

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  Stream<QuerySnapshot> getPosts() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final uid = userId;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("EEmedia (${accountType.toUpperCase()})"),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('messages')
                .where('receiverId', isEqualTo: uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;

              if (snapshot.hasData) {
                final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  if (data['senderId'] != currentUserId) {
                    unreadCount++;
                  }
                }
              }

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () {
                      Navigator.pushNamed(context, '/chat-list');
                    },
                  ),

                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people_outline_sharp),
            onPressed: () {
              Navigator.pushNamed(context, '/friends');
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where(
                  'receiverId',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                )
                .where('isRead', isEqualTo: false)
                .snapshots(),

            builder: (context, snapshot) {
              int count = 0;

              if (snapshot.hasData) {
                count = snapshot.data!.docs.length;
              }

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),

                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),

                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,

                      child: Container(
                        padding: const EdgeInsets.all(4),

                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),

                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),

                        child: Text(
                          count.toString(),

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),

                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-post');
        },
        child: const Icon(Icons.add),
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "EEmedia",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isStudent ? "🎓 Student" : "💼 Professional",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                // Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),

              onTap: () async {
                await PresenceService.setOffline();
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),

          const StoryStrip(),

          const Divider(height: 1, thickness: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getPosts(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No posts yet"));
                }
                final posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final data = posts[index].data() as Map<String, dynamic>;
                    return PostCard(postId: posts[index].id, data: data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.search, color: Colors.black),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library, color: Colors.black),
            label: "Reels",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            label: "Profile",
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            return; // Already on home
          } else if (index == 1) {
            Navigator.pushNamed(context, '/search');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/reels');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
      backgroundColor: Colors.white,
    );
  }
}
