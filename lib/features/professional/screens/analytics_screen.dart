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
                title: "Reactions",
                value: "${data['totalReactions']}",
                icon: Icons.emoji_emotions,
              ),

              AnalyticsCard(
                title: "❤️ Love",
                value: "${data['love']}",
                icon: Icons.favorite,
              ),

              AnalyticsCard(
                title: "👍 Like",
                value: "${data['like']}",
                icon: Icons.thumb_up,
              ),

              AnalyticsCard(
                title: "🤣 Haha",
                value: "${data['haha']}",
                icon: Icons.sentiment_very_satisfied,
              ),

              AnalyticsCard(
                title: "😮 Wow",
                value: "${data['wow']}",
                icon: Icons.emoji_emotions_outlined,
              ),

              AnalyticsCard(
                title: "😢 Sad",
                value: "${data['sad']}",
                icon: Icons.sentiment_dissatisfied,
              ),

              AnalyticsCard(
                title: "😡 Angry",
                value: "${data['angry']}",
                icon: Icons.mood_bad,
              ),

              AnalyticsCard(
                title: "🐥 Polti",
                value: "${data['polti']}",
                icon: Icons.pets,
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
