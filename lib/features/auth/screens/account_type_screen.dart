import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Account Type")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Choose Your Account Type",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            // Student
            GestureDetector(
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                // Update the user's account type in Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .set({'accountType': 'student'});
                Navigator.pushReplacementNamed(context, '/student-level');
              },
              child: Card(
                elevation: 40,
                child: ListView(
                  shrinkWrap: true,
                  children: const [
                    ListTile(
                      leading: Icon(Icons.school, size: 40),

                      title: Text(
                        "Student Account",
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Text(
                        "This is perfect for students looking to learn and grow!",
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Professional
            GestureDetector(
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                // Update the user's account type in Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .set({'accountType': 'professional'});
                Navigator.pushReplacementNamed(
                  context,
                  '/professional-dashboard',
                );
              },
              child: Card(
                elevation: 40,
                child: ListView(
                  shrinkWrap: true,
                  children: const [
                    ListTile(
                      leading: Icon(Icons.work, size: 40),
                      title: Text(
                        "Professional Account",
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Text(
                        "Access professional tools and resources!",
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
