import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAccountService {
  static Future<void> createAccount({
    required String name,
    required String username,
    required String email,
    required String password,
    required String accountType,

    // Student
    String? studentLevel,
    String? institution,
    String? department,
    String? session,

    // Professional
    String? profession,
    String? organization,
    String? jobTitle,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        // Basic
        "uid": uid,
        "name": name,
        "username": username,
        "email": email,

        // Account
        "accountType": accountType,

        // Student
        "studentLevel": studentLevel ?? "",
        "institution": institution ?? "",
        "department": department ?? "",
        "session": session ?? "",

        // Professional
        "profession": profession ?? "",
        "organization": organization ?? "",
        "jobTitle": jobTitle ?? "",

        // Profile
        "profileImage": "",
        "coverImage": "",
        "bio": "",

        // Social
        "followers": [],
        "following": [],

        // Status
        "isOnline": true,
        "lastSeen": FieldValue.serverTimestamp(),

        // Features
        "screenTimeEnabled": accountType == "student",
        "monetizationEnabled": false,

        "createdAt": FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception("Failed to create account: $e");
    }
  }
}
