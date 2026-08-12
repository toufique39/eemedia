import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final double radius;

  const UserAvatar({super.key, required this.userId, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),

      builder: (context, snapshot) {
        String? imageUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();

          imageUrl = data?['profileImage']?.toString();

          if (imageUrl != null && imageUrl.isEmpty) {
            imageUrl = null;
          }
        }

        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null
              ? Icon(Icons.person, size: radius, color: Colors.grey.shade700)
              : null,
        );
      },
    );
  }
}
