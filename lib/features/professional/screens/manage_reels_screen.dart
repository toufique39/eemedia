import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/features/professional/widgets/reel_management_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageReelsScreen extends StatelessWidget {
  const ManageReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Reels")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reels")
            .where("userId", isEqualTo: uid)
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("You haven't uploaded any reels yet."),
            );
          }

          final reels = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reels.length,

            itemBuilder: (context, index) {
              final reel = reels[index];

              return ReelManagementCard(
                reelId: reel.id,
                reelData: reel.data() as Map<String, dynamic>,
              );
            },
          );
        },
      ),
    );
  }
}
