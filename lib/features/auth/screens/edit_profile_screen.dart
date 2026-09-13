import 'package:eemedia/services/education_mapping_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eemedia/services/supabase_storage_service.dart';
import 'dart:typed_data';

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
  XFile? _profileImage;
  XFile? _coverImage;

  String? _oldProfileImageUrl;
  String? _oldCoverImageUrl;

  Uint8List? _profileImageBytes;
  Uint8List? _coverImageBytes;


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
    // old image URLs will be loaded from Firestore below
    // ✅ null safe
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) return;
      final data = doc.data()!;

      // store previous image urls
      _oldProfileImageUrl = data['profileImage']?.toString();
      _oldCoverImageUrl = data['coverImage']?.toString();
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
      ).showSnackBar(const SnackBar(content: Text("Please enter your name")));
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
      String? profileImageUrl;
      String? coverImageUrl;

      if (_profileImage != null && _profileImageBytes != null) {
        setState(() {});

        profileImageUrl = await SupabaseStorageService.uploadProfileImageBytes(
          _profileImageBytes!,
        );

        setState(() {});

        if (profileImageUrl == null) {
          throw Exception("Profile image upload failed");
        }

        if (_oldProfileImageUrl != null && _oldProfileImageUrl!.isNotEmpty) {
          await SupabaseStorageService.deleteProfileImage(_oldProfileImageUrl!);
        }
      }

      if (_coverImage != null && _coverImageBytes != null) {
        setState(() {});

        coverImageUrl = await SupabaseStorageService.uploadCoverImageBytes(
          _coverImageBytes!,
        );

        setState(() {});

        if (coverImageUrl == null) {
          throw Exception("Cover image upload failed");
        }
        if (_oldCoverImageUrl != null && _oldCoverImageUrl!.isNotEmpty) {
          await SupabaseStorageService.deleteCoverImage(_oldCoverImageUrl!);
        }
      }

      final Map<String, dynamic> updateData = {
        'name': nameController.text.trim(),
        'username': usernameController.text.trim(),
        'bio': bioController.text.trim(),
      };

      if (profileImageUrl != null) {
        updateData['profileImage'] = profileImageUrl;
      }

      if (coverImageUrl != null) {
        updateData['coverImage'] = coverImageUrl;
      }

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update profile: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _profileImage = picked;
      _profileImageBytes = bytes;
    });
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _coverImage = picked;
      _coverImageBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Profile Photos",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: _pickCoverImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                        image: _coverImageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_coverImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _coverImageBytes != null
                          ? Image.memory(
                              _coverImageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                            )
                          : const Center(
                              child: Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),

                  Positioned(
                    left: 20,
                    bottom: -35,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: _profileImageBytes != null
                            ? MemoryImage(_profileImageBytes!)
                            : null,
                        child: _profileImageBytes == null
                            ? const Icon(Icons.person, size: 35)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 55),
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
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(dept),
                          );
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
      ),
    );
  }
}
