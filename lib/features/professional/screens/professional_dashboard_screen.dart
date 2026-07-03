import 'package:eemedia/features/professional/screens/analytics_screen.dart';
import 'package:flutter/material.dart';

class ProfessionalDashboardScreen extends StatelessWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Professional Dashboard")),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text("Analytics"),
              subtitle: const Text("View account analytics"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.insights),
              title: const Text("Insights"),
              subtitle: const Text("Content performance"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text("Manage Reels"),
              subtitle: const Text("Manage your uploaded reels"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/manage-reels');
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.article),
              title: const Text("Manage Posts"),
              subtitle: const Text("Manage your posts"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text("Monetization"),
              subtitle: const Text("Coming Soon"),
              trailing: const Icon(Icons.lock_outline),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
