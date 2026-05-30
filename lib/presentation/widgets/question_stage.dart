import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QuestionStage extends StatelessWidget {
  const QuestionStage({
    super.key,
    required this.questions,
    required this.currentIndex,
    required this.secondsLeft,
    required this.records,
    required this.prompt,
    required this.letter,
    required this.controller,
    required this.onSubmit,
  });

  final List<dynamic> questions;
  final int currentIndex;
  final int secondsLeft;
  final Map<String, Map<String, dynamic>> records;
  final String prompt;
  final String letter;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = controller.text.trim().isNotEmpty;

    final correctCount = records.values.where((r) => r['status'] == 'correct').length;
    final wrongCount = records.values.where((r) => r['status'] == 'wrong').length;
    final passCount = records.values.where((r) => r['status'] == 'pass').length;

    return Column(
      children: [
        // 1. Letters Horizontal Progress Indicator
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final q = questions[index];
              final qId = q['id']?.toString() ?? '';
              final r = records[qId];

              Color color = isDark ? YGColors.darkSurface2 : YGColors.lightSurface2;
              if (r != null) {
                if (r['status'] == 'correct') color = YGColors.green;
                if (r['status'] == 'wrong') color = YGColors.red;
                if (r['status'] == 'pass') color = YGColors.gold2;
              }

              final active = index == currentIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 56 : 46,
                height: active ? 56 : 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? color.withOpacity(0.95) : color.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? YGColors.gold : (isDark ? YGColors.lineDark : YGColors.lineLight),
                    width: active ? 2.5 : 1.0,
                  ),
                ),
                child: Text(
                  '${q['letter'] ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w950,
                    fontSize: active ? 20 : 15,
                    color: active ? Colors.white : (isDark ? YGColors.darkText : YGColors.lightText),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // 2. Active Question Card Stage
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(22),
            decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 28),
            child: Column(
              children: [
                // Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, color: YGColors.gold, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(secondsLeft),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w950,
                        color: secondsLeft < 30 ? YGColors.red : (isDark ? YGColors.darkText : YGColors.lightText),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Question Prompt
                Text(
                  prompt.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const Spacer(),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statText('✓ $correctCount Doğru', YGColors.green),
                    const SizedBox(width: 16),
                    _statText('× $wrongCount Yanlış', YGColors.red),
                    const SizedBox(width: 16),
                    _statText('⏭ $passCount Pas', YGColors.gold),
                  ],
                ),
                const SizedBox(height: 20),

                // Form Input and Action Button (Row)
                StatefulBuilder(
                  builder: (context, setInnerState) {
                    controller.removeListener(() {});
                    controller.addListener(() {
                      setInnerState(() {});
                    });

                    final currentHasText = controller.text.trim().isNotEmpty;

                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: '$letter... (Cevabı yaz)',
                              filled: true,
                              fillColor: isDark ? YGColors.darkBg : YGColors.lightBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 110,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentHasText ? YGColors.green : YGColors.gold2,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              currentHasText ? 'GÖNDER' : 'PAS',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 14,
      ),
    );
  }
}
