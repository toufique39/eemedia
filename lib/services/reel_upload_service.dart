import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:eemedia/services/supabase_storage_service.dart';
import 'package:video_compress/video_compress.dart';

class ReelUploadService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isUploading = false;

  static Future<File> _compressVideo(File originalVideo) async {
    if (!originalVideo.existsSync()) {
      throw Exception("Selected video file does not exist.");
    }

    final fileSize = await originalVideo.length();

    if (fileSize == 0) {
      throw Exception("Video file is empty.");
    }
    try {
      final MediaInfo? info = await VideoCompress.compressVideo(
        originalVideo.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info == null || info.file == null) {
        throw Exception("Compression failed.");
      }

      return info.file!;
    } finally {
      VideoCompress.dispose();
    }
  }

  static Future<bool> uploadReel({
    required File videoFile,
    required String caption,
    required String category,
    required String subCategory,
  }) async {
    if (_isUploading) {
      throw Exception("Another upload is already in progress.");
    }

    _isUploading = true;
    try {
      //---------------------------------------------------
      // Current User
      //---------------------------------------------------

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception("User not logged in.");
      }

      //---------------------------------------------------
      // User Data
      //---------------------------------------------------

      final userDoc = await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data();

      if (userData == null) {
        throw Exception("User data not found.");
      }

      //---------------------------------------------------
      // Upload Video
      //---------------------------------------------------

      final compressedVideo = await _compressVideo(videoFile);
      final videoUrl = await SupabaseStorageService.uploadReelVideo(
        compressedVideo,
      );
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception("Video upload failed.");
      }

      debugPrint("VIDEO URL:");
      debugPrint(videoUrl);

      //---------------------------------------------------
      // Save Firestore
      //---------------------------------------------------

      final docRef = await _firestore.collection("reels").add({
        "userId": currentUser.uid,
        "uid": currentUser.uid,

        "caption": caption,

        "videoUrl": videoUrl,

        "category": category,

        "subCategory": subCategory,

        "thumbnailUrl": "",

        "views": 0,

        "likesCount": 0,

        "commentsCount": 0,

        "sharesCount": 0,

        "createdAt": FieldValue.serverTimestamp(),

        "updatedAt": FieldValue.serverTimestamp(),

        "userData": userData,
      });

      final verify = await docRef.get();

      if (!verify.exists) {
        throw Exception("Firestore save failed.");
      }

      debugPrint("REEL SAVED");

      return true;
    } catch (e, stackTrace) {
      debugPrint("========== REEL UPLOAD ERROR ==========");

      debugPrint(e.toString());

      debugPrint(stackTrace.toString());

      rethrow;
    } finally {
      _isUploading = false;
    }
  }

  static Future<void> uploadWebReel({
    required File videoFile,
    required String caption,
    required String category,
    required String subCategory,
  }) async {
    if (_isUploading) {
      throw Exception("Another upload is already in progress.");
    }

    _isUploading = true;
    try {
      //---------------------------------------------------
      // Current User
      //---------------------------------------------------

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception("User not logged in.");
      }

      //---------------------------------------------------
      // User Data
      //---------------------------------------------------

      final userDoc = await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data();

      if (userData == null) {
        throw Exception("User data not found.");
      }

      //---------------------------------------------------
      // Upload Video
      //---------------------------------------------------

      final videoUrl = await SupabaseStorageService.uploadReelVideo(videoFile);
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception("Video upload failed.");
      }

      debugPrint("VIDEO URL:");
      debugPrint(videoUrl);

      //---------------------------------------------------
      // Save Firestore
      //---------------------------------------------------

      final docRef = await _firestore.collection("reels").add({
        "userId": currentUser.uid,
        "uid": currentUser.uid,

        "caption": caption,

        "videoUrl": videoUrl,

        "category": category,

        "subCategory": subCategory,

        "thumbnailUrl": "",

        "views": 0,

        "likesCount": 0,

        "commentsCount": 0,

        "sharesCount": 0,

        "createdAt": FieldValue.serverTimestamp(),

        "updatedAt": FieldValue.serverTimestamp(),

        "userData": userData,
      });

      final verify = await docRef.get();

      if (!verify.exists) {
        throw Exception("Firestore save failed.");
      }

      debugPrint("REEL SAVED");
    } catch (e, stackTrace) {
      debugPrint("========== REEL UPLOAD ERROR ==========");

      debugPrint(e.toString());

      debugPrint(stackTrace.toString());

      rethrow;
    } finally {
      _isUploading = false;
    }
  }
}
