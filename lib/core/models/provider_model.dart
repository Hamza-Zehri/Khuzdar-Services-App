import 'package:cloud_firestore/cloud_firestore.dart';

enum ProviderType { individual, shop }

enum VerificationStatus { pending, approved, rejected }

enum ServiceCategory {
  electrician,
  plumber,
  tailor,
  teacher,
  carpenter,
  mechanic,
  painter,
  cleaner,
}

extension ServiceCategoryExtension on ServiceCategory {
  String get label => switch (this) {
        ServiceCategory.electrician => 'Electrician',
        ServiceCategory.plumber => 'Plumber',
        ServiceCategory.tailor => 'Tailor',
        ServiceCategory.teacher => 'Teacher',
        ServiceCategory.carpenter => 'Carpenter',
        ServiceCategory.mechanic => 'Mechanic',
        ServiceCategory.painter => 'Painter',
        ServiceCategory.cleaner => 'Cleaner',
      };

  String get emoji => switch (this) {
        ServiceCategory.electrician => '⚡',
        ServiceCategory.plumber => '🚿',
        ServiceCategory.tailor => '✂️',
        ServiceCategory.teacher => '📚',
        ServiceCategory.carpenter => '🪵',
        ServiceCategory.mechanic => '🔧',
        ServiceCategory.painter => '🖌️',
        ServiceCategory.cleaner => '🧹',
      };
}

class ShopInfo {
  final String shopName;
  final String shopAddress;

  const ShopInfo({required this.shopName, required this.shopAddress});

  factory ShopInfo.fromMap(Map<String, dynamic> m) =>
      ShopInfo(shopName: m['shopName'] ?? '', shopAddress: m['shopAddress'] ?? '');

  Map<String, dynamic> toMap() => {'shopName': shopName, 'shopAddress': shopAddress};
}

class ProviderModel {
  final String id;
  final String userId;
  final ProviderType type;
  final ServiceCategory category;
  final String area;
  final double rating;
  final int jobsCompleted;
  final VerificationStatus verificationStatus;
  final bool isAvailable;
  final ShopInfo? shop; // only for ProviderType.shop
  final String? profilePic;
  final DateTime createdAt;

  const ProviderModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.area,
    this.rating = 5.0,
    this.jobsCompleted = 0,
    this.verificationStatus = VerificationStatus.pending,
    this.isAvailable = true,
    this.shop,
    this.profilePic,
    required this.createdAt,
  });

  factory ProviderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProviderModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      type: ProviderType.values.firstWhere(
        (t) => t.name == (d['type'] ?? 'individual'),
        orElse: () => ProviderType.individual,
      ),
      category: ServiceCategory.values.firstWhere(
        (c) => c.name == (d['category'] ?? 'electrician'),
        orElse: () => ServiceCategory.electrician,
      ),
      area: d['area'] ?? '',
      rating: (d['rating'] ?? 5.0).toDouble(),
      jobsCompleted: d['jobsCompleted'] ?? 0,
      verificationStatus: VerificationStatus.values.firstWhere(
        (v) => v.name == (d['verificationStatus'] ?? 'pending'),
        orElse: () => VerificationStatus.pending,
      ),
      isAvailable: d['isAvailable'] ?? true,
      shop: d['shop'] != null ? ShopInfo.fromMap(d['shop']) : null,
      profilePic: d['profilePic'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type.name,
        'category': category.name,
        'area': area,
        'rating': rating,
        'jobsCompleted': jobsCompleted,
        'verificationStatus': verificationStatus.name,
        'isAvailable': isAvailable,
        'shop': shop?.toMap(),
        'profilePic': profilePic,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isApproved => verificationStatus == VerificationStatus.approved;

  ProviderModel copyWith({
    bool? isAvailable,
    double? rating,
    int? jobsCompleted,
    VerificationStatus? verificationStatus,
    String? profilePic,
  }) =>
      ProviderModel(
        id: id,
        userId: userId,
        type: type,
        category: category,
        area: area,
        rating: rating ?? this.rating,
        jobsCompleted: jobsCompleted ?? this.jobsCompleted,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        isAvailable: isAvailable ?? this.isAvailable,
        shop: shop,
        profilePic: profilePic ?? this.profilePic,
        createdAt: createdAt,
      );
}
