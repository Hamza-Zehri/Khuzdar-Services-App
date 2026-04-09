import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/all_models.dart';
import '../core/services/auth_service.dart';
import '../core/services/presence_service.dart';

class AuthAppProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _presenceService = PresenceService();

  UserModel? _user;
  bool _loading = false;

  UserModel? get user => _user;
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
  bool get hasProfile => _user != null;
  bool get loading => _loading;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  AuthAppProvider() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      _user = await _authService.fetchUser(firebaseUser.uid);
      if (_user != null && (_user!.isVisibleOnline)) {
        await _presenceService.goOnline();
      }
    } else {
      _user = null;
    }
    notifyListeners();
  }

  Future<void> sendOTP(String phone) async {
    await _authService.sendOTP(
      phoneNumber: phone,
      onCodeSent: (_) {},
      onError: (e) => debugPrint('OTP error: $e'),
      onAutoVerified: (_) {},
    );
  }

  Future<bool> verifyOTP(String code) async {
    try {
      final cred = await _authService.verifyOTP(code);
      if (cred?.user != null) {
        _user = await _authService.fetchUser(cred!.user!.uid);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Verify OTP error: $e');
    }
    return false;
  }

  Future<void> signOut() async {
    await _presenceService.goOffline();
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
