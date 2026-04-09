import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _verificationId;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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
      verificationFailed: onError,
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        onCodeSent(verificationId);
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

  // Step 3: Create or fetch user profile in Firestore
  Future<UserModel?> createOrFetchUser({
    required String uid,
    required String phone,
    String name = '',
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
      createdAt: DateTime.now(),
    );
    await docRef.set(user.toFirestore());
    return user;
  }

  Future<UserModel?> fetchUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists ? UserModel.fromFirestore(snap) : null;
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({'role': role.name});
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
