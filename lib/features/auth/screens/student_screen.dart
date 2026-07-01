import 'package:eemedia/features/home/data/dummy_posts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tracking_provider.dart';

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Student Feed")),
      body: Column(
        children: [
          Text("Fun Time: ${tracker.funTime} sec"),

          if (tracker.isBlocked)
            const Text(
              "⚠️ Funny content blocked! Educational mode active",
              style: TextStyle(color: Colors.red),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

                // block funny posts
                if (tracker.isBlocked && post.type == "funny") {
                  return const SizedBox();
                }

                return GestureDetector(
                  onTap: () {
                    tracker.startTracking(post.type);
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(post.title),
                      subtitle: Text(post.type),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
