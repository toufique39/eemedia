import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class ScreenTimeScreen extends StatelessWidget {
  const ScreenTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Screen Time Check")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Select Your Screen Usage Level",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            // HIGH
            _buildOption(context, "high", Colors.red, authProvider),

            const SizedBox(height: 20),

            // LOW
            _buildOption(context, "low", Colors.green, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String type,
    Color color,
    MyAuthProvider authProvider,
  ) {
    return GestureDetector(
      onTap: () async {
        final user = FirebaseAuth.instance.currentUser;

        await saveScreenType(user!.uid, type);

        Navigator.pushReplacementNamed(context, '/student_home');
      },
      child: Card(
        color: color.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              type.toUpperCase(),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
