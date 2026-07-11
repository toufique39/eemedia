import 'package:eemedia/features/home/student_home_screen.dart';
import 'package:eemedia/services/create_account_service.dart';
import 'package:eemedia/services/education_mapping_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String name;
  final String username;
  final String email;
  final String password;

  const StudentDetailsScreen({
    super.key,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  String? studentLevel;
  bool isLoading = false;

  final institutionController = TextEditingController();
  final departmentController = TextEditingController();
  final sessionController = TextEditingController();

  String? selectedEducation;
  String? selectedDepartment;

  final List<String> educationLevels = [
    'school',
    'college',
    'university',
    'other',
  ];

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleCreateAccount() async {
    setState(() => isLoading = true);
    // recong
    try {
      await CreateAccountService.createAccount(
        name: widget.name,
        username: widget.username,
        email: widget.email,
        password: widget.password,
        accountType: "student",
        studentLevel: educationLevels.contains(selectedEducation)
            ? selectedEducation
            : null,
        institution: institutionController.text.trim(),
        department:
            educationLevels.contains(selectedEducation) &&
                selectedDepartment != null
            ? selectedDepartment
            : null,
        session: sessionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code}');
    } catch (e) {
      debugPrint('Create account error: $e');
      if (mounted) {
        _showError("Account creation failed. Please try again.");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    institutionController.dispose();
    departmentController.dispose();
    sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Student Level",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: educationLevels.contains(selectedEducation)
                  ? selectedEducation
                  : null,
              decoration: const InputDecoration(
                labelText: 'Student Level',
                border: OutlineInputBorder(),
              ),
              items: educationLevels.map((level) {
                return DropdownMenuItem(
                  value: level,

                  child: Text(level[0].toUpperCase() + level.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedEducation = value;
                  selectedDepartment = null;
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: institutionController,
              decoration: const InputDecoration(
                labelText: "Institution",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (selectedEducation != null) ...[
              DropdownButtonFormField<String>(
                value: selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                items:
                    EducationMappingService.getDepartments(
                      selectedEducation!,
                    ).map((dept) {
                      return DropdownMenuItem(value: dept, child: Text(dept));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDepartment = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),

            TextField(
              controller: sessionController,
              decoration: const InputDecoration(
                labelText: "Session",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleCreateAccount,
                child: isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text("Create Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
