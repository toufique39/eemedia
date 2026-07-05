import 'package:eemedia/features/auth/screens/login_screen.dart';
import 'package:eemedia/features/auth/screens/presence_service.dart';
import 'package:eemedia/features/home/widgets/post_card.dart';
import 'package:eemedia/features/professional/screens/professional_dashboard_screen.dart';
import 'package:eemedia/services/screen_time_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLiked(List likes) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return likes.contains(userId);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final userData = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              PresenceService.setOffline();
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
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

      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: userData,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final accountType = (data["accountType"] ?? "student")
                  .toString()
                  .toLowerCase();

              final isStudent = accountType == "student";

              final isProfessional = accountType == 'professional';

              return Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      "https://ui-avatars.com/api/?name=${data['name'] ?? 'User'}&background=random",
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    data['name'] ?? "",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "@${data['username'] ?? ""}",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 5),
                  Text(
                    data['bio'] ?? "",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (isStudent)
                    FutureBuilder<List<int>>(
                      future: Future.wait([
                        ScreenTimeService.getEntertainmentSeconds(),
                        ScreenTimeService.getRemainingEntertainmentSeconds(),
                        Future.value(
                          ScreenTimeService.entertainmentLimitSeconds,
                        ),
                      ]),

                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        final used = snapshot.data![0];

                        final limit = snapshot.data![1];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),

                          elevation: 2,

                          child: Padding(
                            padding: const EdgeInsets.all(10),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.timer, color: Colors.orange),

                                    SizedBox(width: 5),

                                    Text(
                                      "Today's Entertainment",

                                      style: TextStyle(
                                        fontSize: 12,

                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 5),

                                LinearProgressIndicator(
                                  value: limit == 0 ? 0 : used / limit,
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  "Limit : ${ScreenTimeService.formatDuration(ScreenTimeService.entertainmentLimitSeconds)}",

                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/edit-profile');
                    },
                    child: Text(
                      isStudent
                          ? "Edit Student Profile"
                          : "Edit Professional Profile",
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (isProfessional) ...[
                    const SizedBox(height: 5),

                    SizedBox(
                      width: 220,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.dashboard),

                        label: Center(
                          child: const Text("Professional Dashboard"),
                        ),

                        onPressed: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) =>
                                  const ProfessionalDashboardScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 5),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isStudent) ...[
                            Row(
                              children: [
                                const Icon(Icons.school),
                                const SizedBox(width: 5),
                                Text(data['studentLevel'] ?? ''),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                const Icon(Icons.account_balance),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(data['institution'] ?? ''),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                const Icon(Icons.menu_book),
                                const SizedBox(width: 5),
                                Expanded(child: Text(data['department'] ?? '')),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 5),
                                Text(data['session'] ?? ''),
                              ],
                            ),
                          ],

                          if (isProfessional) ...[
                            Row(
                              children: [
                                const Icon(Icons.work),
                                const SizedBox(width: 5),
                                Expanded(child: Text(data['profession'] ?? '')),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                const Icon(Icons.business),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(data['organization'] ?? ''),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                const Icon(Icons.badge),
                                const SizedBox(width: 5),
                                Expanded(child: Text(data['jobTitle'] ?? '')),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
    );
  }
}
