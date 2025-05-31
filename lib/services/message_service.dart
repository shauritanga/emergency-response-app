import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class MessageService {
  final CollectionReference _messages = FirebaseFirestore.instance.collection(
    'messages',
  );

  Stream<List<Message>> getUserMessages(String userId) {
    return _messages
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Message.fromMap(doc.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  Future<void> sendMessage({
    required String userId,
    required String title,
    required String body,
  }) async {
    final id = _messages.doc().id;

    await _messages.doc(id).set({
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    });
  }

  Future<void> markAsRead(String messageId) async {
    await _messages.doc(messageId).update({'isRead': true});
  }
}
