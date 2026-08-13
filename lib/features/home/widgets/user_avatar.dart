import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final double radius;
  final Color? fallbackColor;

  const UserAvatar({
    super.key,
    required this.userId,
    this.radius = 22,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: fallbackColor ?? Colors.grey.shade300,
        child: Icon(Icons.person, size: radius, color: Colors.grey.shade700),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        String? imageUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();

          final value = data?['profileImage']?.toString().trim();

          if (value != null && value.isNotEmpty) {
            imageUrl = value;
          }
        }

        return CircleAvatar(
          radius: radius,
          backgroundColor: fallbackColor ?? Colors.grey.shade300,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null
              ? Icon(Icons.person, size: radius, color: Colors.grey.shade700)
              : null,
        );
      },
    );
  }
}
