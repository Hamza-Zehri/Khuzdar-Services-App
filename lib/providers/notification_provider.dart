import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/messaging_service.dart';

class NotificationAppProvider extends ChangeNotifier {
  final _service = MessagingService();
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  NotificationAppProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _listen(user.uid);
    });
  }

  void _listen(String uid) {
    _service.streamUnreadCount(uid).listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }
}
