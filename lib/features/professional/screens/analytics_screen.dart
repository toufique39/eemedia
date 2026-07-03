import 'package:eemedia/services/professional_dashboard_service.dart';
import 'package:eemedia/features/professional/widgets/analytics_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),

      body: FutureBuilder<Map<String, dynamic>>(
        future: ProfessionalDashboardService.getAnalytics(uid),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return GridView.count(
            padding: const EdgeInsets.all(16),

            crossAxisCount: 2,

            crossAxisSpacing: 12,

            mainAxisSpacing: 12,

            children: [
              AnalyticsCard(
                title: "Posts",
                value: "${data['posts']}",
                icon: Icons.article,
              ),

              AnalyticsCard(
                title: "Reels",
                value: "${data['reels']}",
                icon: Icons.video_library,
              ),

              AnalyticsCard(
                title: "Likes",
                value: "${data['likes']}",
                icon: Icons.favorite,
              ),

              AnalyticsCard(
                title: "Views",
                value: "${data['views']}",
                icon: Icons.remove_red_eye,
              ),
            ],
          );
        },
      ),
    );
  }
}
