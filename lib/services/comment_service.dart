import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addComment({
    required String collection,
    required String documentId,
    required String text,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser!;

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final userData = userDoc.data() ?? {};

    await _firestore
        .collection(collection)
        .doc(documentId)
        .collection('comments')
        .add({
          "userId": currentUser.uid,
          "name": userData["name"] ?? "Unknown",
          "profileImage": userData["profileImage"] ?? "",
          "text": text,
          "createdAt": FieldValue.serverTimestamp(),
        });
  }

  static Stream<QuerySnapshot> getComments({
    required String collection,
    required String documentId,
  }) {
    return _firestore
        .collection(collection)
        .doc(documentId)
        .collection("comments")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  static Future<void> deleteComment({
    required String collection,
    required String documentId,
    required String commentId,
  }) async {
    await _firestore
        .collection(collection)
        .doc(documentId)
        .collection("comments")
        .doc(commentId)
        .delete();
  }

  static Future<void> updateComment({
    required String collection,
    required String documentId,
    required String commentId,
    required String newText,
  }) async {
    await _firestore
        .collection(collection)
        .doc(documentId)
        .collection("comments")
        .doc(commentId)
        .update({
          "text": newText,
          "edited": true,
          "updatedAt": FieldValue.serverTimestamp(),
        });
  }
}
