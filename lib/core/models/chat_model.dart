import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatStatus {
  requested,
  chatting,
  agreed,
  contactVisible,
  completed,
  cancelled,
}

class AgreementState {
  final bool userAgreed;
  final bool providerAgreed;
  final bool contactVisible;

  const AgreementState({
    this.userAgreed = false,
    this.providerAgreed = false,
    this.contactVisible = false,
  });

  bool get bothAgreed => userAgreed && providerAgreed;

  factory AgreementState.fromMap(Map<String, dynamic> m) => AgreementState(
        userAgreed: m['userAgreed'] ?? false,
        providerAgreed: m['providerAgreed'] ?? false,
        contactVisible: m['contactVisible'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'userAgreed': userAgreed,
        'providerAgreed': providerAgreed,
        'contactVisible': contactVisible,
      };

  AgreementState copyWith({bool? userAgreed, bool? providerAgreed, bool? contactVisible}) =>
      AgreementState(
        userAgreed: userAgreed ?? this.userAgreed,
        providerAgreed: providerAgreed ?? this.providerAgreed,
        contactVisible: contactVisible ?? this.contactVisible,
      );
}

class ChatModel {
  final String id;
  final String userId;
  final String providerId;
  final ChatStatus status;
  final AgreementState agreement;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;

  const ChatModel({
    required this.id,
    required this.userId,
    required this.providerId,
    this.status = ChatStatus.requested,
    this.agreement = const AgreementState(),
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      providerId: d['providerId'] ?? '',
      status: ChatStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'requested'),
        orElse: () => ChatStatus.requested,
      ),
      agreement: d['agreement'] != null
          ? AgreementState.fromMap(d['agreement'])
          : const AgreementState(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessage: d['lastMessage'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'providerId': providerId,
        'status': status.name,
        'agreement': agreement.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
        'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
        'lastMessage': lastMessage,
      };

  ChatModel copyWith({
    ChatStatus? status,
    AgreementState? agreement,
    DateTime? lastMessageAt,
    String? lastMessage,
  }) =>
      ChatModel(
        id: id,
        userId: userId,
        providerId: providerId,
        status: status ?? this.status,
        agreement: agreement ?? this.agreement,
        createdAt: createdAt,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessage: lastMessage ?? this.lastMessage,
      );
}
