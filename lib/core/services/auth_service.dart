import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService() {
    // Explicitly initialize with serverClientId to prevent "Sign in failed"
    _googleSignIn.initialize(
      serverClientId: '462613436846-5fp1pbj1ghafhshi5le1ptfl86njntim.apps.googleusercontent.com',
    );
  }

  String? _verificationId;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // New: Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ensure initialized (v7.x requirement)
      // Note: In some versions this is required, in others it's internal.
      // But using .authenticate() on the instance is correct.
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      
      // In google_sign_in v7.x+, authentication is a getter and only contains idToken
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      // To get the accessToken, we use the authorizationClient
      final authz = await googleUser.authorizationClient.authorizationForScopes(['email', 'profile']);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authz?.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Step 1: Send OTP
  Future<void> sendOTP({
    required String phoneNumber, // e.g. +923001234567
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: (FirebaseAuthException e) {
        // Detailed internal logging
        // debugPrint('🔥 Firebase Auth Error [${e.code}]: ${e.message}');
        // if (e.code == 'app-not-authorized') {
        //   debugPrint('TIP: This means SHA-1 fingerprints are missing in Firebase Console.');
        // }
        onError(e);
      },
      codeSent: (String vid, int? resendToken) {
        _verificationId = vid;
        // debugPrint('✅ OTP Sent successfully. ID: $vid');
        onCodeSent(vid);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // Step 2: Verify OTP
  Future<UserCredential?> verifyOTP(String smsCode) async {
    if (_verificationId == null) throw Exception('No verification ID');
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Email/Password Auth
  Future<UserCredential> loginWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Step 3: Create or fetch user profile in Firestore
  Future<UserModel?> createOrFetchUser({
    required String uid,
    required String phone,
    String name = '',
    String? address,
    UserRole role = UserRole.customer,
  }) async {
    final docRef = _db.collection('users').doc(uid);
    final snap = await docRef.get();

    if (snap.exists) {
      return UserModel.fromFirestore(snap);
    }

    // New user
    final user = UserModel(
      id: uid,
      name: name,
      phone: phone,
      role: role,
      address: address,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(uid).set(
      user.toFirestore(),
      SetOptions(merge: true),
    );
    return user;
  }

  Future<UserModel?> fetchUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists ? UserModel.fromFirestore(snap) : null;
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).set({
      'role': role.name,
      'id': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
