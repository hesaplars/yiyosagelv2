import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../widgets/avatar_bubble.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.quiz});

  final Map<String, dynamic> quiz;

  static void show(BuildContext context, Map<String, dynamic> quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(quiz: quiz),
    );
  }

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final TextEditingController _inputController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  StreamSubscription? _sub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listenComments();
  }

  void _listenComments() {
    final quizId = widget.quiz['id']?.toString() ?? '';
    _sub = FirebaseService.instance.roomsRef.parent!
        .child('customQuizzes/$quizId/comments')
        .onValue
        .listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      final List<Map<String, dynamic>> list = [];
      if (val != null) {
        if (val is Map) {
          val.forEach((key, value) {
            list.add({'id': key, ...Map<String, dynamic>.from(value as Map)});
          });
        }
      }
      list.sort((a, b) => (b['createdAt'] ?? 0).toString().compareTo((a['createdAt'] ?? 0).toString()));
      setState(() {
        _comments = list;
        _loading = false;
      });
    });
  }

  Future<void> _sendComment() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    if (text.length > 240) {
      _showToast('Yorum 240 karakteri aşamaz.');
      return;
    }

    final profile = ref.read(profileProvider);
    final displayName = profile?.name ?? 'Oyuncu';
    final avatar = profile?.avatar ?? '🍄';
    final quizId = widget.quiz['id']?.toString() ?? '';

    try {
      await FirebaseService.instance.callFunction('addCustomQuizComment', {
        'quizId': quizId,
        'text': text,
        'name': displayName,
        'avatar': avatar,
      });
      _inputController.clear();
    } catch (e) {
      _showToast('Yorum gönderilemedi: $e');
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final quizId = widget.quiz['id']?.toString() ?? '';
    try {
      await FirebaseService.instance.callFunction('deleteCustomQuizComment', {
        'quizId': quizId,
        'commentId': commentId,
      });
      _showToast('Yorum silindi.');
    } catch (e) {
      _showToast('Yorum silinemedi: $e');
    }
  }

  void _reportComment(Map<String, dynamic> comment) {
    final commentId = comment['id']?.toString() ?? '';
    final creatorUid = comment['uid']?.toString() ?? '';
    final text = comment['text']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yorumu Rapor Et'),
        content: const Text('Bu yorumu kurallara aykırı olduğu gerekçesiyle şikayet etmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseService.instance.reportContent(
                  type: 'comment',
                  contentId: commentId,
                  reportedUid: creatorUid,
                  text: text,
                );
                _showToast('Şikayetiniz değerlendirilmek üzere başarıyla iletildi.');
              } catch (_) {
                _showToast('Rapor gönderilemedi.');
              }
            },
            child: const Text('Rapor Et', style: TextStyle(color: YGColors.red)),
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
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseService.instance.currentUser;

    return DraggableScrollableSheet(
      initialChildSize: 0.74,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? YGColors.darkBg : YGColors.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: YGColors.gold, width: 2.0)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            // Close header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Yorumlar', style: TextStyle(fontWeight: FontWeight.w950, fontSize: 20)),
                      Text(widget.quiz['title']?.toString() ?? '', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // List of comments
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: YGColors.gold))
                  : _comments.isEmpty
                      ? const Center(child: Text('İlk yorumu yazan sen ol!'))
                      : ListView.builder(
                          controller: controller,
                          itemCount: _comments.length,
                          itemBuilder: (context, i) {
                            final c = _comments[i];
                            final own = user != null && user.uid == c['uid'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AvatarBubble(avatar: c['avatar']?.toString() ?? '🍄', size: 28),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? YGColors.darkText : YGColors.lightText,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '${c['name'] ?? 'Oyuncu'} ',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text: '${YGHelpers.formatDateOnly(c['createdAt'])}  ',
                                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                              ),
                                              TextSpan(
                                                text: '\n${c['text'] ?? ''}',
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (own)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: YGColors.red, size: 18),
                                          onPressed: () => _deleteComment(c['id']),
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.flag_outlined, color: Colors.grey, size: 18),
                                          onPressed: () => _reportComment(c),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 8),

            // Leave Comment input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    maxLength: 240,
                    decoration: InputDecoration(
                      hintText: 'Yorum yaz...',
                      counterText: '',
                      filled: true,
                      fillColor: isDark ? YGColors.darkSurface : YGColors.lightSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendComment,
                  icon: const Icon(Icons.send, color: YGColors.gold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
