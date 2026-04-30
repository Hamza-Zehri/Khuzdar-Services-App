import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String label;
  final String labelUrdu;
  final String emoji;
  final bool isEnabled;
  final int order;

  const CategoryModel({
    required this.id,
    required this.label,
    required this.labelUrdu,
    required this.emoji,
    this.isEnabled = true,
    this.order = 0,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      label: d['label'] ?? '',
      labelUrdu: d['labelUrdu'] ?? '',
      emoji: d['emoji'] ?? '📁',
      isEnabled: d['isEnabled'] ?? true,
      order: d['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'label': label,
        'labelUrdu': labelUrdu,
        'emoji': emoji,
        'isEnabled': isEnabled,
        'order': order,
      };

  CategoryModel copyWith({
    String? label,
    String? labelUrdu,
    String? emoji,
    bool? isEnabled,
    int? order,
  }) =>
      CategoryModel(
        id: id,
        label: label ?? this.label,
        labelUrdu: labelUrdu ?? this.labelUrdu,
        emoji: emoji ?? this.emoji,
        isEnabled: isEnabled ?? this.isEnabled,
        order: order ?? this.order,
      );
}
