import 'package:eemedia/features/home/student_home_screen.dart';
import 'package:eemedia/services/create_account_service.dart';
import 'package:flutter/material.dart';

class ProfessionalDetailsScreen extends StatefulWidget {
  final String name;
  final String username;
  final String email;
  final String password;

  const ProfessionalDetailsScreen({
    super.key,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  State<ProfessionalDetailsScreen> createState() =>
      _ProfessionalDetailsScreenState();
}

class _ProfessionalDetailsScreenState extends State<ProfessionalDetailsScreen> {
  final professionController = TextEditingController();

  final organizationController = TextEditingController();

  final jobTitleController = TextEditingController();

  @override
  void dispose() {
    professionController.dispose();
    organizationController.dispose();
    jobTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Professional Details")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextFormField(
              controller: professionController,

              decoration: const InputDecoration(
                labelText: "Profession",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: organizationController,

              decoration: const InputDecoration(
                labelText: "Organization / Company",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: jobTitleController,

              decoration: const InputDecoration(
                labelText: "Job Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () async {
                  if (professionController.text.trim().isEmpty) {
                    return;
                  }

                  if (organizationController.text.trim().isEmpty) {
                    return;
                  }

                  if (jobTitleController.text.trim().isEmpty) {
                    return;
                  }
                  await CreateAccountService.createAccount(
                    name: widget.name,
                    username: widget.username,
                    email: widget.email,
                    password: widget.password,
                    accountType: "professional",
                    profession: professionController.text.trim(),
                    organization: organizationController.text.trim(),
                    jobTitle: jobTitleController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentHomeScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },

                child: const Text("Create Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
