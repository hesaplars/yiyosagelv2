import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  // Auth Streams
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Singleton pattern for simplicity, or inject via Provider
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  // Ensures we always have an authenticated user (Anonymous fallback)
  Future<User> ensureUser() async {
    final current = _auth.currentUser;
    if (current != null) return current;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  // Anonymous Login
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // Google Sign In (Android/iOS & Web compatible)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final current = _auth.currentUser;
      if (current != null && current.isAnonymous) {
        // Link anonymous account to preserve data
        return await current.linkWithCredential(credential);
      } else {
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // Call Cloud Function Helper
  Future<dynamic> callFunction(String name, [Map<String, dynamic>? data]) async {
    await ensureUser();
    final result = await _functions.httpsCallable(name).call(data ?? <String, dynamic>{});
    return result.data;
  }

  // Profiles Database Ref
  DatabaseReference get profileRef => _db.ref('profiles');
  DatabaseReference get roomsRef => _db.ref('rooms');
  DatabaseReference get usersRef => _db.ref('users');

  // Sync profile details to RTDB
  Future<void> syncProfile({required String displayName, required String avatar}) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.ref('profiles/$uid').update({
      'uid': uid,
      'name': displayName,
      'avatar': avatar,
      'isGoogle': !(currentUser?.isAnonymous ?? true),
      'lastSeenAt': ServerValue.timestamp,
    });
  }

  // Block User
  Future<void> blockUser(String blockedUid) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/blocked/$blockedUid').set(true);
    // Bidirectional list updates or simply local storage
  }

  // Report Content (swears, spam, comments, chats, DMs)
  Future<void> reportContent({
    required String type, // 'chat', 'dm', 'comment'
    required String contentId,
    required String reportedUid,
    required String text,
  }) async {
    final uid = currentUser?.uid;
    await callFunction('reportUserContent', {
      'type': type,
      'contentId': contentId,
      'reportedUid': reportedUid,
      'reporterUid': uid,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
