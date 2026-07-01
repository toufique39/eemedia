import 'package:eemedia/features/auth/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Users")),

      body: Column(
        children: [
          // 🔍 SEARCH FIELD
          Padding(
            padding: const EdgeInsets.all(12),

            child: TextField(
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;

                final filteredUsers = users.where((user) {
                  final data = user.data() as Map<String, dynamic>;

                  final name = (data['name'] ?? "").toString().toLowerCase();

                  final username = (data['username'] ?? "")
                      .toString()
                      .toLowerCase();

                  return name.contains(searchText) ||
                      username.contains(searchText);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,

                  itemBuilder: (context, index) {
                    final data =
                        filteredUsers[index].data() as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          "https://ui-avatars.com/api/?name=${data['name']}&background=random",
                        ),
                      ),

                      title: Text(data['name'] ?? ""),

                      subtitle: Text("@${data['username'] ?? ''}"),

                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                      onTap: () {
                        // Next step: navigate to profile
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                              userId: filteredUsers[index].id,
                              userData: data,
                            ),
                          ),
                        );
                      },
                    );
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
