import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/all_models.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/presence_service.dart';
import 'language_provider.dart';

class AuthAppProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _presenceService = PresenceService();
  final _firestoreService = FirestoreService();
  final LanguageProvider? languageProvider;

  UserModel? _user;
  bool _isProviderMode = false;

  UserModel? get user => _user;
  bool get isProviderMode => _isProviderMode;
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
  bool get hasProfile => _user != null;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  AuthAppProvider({this.languageProvider}) {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      _user = await _authService.fetchUser(firebaseUser.uid);
      if (_user != null) {
        // SYNC LANGUAGE
        languageProvider?.setLocale(_user!.language);
        
        if (_user!.isVisibleOnline) {
          await _presenceService.goOnline();
        }
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

  Future<void> refreshUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await _onAuthStateChanged(firebaseUser);
    }
  }

  Future<void> toggleProviderMode() async {
    _isProviderMode = !_isProviderMode;
    notifyListeners();
  }

  Future<void> enableProviderMode() async {
    _isProviderMode = true;
    notifyListeners();
  }

  Future<void> toggleAvailability(bool isAvailable) async {
    if (uid == null) return;
    try {
      await _firestoreService.toggleProviderAvailability(uid!, isAvailable);
    } catch (e) {
      debugPrint('Error toggling availability: $e');
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    try {
      final cred = await _authService.loginWithEmail(email, password);
      return cred.user != null;
    } catch (e) {
      debugPrint('Email Login Error: $e');
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred != null && cred.user != null) {
        // Fetch profile
        _user = await _authService.fetchUser(cred.user!.uid);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Google Login Error: $e');
      return false;
    }
  }

  Future<bool> completeRegistration({
    required String email,
    String? password, // Now optional
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      String? targetUid;

      // 1. If already logged in (Google), use existing UID
      final currentFirebaseUser = FirebaseAuth.instance.currentUser;
      if (currentFirebaseUser != null) {
        targetUid = currentFirebaseUser.uid;
      } else if (password != null) {
        // 2. Otherwise create new Email Auth account (Legacy fallback)
        final cred = await _authService.signUpWithEmail(email, password);
        targetUid = cred.user?.uid;
      }

      if (targetUid != null) {
        // 3. Create Firestore profile
        _user = await _authService.createOrFetchUser(
          uid: targetUid,
          phone: phone,
          name: name,
          address: address,
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Complete Registration Error: $e');
    }
    return false;
  }

  Future<bool> updateProfile({
    String? name,
    String? address,
    String? language,
  }) async {
    if (uid == null) return false;
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (address != null) updates['address'] = address;
      if (language != null) updates['language'] = language;

      if (updates.isEmpty) return true;

      // 1. Update User Document
      await _firestoreService.updateUserFields(uid!, updates);

      // 2. If it's a provider and address changed, sync to provider doc
      if (address != null && _user?.role == UserRole.provider) {
        // Area is the primary location for providers
        await _firestoreService.updateProviderFields(uid!, {'area': address});
      }

      // 3. Refresh local user state
      await refreshUser();
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _presenceService.goOffline().timeout(const Duration(seconds: 2));
    } catch (_) {}
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
