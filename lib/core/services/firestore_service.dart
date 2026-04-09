import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/all_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Providers ──────────────────────────────

  Future<void> createProvider(ProviderModel provider) async {
    await _db.collection('providers').doc(provider.id).set(provider.toFirestore());
  }

  Stream<List<ProviderModel>> streamProvidersByCategory(ServiceCategory category) {
    return _db
        .collection('providers')
        .where('category', isEqualTo: category.name)
        .where('verificationStatus', isEqualTo: 'approved')
        .orderBy('isAvailable', descending: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProviderModel.fromFirestore).toList());
  }

  Future<void> toggleProviderAvailability(String providerId, bool isAvailable) async {
    await _db.collection('providers').doc(providerId).update({'isAvailable': isAvailable});
  }

  Future<void> updateProviderVerification(String providerId, VerificationStatus status) async {
    await _db
        .collection('providers')
        .doc(providerId)
        .update({'verificationStatus': status.name});
  }

  // ── Chats ──────────────────────────────────

  Future<ChatModel> startChat({
    required String userId,
    required String providerId,
  }) async {
    // Check if chat already exists between this pair
    final existing = await _db
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .where('providerId', isEqualTo: providerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return ChatModel.fromFirestore(existing.docs.first);
    }

    final chatId = _uuid.v4();
    final chat = ChatModel(
      id: chatId,
      userId: userId,
      providerId: providerId,
      createdAt: DateTime.now(),
    );
    await _db.collection('chats').doc(chatId).set(chat.toFirestore());
    return chat;
  }

  Stream<ChatModel?> streamChat(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snap) => snap.exists ? ChatModel.fromFirestore(snap) : null);
  }

  Stream<List<ChatModel>> streamUserChats(String userId) {
    return _db
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatModel.fromFirestore).toList());
  }

  Stream<List<ChatModel>> streamProviderChats(String providerId) {
    return _db
        .collection('chats')
        .where('providerId', isEqualTo: providerId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatModel.fromFirestore).toList());
  }

  // ── Messages ───────────────────────────────

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    bool isQuickReply = false,
  }) async {
    final msgId = _uuid.v4();
    final msg = MessageModel(
      id: msgId,
      senderId: senderId,
      message: message,
      timestamp: DateTime.now(),
      isQuickReply: isQuickReply,
    );

    final batch = _db.batch();

    // Add message to subcollection
    batch.set(
      _db.collection('chats').doc(chatId).collection('messages').doc(msgId),
      msg.toFirestore(),
    );

    // Update chat's last message + transition to CHATTING
    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessage': message,
      'lastMessageAt': Timestamp.fromDate(msg.timestamp),
      'status': ChatStatus.chatting.name,
    });

    await batch.commit();
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  Future<void> markMessagesSeen(String chatId, String viewerUid) async {
    final unseenQuery = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('seen', isEqualTo: false)
        .where('senderId', isNotEqualTo: viewerUid)
        .get();

    final batch = _db.batch();
    for (final doc in unseenQuery.docs) {
      batch.update(doc.reference, {'seen': true});
    }
    await batch.commit();
  }

  // ── Agreement state machine ─────────────────
  // State: REQUESTED → CHATTING → AGREED → CONTACT_VISIBLE → COMPLETED

  Future<void> setUserAgreed(String chatId) async {
    final snap = await _db.collection('chats').doc(chatId).get();
    final chat = ChatModel.fromFirestore(snap);
    final newAgreement = chat.agreement.copyWith(userAgreed: true);

    final update = <String, dynamic>{
      'agreement': newAgreement.toMap(),
    };

    if (newAgreement.bothAgreed) {
      update['status'] = ChatStatus.contactVisible.name;
      update['agreement.contactVisible'] = true;
    } else {
      update['status'] = ChatStatus.agreed.name;
    }

    await _db.collection('chats').doc(chatId).update(update);
  }

  Future<void> setProviderAgreed(String chatId) async {
    final snap = await _db.collection('chats').doc(chatId).get();
    final chat = ChatModel.fromFirestore(snap);
    final newAgreement = chat.agreement.copyWith(providerAgreed: true);

    final update = <String, dynamic>{
      'agreement': newAgreement.toMap(),
    };

    if (newAgreement.bothAgreed) {
      update['status'] = ChatStatus.contactVisible.name;
      update['agreement.contactVisible'] = true;
    } else {
      update['status'] = ChatStatus.agreed.name;
    }

    await _db.collection('chats').doc(chatId).update(update);
  }

  // ── Jobs ───────────────────────────────────

  Future<JobModel> createJob({
    required String chatId,
    required String userId,
    required String providerId,
  }) async {
    final jobId = _uuid.v4();
    final job = JobModel(
      id: jobId,
      chatId: chatId,
      userId: userId,
      providerId: providerId,
      createdAt: DateTime.now(),
    );
    await _db.collection('jobs').doc(jobId).set(job.toFirestore());
    return job;
  }

  Future<void> completeJob(String jobId) async {
    await _db.collection('jobs').doc(jobId).update({
      'status': JobStatus.completed.name,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Ratings ────────────────────────────────

  Future<void> submitRating({
    required String fromUserId,
    required String toUserId,
    required String jobId,
    required double rating,
    String? comment,
  }) async {
    final ratingId = _uuid.v4();
    final ratingObj = RatingModel(
      id: ratingId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      jobId: jobId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(_db.collection('ratings').doc(ratingId), ratingObj.toFirestore());

    // Recalculate average for the target user (Firestore transaction)
    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(toUserId);
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) return;

      final currentRating = (userSnap.data()?['rating'] ?? 5.0).toDouble();
      final totalJobs = (userSnap.data()?['totalJobs'] ?? 0) as int;
      final newTotal = totalJobs + 1;
      final newRating = ((currentRating * totalJobs) + rating) / newTotal;

      tx.update(userRef, {
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'totalJobs': newTotal,
      });

      // Also update provider's rating if toUser is a provider
      final providerQuery = await _db
          .collection('providers')
          .where('userId', isEqualTo: toUserId)
          .limit(1)
          .get();
      if (providerQuery.docs.isNotEmpty) {
        final providerRef = providerQuery.docs.first.reference;
        tx.update(providerRef, {
          'rating': double.parse(newRating.toStringAsFixed(1)),
          'jobsCompleted': newTotal,
        });
      }
    });
  }

  // ── Admin ──────────────────────────────────

  Future<void> blockUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isBlocked': true});
  }

  Future<void> unblockUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isBlocked': false});
  }

  Stream<List<ProviderModel>> streamPendingProviders() {
    return _db
        .collection('providers')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(ProviderModel.fromFirestore).toList());
  }
}
