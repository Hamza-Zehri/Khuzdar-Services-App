import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String message;
  final bool seen;
  final DateTime timestamp;
  final bool isQuickReply;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.message,
    this.seen = false,
    required this.timestamp,
    this.isQuickReply = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      message: d['message'] ?? '',
      seen: d['seen'] ?? false,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isQuickReply: d['isQuickReply'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'message': message,
        'seen': seen,
        'timestamp': Timestamp.fromDate(timestamp),
        'isQuickReply': isQuickReply,
      };
}
