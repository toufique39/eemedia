import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  String errorMessage = '';

  Future<void> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      errorMessage = '';
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "Login Failed";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔥 Save basic user data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'Name': 'Name',
            'email': 'email',
            'accountType': '', // initially empty
          });

      errorMessage = '';
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "Registration Failed";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      isLoading = true;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      errorMessage = '';
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "Failed to send password reset email";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getAccountType(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists && doc.data()!.containsKey('accountType')) {
      return doc['accountType'];
    }
    return null;
  }
}

Future<void> saveStudentLevel(String uid, String level) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'studentLevel': level,
  });
}

Future<String?> getStudentLevel(String uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();

  if (doc.exists && doc.data()!.containsKey('studentLevel')) {
    return doc['studentLevel'];
  }
  return null;
}

Future<void> saveScreenType(String uid, String type) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'screenType': type,
  });
}

Future<String?> getScreenType(String uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();

  if (doc.exists && doc.data()!.containsKey('screenType')) {
    return doc['screenType'];
  }
  return null;
}

Future<void> toggleLike(String postId, List likes) async {
  final user = FirebaseAuth.instance.currentUser;
  final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

  if (likes.contains(user!.uid)) {
    // unlike
    await postRef.update({
      'likes': FieldValue.arrayRemove([user.uid]),
      'likesCount': FieldValue.increment(-1),
    });
  } else {
    // like
    await postRef.update({
      'likes': FieldValue.arrayUnion([user.uid]),
      'likesCount': FieldValue.increment(1),
    });
  }
}
