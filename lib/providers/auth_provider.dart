import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/user_profile.dart';
import '../data/services/firebase_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.instance.authStateChanges;
});

class ProfileNotifier extends StateNotifier<UserProfile?> {
  ProfileNotifier(this.ref) : super(null) {
    _init();
  }

  final Ref ref;
  StreamSubscription? _profileSub;

  void _init() {
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final user = next.value;
      if (user == null) {
        _profileSub?.cancel();
        state = null;
      } else {
        _listenToProfile(user.uid);
      }
    }, fireImmediately: true);
  }

  void _listenToProfile(String uid) {
    _profileSub?.cancel();
    _profileSub = FirebaseService.instance.profileRef.child(uid).onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        final rawMap = Map<String, dynamic>.from(value as Map);
        state = UserProfile.fromMap(uid, rawMap);
      } else {
        // First-time fallback sync
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final defaultName = user.displayName ?? user.email?.split('@').first ?? 'Misafir Oyuncu';
          FirebaseService.instance.syncProfile(displayName: defaultName, avatar: '🍄');
        }
      }
    });
  }

  Future<void> updateProfile({required String displayName, required String avatar}) async {
    await FirebaseService.instance.syncProfile(displayName: displayName, avatar: avatar);
  }

  Future<void> updateBio(String bio) async {
    final uid = state?.uid;
    if (uid == null) return;
    await FirebaseDatabase.instance.ref('profiles/$uid').update({'bio': bio});
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile?>((ref) {
  return ProfileNotifier(ref);
});
