import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/firebase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/avatar_bubble.dart';

class DMChatScreen extends ConsumerStatefulWidget {
  const DMChatScreen({
    super.key,
    required this.otherUid,
    required this.otherName,
    required this.otherAvatar,
  });

  final String otherUid;
  final String otherName;
  final String otherAvatar;

  @override
  ConsumerState<DMChatScreen> createState() => _DMChatScreenState();
}

class _DMChatScreenState extends ConsumerState<DMChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _sub;
  bool _loading = true;
  String _chatId = '';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;

    // Generate stable unique chatId sorted by UIDs
    final list = [uid, widget.otherUid]..sort();
    _chatId = '${list[0]}_${list[1]}';

    // Subscribe to chat messages node
    _sub = FirebaseService.instance.usersRef.parent!
        .child('chats/$_chatId/messages')
        .onValue
        .listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      final List<Map<String, dynamic>> msgs = [];
      if (val != null) {
        if (val is Map) {
          val.forEach((key, value) {
            msgs.add({'id': key, ...Map<String, dynamic>.from(value as Map)});
          });
        }
      }
      msgs.sort((a, b) => (a['timestamp'] ?? 0).toString().compareTo((b['timestamp'] ?? 0).toString()));
      setState(() {
        _messages.clear();
        _messages.addAll(msgs);
        _loading = false;
      });
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseService.instance.usersRef.parent!
          .child('chats/$_chatId/messages')
          .push()
          .set({
        'sender': uid,
        'text': text,
        'timestamp': ServerValue.timestamp,
      });
      _messageController.clear();
    } catch (e) {
      _showToast('Mesaj gönderilemedi: $e');
    }
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.otherName} Engellensin mi?'),
        content: const Text('Bu kullanıcıyı engellerseniz size mesaj gönderemeyecektir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseService.instance.blockUser(widget.otherUid);
                _showToast('Kullanıcı engellendi.');
                if (mounted) Navigator.pop(context);
              } catch (_) {
                _showToast('İşlem başarısız.');
              }
            },
            child: const Text('Engelle', style: TextStyle(color: YGColors.red)),
          ),
        ],
      ),
    );
  }

  void _reportMessage(Map<String, dynamic> message) {
    final messageId = message['id']?.toString() ?? '';
    final text = message['text']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Şikayet Et'),
        content: const Text('Bu mesajı uygunsuz içerik barındırdığı gerekçesiyle şikayet etmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseService.instance.reportContent(
                  type: 'dm',
                  contentId: messageId,
                  reportedUid: widget.otherUid,
                  text: text,
                );
                _showToast('Şikayetiniz alındı.');
              } catch (_) {
                _showToast('Rapor gönderilemedi.');
              }
            },
            child: const Text('Şikayet Et', style: TextStyle(color: YGColors.red)),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = FirebaseService.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AvatarBubble(avatar: widget.otherAvatar, size: 36),
            const SizedBox(width: 10),
            Text(widget.otherName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'block') _blockUser();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Text('Engelle', style: TextStyle(color: YGColors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Message stream
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: YGColors.gold))
                : _messages.isEmpty
                    ? const Center(child: Text('Sohbete ilk selamı ver! 👋'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final mine = m['sender'] == myUid;

                          return GestureDetector(
                            onLongPress: mine ? null : () => _reportMessage(m),
                            child: Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? YGColors.gold.withOpacity(0.85)
                                      : (isDark ? YGColors.darkSurface2 : YGColors.lightSurface2),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: mine ? const Radius.circular(18) : Radius.zero,
                                    bottomRight: mine ? Radius.zero : const Radius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  m['text']?.toString() ?? '',
                                  style: TextStyle(
                                    color: mine ? Colors.white : (isDark ? YGColors.darkText : YGColors.lightText),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Message input bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? YGColors.darkSurface : YGColors.lightSurface,
              border: Border(top: BorderSide(color: isDark ? YGColors.lineDark : YGColors.lineLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Mesaj yaz...',
                      filled: true,
                      fillColor: isDark ? YGColors.darkBg : YGColors.lightBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: YGColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
