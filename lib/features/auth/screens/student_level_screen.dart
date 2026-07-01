import 'package:eemedia/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class StudentLevelScreen extends StatelessWidget {
  const StudentLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Student Level"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            Center(
              child: const Text(
                "Choose Your Level",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 40),

            // School
            _buildOption(context, "school", Icons.school, authProvider),

            const SizedBox(height: 20),

            // College
            _buildOption(context, "college", Icons.menu_book, authProvider),

            const SizedBox(height: 20),

            // University
            _buildOption(
              context,
              "university",
              Icons.account_balance,
              authProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String level,
    IconData icon,
    MyAuthProvider authProvider,
  ) {
    return GestureDetector(
      onTap: () async {
        final user = FirebaseAuth.instance.currentUser;
        await saveStudentLevel(user!.uid, level);
        Navigator.pushReplacementNamed(context, '/student-home');
      },
      child: Card(
        elevation: 40,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 20),
              Text(level.toUpperCase(), style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
