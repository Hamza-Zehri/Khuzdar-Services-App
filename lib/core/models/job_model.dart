import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus { active, completed, cancelled }

class JobModel {
  final String id;
  final String chatId;
  final String userId;
  final String providerId;
  final JobStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  const JobModel({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.providerId,
    this.status = JobStatus.active,
    required this.createdAt,
    this.completedAt,
  });

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      chatId: d['chatId'] ?? '',
      userId: d['userId'] ?? '',
      providerId: d['providerId'] ?? '',
      status: JobStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'active'),
        orElse: () => JobStatus.active,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'chatId': chatId,
        'userId': userId,
        'providerId': providerId,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };
}
