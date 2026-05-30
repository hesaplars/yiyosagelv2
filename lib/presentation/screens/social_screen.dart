import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/firebase_service.dart';
import '../widgets/avatar_bubble.dart';
import 'social/dm_chat_screen.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  // Modal helper to show details of another user
  static void showUserProfile(BuildContext context, String targetUid, Map<String, dynamic> userDetails) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserProfileSheet(uid: targetUid, initialDetails: userDetails),
    );
  }

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  String _activeTab = 'chats'; // 'chats', 'friends'
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;
  StreamSubscription? _friendsSub;
  StreamSubscription? _chatsSub;

  @override
  void initState() {
    super.initState();
    _listenSocialData();
  }

  void _listenSocialData() {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;

    // Listen to friends list
    _friendsSub = FirebaseService.instance.usersRef.child('$uid/friends').onValue.listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      final List<Map<String, dynamic>> list = [];
      if (val is Map) {
        val.forEach((key, value) {
          list.add({'uid': key, ...Map<String, dynamic>.from(value as Map)});
        });
      }
      setState(() {
        _friends = list;
        _loading = false;
      });
    });

    // Listen to active private messages
    _chatsSub = FirebaseService.instance.usersRef.parent!.child('chats').onValue.listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      final List<Map<String, dynamic>> list = [];
      if (val is Map) {
        val.forEach((chatId, chatVal) {
          if (chatId.toString().contains(uid)) {
            final cMap = Map<String, dynamic>.from(chatVal as Map);
            // Get other user ID
            final otherUid = chatId.toString().replaceAll(uid, '').replaceAll('_', '');
            
            // Fetch other profile detail locally/cached
            FirebaseService.instance.profileRef.child(otherUid).get().then((snap) {
              if (snap.exists && mounted) {
                final op = Map<String, dynamic>.from(snap.value as Map);
                setState(() {
                  _chats.removeWhere((element) => element['chatId'] == chatId);
                  _chats.add({
                    'chatId': chatId,
                    'otherUid': otherUid,
                    'name': op['name'] ?? 'Oyuncu',
                    'avatar': op['avatar'] ?? '🍄',
                    'lastMessage': (cMap['messages'] as Map?)?.values.last['text'] ?? '',
                  });
                });
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _chatsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Tab bar (Chats vs Friends)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Mesajlarım', style: TextStyle(fontWeight: FontWeight.bold))),
                    selected: _activeTab == 'chats',
                    onSelected: (_) => setState(() => _activeTab = 'chats'),
                    selectedColor: YGColors.gold.withOpacity(0.18),
                    showCheckmark: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Arkadaşlarım', style: TextStyle(fontWeight: FontWeight.bold))),
                    selected: _activeTab == 'friends',
                    onSelected: (_) => setState(() => _activeTab = 'friends'),
                    selectedColor: YGColors.gold.withOpacity(0.18),
                    showCheckmark: false,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: YGColors.gold))
                : _activeTab == 'chats'
                    ? _buildChatsList(isDark)
                    : _buildFriendsList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList(bool isDark) {
    if (_chats.isEmpty) {
      return const Center(child: Text('Henüz aktif sohbetiniz yok.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _chats.length,
      itemBuilder: (context, i) {
        final chat = _chats[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 18),
          child: ListTile(
            leading: AvatarBubble(avatar: chat['avatar'] ?? '🍄', size: 40),
            title: Text(chat['name'] ?? 'Oyuncu', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(chat['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DMChatScreen(
                  otherUid: chat['otherUid'],
                  otherName: chat['name'],
                  otherAvatar: chat['avatar'],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendsList(bool isDark) {
    if (_friends.isEmpty) {
      return const Center(child: Text('Ekli arkadaşınız bulunamadı.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _friends.length,
      itemBuilder: (context, i) {
        final friend = _friends[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 18),
          child: ListTile(
            leading: AvatarBubble(avatar: friend['avatar'] ?? '🍄', size: 40),
            title: Text(friend['name'] ?? 'Oyuncu', style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.message_outlined, color: YGColors.gold),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DMChatScreen(
                    otherUid: friend['uid'],
                    otherName: friend['name'],
                    otherAvatar: friend['avatar'],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Another User Profile Sheet Overlay
class UserProfileSheet extends ConsumerWidget {
  const UserProfileSheet({
    super.key,
    required this.uid,
    required this.initialDetails,
  });

  final String uid;
  final Map<String, dynamic> initialDetails;

  void _addFriend(BuildContext context) {
    final selfUid = FirebaseService.instance.currentUser?.uid;
    if (selfUid == null) return;

    FirebaseService.instance.usersRef
        .child('$uid/friends/$selfUid')
        .set({
      'name': initialDetails['name'] ?? 'Oyuncu',
      'avatar': initialDetails['avatar'] ?? '🍄',
    }).then((_) {
      FirebaseService.instance.usersRef
          .child('$selfUid/friends/$uid')
          .set({
        'name': initialDetails['name'] ?? 'Oyuncu',
        'avatar': initialDetails['avatar'] ?? '🍄',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arkadaş eklendi!')),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = initialDetails['name']?.toString() ?? 'Oyuncu';
    final avatar = initialDetails['avatar']?.toString() ?? '🍄';
    final bio = initialDetails['bio']?.toString() ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.75,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? YGColors.darkBg : YGColors.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: YGColors.gold, width: 2.0)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AvatarBubble(avatar: avatar, size: 74, frameColor: initialDetails['avatarFrameId'] != null ? YGColors.gold : null),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w950, fontSize: 24)),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(bio, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addFriend(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: YGColors.gold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Arkadaş Ekle', style: TextStyle(color: YGColors.gold, fontWeight: FontWeight.w950)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DMChatScreen(
                            otherUid: uid,
                            otherName: name,
                            otherAvatar: avatar,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YGColors.gold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Mesaj Gönder', style: TextStyle(fontWeight: FontWeight.w950)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
