import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/firebase_service.dart';
import '../../widgets/avatar_bubble.dart';
import 'create_quiz_screen.dart';
import 'custom_game_screen.dart';
import '../social_screen.dart';
import '../../sheets/comments_sheet.dart';

class CustomQuizListScreen extends ConsumerStatefulWidget {
  const CustomQuizListScreen({super.key});

  @override
  ConsumerState<CustomQuizListScreen> createState() => _CustomQuizListScreenState();
}

class _CustomQuizListScreenState extends ConsumerState<CustomQuizListScreen> {
  List<Map<String, dynamic>> _quizzes = [];
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  void _fetchQuizzes() {
    _sub = FirebaseService.instance.usersRef.parent!.child('customQuizzes').onValue.listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      if (val != null) {
        final List<Map<String, dynamic>> list = [];
        if (val is Map) {
          val.forEach((key, value) {
            final q = Map<String, dynamic>.from(value as Map);
            if (q['approved'] == true || q['approved'] == null) {
              list.add({'id': key, ...q});
            }
          });
        } else if (val is List) {
          for (int i = 0; i < val.length; i++) {
            if (val[i] != null) {
              final q = Map<String, dynamic>.from(val[i] as Map);
              list.add({'id': i.toString(), ...q});
            }
          }
        }
        list.sort((a, b) => (b['createdAt'] ?? 0).toString().compareTo((a['createdAt'] ?? 0).toString()));
        setState(() {
          _quizzes = list;
          _loading = false;
        });
      } else {
        setState(() {
          _quizzes = [];
          _loading = false;
        });
      }
    });
  }

  void _openComments(Map<String, dynamic> quiz) {
    CommentsSheet.show(context, quiz);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyun Keşfet', style: TextStyle(fontWeight: FontWeight.w950)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: YGColors.gold),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateQuizScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: YGColors.gold))
          : _quizzes.isEmpty
              ? const Center(child: Text('Kullanıcı oyunu bulunamadı. İlkini sen oluştur!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, i) {
                    final q = _quizzes[i];
                    final creator = Map<String, dynamic>.from(q['createdBy'] ?? {});
                    final title = q['title']?.toString() ?? 'Kelime Oyunu';
                    final description = q['description']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => SocialScreen.showUserProfile(
                                  context,
                                  creator['uid']?.toString() ?? '',
                                  creator,
                                ),
                                child: AvatarBubble(avatar: creator['avatar']?.toString() ?? '🍄', size: 32),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  creator['name']?.toString() ?? 'Oyuncu',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _openComments(q),
                                icon: const Icon(Icons.comment_outlined, size: 18, color: YGColors.gold),
                                label: const Text('Yorumlar', style: TextStyle(color: YGColors.gold, fontWeight: FontWeight.w800, fontSize: 12)),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomGameScreen(quiz: q),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: YGColors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Oyna', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
