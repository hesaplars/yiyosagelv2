import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ResultView extends StatelessWidget {
  const ResultView({
    super.key,
    required this.title,
    required this.result,
    required this.onDone,
  });

  final String title;
  final Map<String, dynamic> result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final correct = result['correct']?.toString() ?? '0';
    final wrong = result['wrong']?.toString() ?? '0';
    final pass = result['pass']?.toString() ?? '0';
    final score = result['score']?.toString() ?? '-';
    final goldEarned = result['goldEarned']?.toString() ?? '0';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            maxHeight: 460,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: YGColors.gold.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🏆', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w950, fontSize: 24),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Oyun Başarıyla Tamamlandı!',
                  style: TextStyle(color: YGColors.gold, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Grid stats
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStatChip('Doğru', correct, YGColors.green),
                    _buildStatChip('Yanlış', wrong, YGColors.red),
                    _buildStatChip('Pas', pass, YGColors.gold2),
                    _buildStatChip('Skor', score, YGColors.gold),
                  ],
                ),
                const SizedBox(height: 20),

                if (int.parse(goldEarned) > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: YGColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '✦ +$goldEarned Altın Kazandın!',
                      style: const TextStyle(color: YGColors.gold, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YGColors.gold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Kapat',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      width: 95,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w950, fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
