import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, provider, admin }

class UserModel {
  final String id;
  final String name;
  final String phone; // stored encrypted, never sent to client until agreed
  final UserRole role;
  final double rating;
  final int totalJobs;
  final String? profilePic;
  final bool isBlocked;
  final String language; // 'en' | 'ur'
  final bool isVisibleOnline;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.rating = 5.0,
    this.totalJobs = 0,
    this.profilePic,
    this.isBlocked = false,
    this.language = 'en',
    this.isVisibleOnline = true,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == (d['role'] ?? 'customer'),
        orElse: () => UserRole.customer,
      ),
      rating: (d['rating'] ?? 5.0).toDouble(),
      totalJobs: d['totalJobs'] ?? 0,
      profilePic: d['profilePic'],
      isBlocked: d['isBlocked'] ?? false,
      language: d['language'] ?? 'en',
      isVisibleOnline: d['isVisibleOnline'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'role': role.name,
        'rating': rating,
        'totalJobs': totalJobs,
        'profilePic': profilePic,
        'isBlocked': isBlocked,
        'language': language,
        'isVisibleOnline': isVisibleOnline,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  // Masked phone for display before agreement
  String get maskedPhone {
    if (phone.length < 11) return '03XX-XXXXXXX';
    return '${phone.substring(0, 4)}-XXXXXXX';
  }

  bool get isLowRated => rating < 2.0 && totalJobs >= 3;

  UserModel copyWith({
    String? name,
    double? rating,
    int? totalJobs,
    String? profilePic,
    bool? isBlocked,
    String? language,
    bool? isVisibleOnline,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        phone: phone,
        role: role,
        rating: rating ?? this.rating,
        totalJobs: totalJobs ?? this.totalJobs,
        profilePic: profilePic ?? this.profilePic,
        isBlocked: isBlocked ?? this.isBlocked,
        language: language ?? this.language,
        isVisibleOnline: isVisibleOnline ?? this.isVisibleOnline,
        createdAt: createdAt,
      );
}
