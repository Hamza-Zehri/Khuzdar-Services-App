import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String jobId;
  final double rating; // 1.0 – 5.0
  final String? comment;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.jobId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RatingModel(
      id: doc.id,
      fromUserId: d['fromUserId'] ?? '',
      toUserId: d['toUserId'] ?? '',
      jobId: d['jobId'] ?? '',
      rating: (d['rating'] ?? 5.0).toDouble(),
      comment: d['comment'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'jobId': jobId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
