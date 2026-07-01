import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:eemedia/services/supabase_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  File? selectedImage;
  Uint8List? webImage;
  File? selectedVideo;
  Uint8List? webVideo;
  String? selectedCategory;
  String? selectedSubCategory;

  final List<String> reelCategories = [
    'Education',

    'Entertainment',

    'News',

    'Technology',

    'Sports',

    'Gaming',

    'Business',

    'Health',

    'Motivation',

    'Religion',
  ];
  final Map<String, List<String>> subCategories = {
    'Education': [
      'School',
      'College',
      'University',
      'Programming',
      'AI',
      'IoT',
      'Robotics',
      'Math',
      'Physics',
    ],

    'Entertainment': ['Funny', 'Movies', 'Music', 'Prank', 'Memes'],

    'News': [
      'Local News',
      'International News',
      'Technology News',
      'Sports News',
    ],

    'Technology': ['AI', 'Programming', 'Cyber Security', 'Gadgets'],

    'Sports': ['Football', 'Cricket', 'Badminton', 'Esports'],

    'Gaming': ['PUBG', 'Free Fire', 'Valorant', 'PC Gaming'],

    'Business': ['Startup', 'Marketing', 'Finance'],

    'Health': ['Fitness', 'Nutrition', 'Mental Health'],

    'Motivation': ['Study Motivation', 'Career', 'Life Advice'],

    'Religion': ['Islamic', 'Quran', 'Hadith'],
  };
  Future<File?> _compressVideo(File videoFile) async {
    try {
      final MediaInfo? info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      return info?.file;
    } catch (e) {
      debugPrint('Compress error: $e');
      return null;
    }
  }

  final ImagePicker picker = ImagePicker();
  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        webImage = bytes;
        selectedImage = null;
        webVideo = null;
        selectedVideo = null;
      });
    } else {
      setState(() {
        selectedImage = File(pickedFile.path);

        webImage = null;
        webVideo = null;
        selectedVideo = null;
      });
    }
  }

  Future<void> pickVideo() async {
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile == null) return;

    // ✅ compress করো আগে
    final compressed = await _compressVideo(File(pickedFile.path));

    setState(() {
      selectedVideo = compressed ?? File(pickedFile.path);
    });
  }

  Future<void> uploadReel() async {
    if (selectedVideo == null && webVideo == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String videoUrl = '';

      if (kIsWeb && webVideo != null) {
        videoUrl =
            await SupabaseStorageService.uploadWebReelVideo(webVideo!) ?? '';
      } else if (selectedVideo != null) {
        videoUrl =
            await SupabaseStorageService.uploadReelVideo(selectedVideo!) ?? '';
      }

      if (videoUrl.isEmpty) {
        throw Exception('Video upload failed');
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reel uploaded')));

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

  Future<void> createPost() async {
    if (_controller.text.trim().isEmpty &&
        selectedImage == null &&
        selectedVideo == null) {
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
      String videoUrl = '';

      if (kIsWeb && webImage != null) {
        final uploadedUrl = await SupabaseStorageService.uploadWebImage(
          webImage!,
        );

        imageUrl = uploadedUrl ?? '';
      } else if (selectedImage != null) {
        final uploadedUrl = await SupabaseStorageService.uploadPostImage(
          selectedImage!,
        );

        imageUrl = uploadedUrl ?? '';
      }

      if (kIsWeb && webVideo != null) {
        final uploadedUrl = await SupabaseStorageService.uploadWebReelVideo(
          webVideo!,
        );

        videoUrl = uploadedUrl ?? '';
      } else if (selectedVideo != null) {
        final uploadedUrl = await SupabaseStorageService.uploadReelVideo(
          selectedVideo!,
        );

        videoUrl = uploadedUrl ?? '';
      }

      if (selectedVideo != null || webVideo != null) {
        await FirebaseFirestore.instance.collection('reels').add({
          'category': selectedCategory,
          'subCategory': selectedSubCategory,
          'userId': currentUser.uid,
          'userData': currentUserData,
          'caption': _controller.text.trim(),
          'videoUrl': videoUrl,
          'likes': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('posts').add({
          'userId': currentUser.uid,
          'userData': currentUserData,
          'content': _controller.text.trim(),
          'imageUrl': imageUrl,
          'reactions': {},
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      _controller.clear();

      setState(() {
        selectedImage = null;
        selectedVideo = null;
        webImage = null;
        webVideo = null;
      });

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post created successfully!")),
        );
      }
    } catch (e) {
      debugPrint('CREATE POST ERROR: $e');
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

  void mysnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            children: [
              TextField(
                controller: _controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedCategory,

                decoration: const InputDecoration(
                  labelText: 'Select Reel Category',

                  border: OutlineInputBorder(),
                ),

                items: reelCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),

              if (selectedCategory != null) ...[
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: selectedSubCategory,

                  decoration: const InputDecoration(
                    labelText: 'Select Sub Category',
                    border: OutlineInputBorder(),
                  ),

                  items: subCategories[selectedCategory]!.map((sub) {
                    return DropdownMenuItem(value: sub, child: Text(sub));
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      selectedCategory = null;
                      selectedSubCategory = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 10),
              if (kIsWeb && webImage != null)
                Image.memory(
                  webImage!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else if (selectedImage != null)
                Image.file(
                  selectedImage!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: pickImage,

                icon: const Icon(Icons.photo),
                iconAlignment: IconAlignment.start,

                label: const Text("Add Photo"),
              ),

              SafeArea(child: const SizedBox(height: 10)),

              if (kIsWeb && webVideo != null && selectedSubCategory != null)
                SafeArea(
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.black12,
                    child: const Center(child: Text("Video selected")),
                  ),
                )
              else if (selectedVideo != null && selectedSubCategory != null)
                SafeArea(
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.black12,
                    child: const Center(child: Text("Video selected")),
                  ),
                ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: pickVideo,

                icon: const Icon(Icons.videocam),
                iconAlignment: IconAlignment.start,

                label: const Text("Add Video"),
              ),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (_controller.text.trim().isEmpty &&
                              selectedImage == null &&
                              selectedVideo != null &&
                              webImage == null &&
                              webVideo != null &&
                              selectedSubCategory != null) {
                            mysnackbar(
                              "Please add some content and select a category",
                            );
                            return;
                          } else {
                            createPost();
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          selectedVideo != null || webVideo != null
                              ? "Upload Reel"
                              : "Post",
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
