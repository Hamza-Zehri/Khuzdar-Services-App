import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseReference _ref(String uid) => _rtdb.ref('presence/$uid');

  Future<void> goOnline() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _ref(uid);

    // When connection drops, Firebase will auto-set this
    await ref.onDisconnect().set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });

    await ref.set({
      'online': true,
      'lastSeen': ServerValue.timestamp,
    });
  }

  Future<void> goOffline() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _ref(uid).set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  Stream<Map<String, dynamic>?> streamPresence(String uid) {
    return _ref(uid).onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return null;
      return Map<String, dynamic>.from(val as Map);
    });
  }

  Future<void> setVisibility(String uid, bool visible) async {
    // Stored in Firestore, read by other clients to decide whether to show status
    // This is just the presence signal — visibility pref is in UserModel.isVisibleOnline
    if (!visible) await goOffline();
  }
}
