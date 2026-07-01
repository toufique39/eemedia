import 'package:eemedia/services/education_mapping_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  final institutionController = TextEditingController();
  final sessionController = TextEditingController();
  final departmentController = TextEditingController();

  final professionController = TextEditingController();
  final organizationController = TextEditingController();
  final jobTitleController = TextEditingController();

  String? selectedEducation;
  String? selectedDepartment;
  String accountType = 'student';
  bool isLoading = false;

  final List<String> educationLevels = [
    'school',
    'college',
    'university',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    bioController.dispose();
    institutionController.dispose();
    sessionController.dispose();
    professionController.dispose();
    organizationController.dispose();
    jobTitleController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    // ✅ null safe
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // ✅ document exist check
      if (!doc.exists || doc.data() == null) return;
      final data = doc.data()!;

      nameController.text = data['name'] ?? '';
      usernameController.text = data['username'] ?? '';
      bioController.text = data['bio'] ?? '';
      accountType = data['accountType'] ?? 'student';

      if (accountType == "student") {
        selectedEducation = data['studentLevel']
            ?.toString()
            .trim()
            .toLowerCase();
        institutionController.text = data['institution'] ?? '';
        selectedDepartment = data['department']?.toString().trim();
        sessionController.text = data['session'] ?? '';
      } else {
        professionController.text = data['profession'] ?? '';
        organizationController.text = data['organization'] ?? '';
        jobTitleController.text = data['jobTitle'] ?? '';
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Load profile error: $e');
    }
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Basic validation
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your ")));
      return;
    }

    if (usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your username")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final Map<String, dynamic> updateData = {
        'name': nameController.text.trim(),
        'username': usernameController.text.trim(),
        'bio': bioController.text.trim(),
      };

      if (accountType == "student") {
        updateData.addAll({
          'studentLevel': selectedEducation,
          'institution': institutionController.text.trim(),
          'department': selectedDepartment,
          'session': sessionController.text.trim(),
        });
      } else {
        updateData.addAll({
          'profession': professionController.text.trim(),
          'organization': organizationController.text.trim(),
          'jobTitle': jobTitleController.text.trim(),
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Save profile error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile. Try again.")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false); // ✅ loading শেষ
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      // ✅ SingleChildScrollView — keyboard overflow এড়াতে
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info
            const Text(
              "Basic Information",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Student Fields
            if (accountType == "student") ...[
              const Text(
                "Student Information",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

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
            ]
            // Professional Fields
            else ...[
              const Text(
                "Professional Information",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: professionController,
                decoration: const InputDecoration(
                  labelText: "Profession",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: organizationController,
                decoration: const InputDecoration(
                  labelText: "Organization / Company",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: jobTitleController,
                decoration: const InputDecoration(
                  labelText: "Job Title",
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Save Profile",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
