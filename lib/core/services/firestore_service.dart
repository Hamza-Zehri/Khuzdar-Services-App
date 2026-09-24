import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/all_models.dart';

class FirestoreService {
  // ── Singleton ──────────────────────────────────────────
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Call once at app startup
  static void initializeSettings() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, // Disk cache for offline + speed
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ── Providers ──────────────────────────────

  Future<void> createProvider(ProviderModel provider) async {
    // Use userId as the document ID for 1:1 reliability
    await _db.collection('providers').doc(provider.userId).set(
          provider.toFirestore(),
          SetOptions(merge: true),
        );
  }

  Stream<List<CategoryModel>> streamCategories() {
    return _db
        .collection('categories')
        .where('isEnabled', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CategoryModel.fromFirestore(d)).toList());
  }

  Stream<List<ProviderModel>> streamProvidersByCategory(String categoryId) {
    // Single-field query only — avoids needing a composite Firestore index.
    // Approved filtering + sorting are done client-side.
    return _db
        .collection('providers')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(ProviderModel.fromFirestore)
          .where((p) => p.isApproved && !p.isBlocked)
          .toList();
      list.sort((a, b) => b.rating.compareTo(a.rating));
      return list;
    });
  }

  Future<void> toggleProviderAvailability(
      String providerId, bool isAvailable) async {
    await _db
        .collection('providers')
        .doc(providerId)
        .update({'isAvailable': isAvailable});
  }

  Stream<ProviderModel?> streamProvider(String uid) {
    return _db
        .collection('providers')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? ProviderModel.fromFirestore(snap) : null);
  }

  Future<void> updateProviderVerification(
      String providerId, VerificationStatus status) async {
    await _db
        .collection('providers')
        .doc(providerId)
        .update({'verificationStatus': status.name});
  }

  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    await _db.collection('users').doc(uid).update(fields);
  }

  Future<void> updateProviderFields(
      String uid, Map<String, dynamic> fields) async {
    await _db.collection('providers').doc(uid).update(fields);
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

    // A chat can only move to CHATTING after the provider ACCEPTS it.
    final chatSnap = await _db.collection('chats').doc(chatId).get();
    final chat = ChatModel.fromFirestore(chatSnap);
    final nextStatus = chat.status == ChatStatus.requested
        ? ChatStatus.requested
        : ChatStatus.chatting;

    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessage': message,
      'lastMessageAt': Timestamp.fromDate(msg.timestamp),
      'status': nextStatus.name,
    });

    await batch.commit();
  }

  /// Provider accepts a request → both can now chat.
  Future<void> acceptChat(String chatId) async {
    await updateChatStatus(chatId, ChatStatus.chatting);
  }

  /// Provider declines a request → chat is closed.
  Future<void> rejectChat(String chatId) async {
    await updateChatStatus(chatId, ChatStatus.cancelled);
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

  Future<void> updateChatStatus(String chatId, ChatStatus status) async {
    await _db.collection('chats').doc(chatId).update({'status': status.name});
  }

  // ── Jobs ───────────────────────────────────

  /// Idempotently creates + completes the job for a chat.
  /// Job document ID == chat ID so both parties can find it by chat.
  Future<String> completeJobForChat(String chatId) async {
    final chatSnap = await _db.collection('chats').doc(chatId).get();
    final chat = ChatModel.fromFirestore(chatSnap);

    final job = JobModel(
      id: chatId,
      chatId: chatId,
      userId: chat.userId,
      providerId: chat.providerId,
      status: JobStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
    await _db.collection('jobs').doc(chatId).set(job.toFirestore());
    await updateChatStatus(chatId, ChatStatus.completed);
    return chatId;
  }

  Future<JobModel?> getJob(String jobId) async {
    final snap = await _db.collection('jobs').doc(jobId).get();
    return snap.exists ? JobModel.fromFirestore(snap) : null;
  }

  // ── Ratings ────────────────────────────────

  Future<bool> hasUserRated(String jobId, String userId) async {
    final snap = await _db
        .collection('ratings')
        .where('jobId', isEqualTo: jobId)
        .where('fromUserId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Stream<List<RatingModel>> streamRatingsFor(String toUserId) {
    return _db
        .collection('ratings')
        .where('toUserId', isEqualTo: toUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(RatingModel.fromFirestore).toList());
  }

  Future<void> submitRating({
    required String fromUserId,
    required String toUserId,
    required String jobId,
    required double rating,
    String? comment,
  }) async {
    // Guard: only once per job
    if (await hasUserRated(jobId, fromUserId)) return;

    final ratingObj = RatingModel(
      id: _uuid.v4(),
      fromUserId: fromUserId,
      toUserId: toUserId,
      jobId: jobId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    await _db.collection('ratings').doc(ratingObj.id).set(ratingObj.toFirestore());

    // Recompute target stats (average + count) from all ratings
    await _recomputeTargetStats(toUserId);

    // Provider reputation check → auto-block if consistently bad
    await _checkProviderReputation(toUserId);

    // Client behaviour check → auto-block if giving unfair low reviews
    await _trackClientReview(fromUserId, rating);
  }

  /// Recomputes a target user's & provider's rating from stored ratings.
  /// Ratings written by blocked users are ignored (fairness).
  Future<void> _recomputeTargetStats(String toUserId) async {
    final ratingsSnap = await _db
        .collection('ratings')
        .where('toUserId', isEqualTo: toUserId)
        .get();

    // Exclude ratings from blocked users
    final authors = <String>{};
    for (final d in ratingsSnap.docs) {
      authors.add(RatingModel.fromFirestore(d).fromUserId);
    }
    final blockedAuthors = <String>{};
    for (final authorId in authors) {
      final authorSnap = await _db.collection('users').doc(authorId).get();
      if (authorSnap.exists && authorSnap.data()?['isBlocked'] == true) {
        blockedAuthors.add(authorId);
      }
    }

    double sum = 0;
    var count = 0;
    for (final d in ratingsSnap.docs) {
      final r = RatingModel.fromFirestore(d);
      if (blockedAuthors.contains(r.fromUserId)) continue;
      sum += r.rating;
      count++;
    }
    final avg = count == 0 ? 5.0 : double.parse((sum / count).toStringAsFixed(1));

    await _db.collection('users').doc(toUserId).update({
      'rating': avg,
      'totalJobs': count,
    });

    final providerQuery = await _db
        .collection('providers')
        .where('userId', isEqualTo: toUserId)
        .limit(1)
        .get();
    if (providerQuery.docs.isNotEmpty) {
      await providerQuery.docs.first.reference.update({
        'rating': avg,
        'jobsCompleted': count,
      });
    }
  }

  /// Auto-block a provider when average drops below 2★ after 3+ rated jobs.
  Future<void> _checkProviderReputation(String toUserId) async {
    final userSnap = await _db.collection('users').doc(toUserId).get();
    final rating = (userSnap.data()?['rating'] ?? 5.0).toDouble();
    final totalJobs = (userSnap.data()?['totalJobs'] ?? 0) as int;

    if (totalJobs >= 3 && rating < 2.0) {
      await _db.collection('users').doc(toUserId).update({
        'isBlocked': true,
        'blockReason': 'auto_provider_rating',
      });
      final providerQuery = await _db
          .collection('providers')
          .where('userId', isEqualTo: toUserId)
          .limit(1)
          .get();
      if (providerQuery.docs.isNotEmpty) {
        await providerQuery.docs.first.reference.update({'isBlocked': true});
      }
    }
  }

  /// Auto-block a client who gives 3+ unfair (1-2★) reviews.
  Future<void> _trackClientReview(String fromUserId, double rating) async {
    // Only counts when a client rates a provider low
    if (rating > 2) return;

    final userRef = _db.collection('users').doc(fromUserId);
    final userSnap = await userRef.get();
    if (!userSnap.exists || userSnap.data()?['role'] == 'provider') return;

    final badCount = ((userSnap.data()?['badReviewsGiven'] ?? 0) as int) + 1;
    await userRef.update({'badReviewsGiven': badCount});

    if (badCount >= 3) {
      await userRef.update({
        'isBlocked': true,
        'blockReason': 'auto_client_review',
      });
      // Restore ratings that this client unfairly gave
      final unfairSnap = await _db
          .collection('ratings')
          .where('fromUserId', isEqualTo: fromUserId)
          .where('rating', isLessThanOrEqualTo: 2)
          .get();
      final affected = <String>{};
      for (final d in unfairSnap.docs) {
        affected.add(RatingModel.fromFirestore(d).toUserId);
      }
      affected.remove(fromUserId);
      for (final uid in affected) {
        await _recomputeTargetStats(uid);
      }
    }
  }

  // ── Admin ──────────────────────────────────

  Future<void> blockUser(String userId, {String reason = 'admin'}) async {
    await _db.collection('users').doc(userId).update({
      'isBlocked': true,
      'blockReason': reason,
    });
    // Also block a matching provider profile
    final providerQuery = await _db
        .collection('providers')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (providerQuery.docs.isNotEmpty) {
      await providerQuery.docs.first.reference.update({'isBlocked': true});
    }
  }

  Future<void> unblockUser(String userId) async {
    await _db.collection('users').doc(userId).update({
      'isBlocked': false,
      'blockReason': null,
    });
    final providerQuery = await _db
        .collection('providers')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (providerQuery.docs.isNotEmpty) {
      await providerQuery.docs.first.reference.update({'isBlocked': false});
    }
  }

  Future<UserModel?> getUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists ? UserModel.fromFirestore(snap) : null;
  }

  Future<void> updateUserAddress(String uid, String address) async {
    await _db.collection('users').doc(uid).update({'address': address});
  }

  Stream<List<ProviderModel>> streamPendingProviders() {
    return _db
        .collection('providers')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(ProviderModel.fromFirestore).toList());
  }

  Stream<List<Map<String, dynamic>>> streamBroadcastJobs() {
    return _db
        .collection('broadcast_jobs')
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }
}
