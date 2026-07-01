import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eemedia/services/supabase_storage_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? selectedImage;
  Uint8List? webImage;

  bool isLoading = false;

  final ImagePicker picker = ImagePicker();

  Future<void> pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();

      setState(() {
        webImage = bytes;
        selectedImage = null;
      });
    } else {
      setState(() {
        selectedImage = File(picked.path);
        webImage = null;
      });
    }
  }

  Future<void> uploadStory() async {
    if (selectedImage == null && webImage == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final currentUserData = userDoc.data() ?? {};

      String imageUrl = '';

      // Web Upload
      if (kIsWeb && webImage != null) {
        imageUrl =
            await SupabaseStorageService.uploadWebStoryImage(webImage!) ?? '';
      }
      // Android Upload
      else if (selectedImage != null) {
        imageUrl =
            await SupabaseStorageService.uploadStoryImage(selectedImage!) ?? '';
      }

      if (imageUrl.isEmpty) {
        throw Exception('Failed to upload image.');
      }

      await FirebaseFirestore.instance.collection('stories').add({
        'userId': currentUser.uid,

        'userData': currentUserData,

        'imageUrl': imageUrl,

        'createdAt': FieldValue.serverTimestamp(),

        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 10)),
        ),

        'seenBy': [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story uploaded successfully')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Story')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Builder(
                  builder: (_) {
                    if (kIsWeb && webImage != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),

                        child: Image.memory(
                          webImage!,

                          width: double.infinity,

                          fit: BoxFit.cover,
                        ),
                      );
                    }

                    if (selectedImage != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),

                        child: Image.file(
                          selectedImage!,

                          width: double.infinity,

                          fit: BoxFit.cover,
                        ),
                      );
                    }

                    return Container(
                      width: double.infinity,

                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,

                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: const Center(child: Text('No image selected')),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: pickImage,

                icon: const Icon(Icons.photo),

                label: const Text('Choose Story'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,

              height: 50,

              child: ElevatedButton(
                onPressed: isLoading ? null : uploadStory,

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Upload Story'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
