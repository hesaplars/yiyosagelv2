import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/firebase_service.dart';
import '../../../providers/auth_provider.dart';

class CreateQuizScreen extends ConsumerStatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  ConsumerState<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends ConsumerState<CreateQuizScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<Map<String, TextEditingController>> _questions = [
    {'prompt': TextEditingController(), 'answer': TextEditingController()}
  ];
  bool _busy = false;

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'prompt': TextEditingController(),
        'answer': TextEditingController(),
      });
    });
  }

  Future<void> _publishQuiz() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    if (title.isEmpty) {
      _showToast('Lütfen oyun için bir başlık girin.');
      return;
    }

    // Validate questions
    final List<Map<String, String>> quizQuestions = [];
    for (final q in _questions) {
      final pText = q['prompt']!.text.trim();
      final aText = q['answer']!.text.trim();
      if (pText.isEmpty || aText.isEmpty) {
        _showToast('Soru ve cevap alanları boş bırakılamaz.');
        return;
      }
      quizQuestions.add({'prompt': pText, 'answer': aText});
    }

    final profile = ref.read(profileProvider);
    final displayName = profile?.name ?? 'Oyuncu';
    final avatar = profile?.avatar ?? '🍄';

    setState(() => _busy = true);

    try {
      await FirebaseService.instance.callFunction('createCustomQuiz', {
        'title': title,
        'description': description,
        'totalMinutes': 5,
        'name': displayName,
        'avatar': avatar,
        'questions': quizQuestions,
      });

      _showToast('Oyun başarıyla oluşturuldu ve onaya gönderildi!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showToast('Oyun oluşturulamadı: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final q in _questions) {
      q['prompt']!.dispose();
      q['answer']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Oyun Oluştur', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator(color: YGColors.gold))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Info block
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Oyun Başlığı',
                    hintText: 'Örn: Yeşilçam Klasikleri',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Kısa Açıklama',
                    hintText: 'Örn: Türk sineması üzerine genel kültür soruları.',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sorular',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 12),

                // Question Cards
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  itemBuilder: (context, i) {
                    final q = _questions[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Soru ${i + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                              const Spacer(),
                              if (_questions.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: YGColors.red, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _questions.removeAt(i);
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: q['prompt'],
                            decoration: const InputDecoration(
                              hintText: 'Soru cümlesini buraya yazın...',
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: q['answer'],
                            decoration: const InputDecoration(
                              hintText: 'Tek kelimelik cevap...',
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _addQuestion,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: YGColors.gold, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Soru Ekle', style: TextStyle(color: YGColors.gold, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _publishQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: YGColors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Yayınla', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
            ),
    );
  }
}
