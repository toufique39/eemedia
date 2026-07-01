import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/services/notification_service.dart';

class ChatService {
  // Generate unique chat ID
  static String getChatId(String user1, String user2) {
    final ids = [user1, user2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Create chat if not exists
  static Future<String> createChatIfNotExists({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final chatId = getChatId(currentUserId, otherUserId);

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': '',
      });
    }

    return chatId;
  }

  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final firestore = FirebaseFirestore.instance;

    // Save message
    await firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update chat metadata
    await firestore.collection('chats').doc(chatId).update({
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    });

    // Get participants
    final chatDoc = await firestore.collection('chats').doc(chatId).get();

    final chatData = chatDoc.data() as Map<String, dynamic>;

    final participants = List<String>.from(chatData['participants']);

    // Find receiver
    final receiverId = participants.firstWhere((id) => id != senderId);

    // Get sender name
    final senderDoc = await firestore.collection('users').doc(senderId).get();

    final senderData = senderDoc.data() ?? {};

    final senderName = senderData['name'] ?? senderData['email'] ?? 'Someone';

    // Create notification
    await createMessageNotification(
      receiverId: receiverId,
      senderName: senderName,
      chatId: chatId,
    );
  }
}
