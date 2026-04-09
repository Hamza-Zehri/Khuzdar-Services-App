import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this runs
  // Just handle the message silently or show a local notification
}

class MessagingService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'khuzdar_marketplace_channel';
  static const _channelName = 'Marketplace Notifications';

  Future<void> initialize() async {
    // Request permissions (Android 13+)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Local notifications channel (Android)
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ),
        );

    // Save FCM token to Firestore
    await _saveFcmToken();

    // Foreground message handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background handler (must be set before runApp)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _saveFcmToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': newToken,
      });
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // Admin: send notification to a specific user via Firestore trigger
  // (In production, use Firebase Cloud Functions to fan out FCM sends)
  Future<void> saveNotificationToInbox({
    required String toUserId,
    required String title,
    required String body,
    required String type, // 'message' | 'agreement' | 'job' | 'broadcast'
    String? relatedId, // chatId or jobId
  }) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'toUserId': toUserId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'read': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<int> streamUnreadCount(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
