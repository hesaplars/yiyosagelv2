import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/firebase_service.dart';
import 'avatar_bubble.dart';

class LeaderboardModal extends ConsumerStatefulWidget {
  const LeaderboardModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LeaderboardModal(),
    );
  }

  @override
  ConsumerState<LeaderboardModal> createState() => _LeaderboardModalState();
}

class _LeaderboardModalState extends ConsumerState<LeaderboardModal> {
  String _activeTab = 'daily'; // 'daily', 'live', 'wordle'
  List<Map<String, dynamic>> _scores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _loading = true);
    try {
      // Call Cloud Function to fetch leaderboard data
      final res = await FirebaseService.instance.callFunction('getLeaderboard', {'mode': _activeTab});
      if (res is List) {
        setState(() {
          _scores = List<Map<String, dynamic>>.from(res.map((item) => Map<String, dynamic>.from(item)));
          _loading = false;
        });
      } else if (res is Map && res['scores'] is List) {
        setState(() {
          _scores = List<Map<String, dynamic>>.from(res['scores'].map((item) => Map<String, dynamic>.from(item)));
          _loading = false;
        });
      }
    } catch (_) {
      // Mock Data if Firebase Function fails or is not deployed
      setState(() {
        _scores = List.generate(20, (i) => {
          'uid': 'user_$i',
          'name': i == 0 ? 'Şampiyon' : 'Oyuncu $i',
          'avatar': i % 3 == 0 ? '🦊' : (i % 3 == 1 ? '🐯' : '🐼'),
          'score': 1000 - (i * 45),
          'rank': i + 1,
        });
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? YGColors.darkBg : YGColors.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: YGColors.gold, width: 2.0)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(width: 45, height: 5, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 14),

            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const Text('Liderlik Tablosu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? YGColors.darkSurface2 : YGColors.lightSurface2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tabs Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildTabButton('daily', 'Günlük'),
                  const SizedBox(width: 8),
                  _buildTabButton('live', 'Tur (7/24)'),
                  const SizedBox(width: 8),
                  _buildTabButton('wordle', 'Tahmin'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content Area
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: YGColors.gold))
                  : _scores.isEmpty
                      ? const Center(child: Text('Skor kaydı bulunamadı.'))
                      : CustomScrollView(
                          controller: controller,
                          slivers: [
                            // 3D Podium for top 3
                            SliverToBoxAdapter(
                              child: _buildPodiumSection(),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 16)),

                            // Scrollable list for rank 4+
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final player = _scores[index + 3];
                                    final rank = index + 4;
                                    return _buildRankRow(player, rank, isDark);
                                  },
                                  childCount: _scores.length > 3 ? _scores.length - 3 : 0,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final active = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tab;
          });
          _fetchLeaderboard();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? YGColors.gold : (Theme.of(context).brightness == Brightness.dark ? YGColors.darkSurface : YGColors.lightSurface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? YGColors.gold : Colors.transparent),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: active ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumSection() {
    if (_scores.isEmpty) return const SizedBox();

    final first = _scores.length > 0 ? _scores[0] : null;
    final second = _scores.length > 1 ? _scores[1] : null;
    final third = _scores.length > 2 ? _scores[2] : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Left)
          if (second != null)
            _buildPodiumColumn(
              second,
              2,
              95,
              YGColors.gold2.withOpacity(0.5),
              isDark,
            ),
          const SizedBox(width: 12),

          // 1st Place (Center - Tallest)
          if (first != null)
            _buildPodiumColumn(
              first,
              1,
              125,
              YGColors.gold,
              isDark,
            ),
          const SizedBox(width: 12),

          // 3rd Place (Right)
          if (third != null)
            _buildPodiumColumn(
              third,
              3,
              75,
              const Color(0xffcd7f32),
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(
      Map<String, dynamic> player, int rank, double height, Color accent, bool isDark) {
    String rankLabel = rank == 1 ? '🥇' : (rank == 2 ? '🥈' : '🥉');

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarBubble(
            avatar: player['avatar']?.toString() ?? '🍄',
            size: rank == 1 ? 64 : 54,
            frameColor: accent,
          ),
          const SizedBox(height: 6),
          Text(
            player['name']?.toString() ?? 'Oyuncu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          Text(
            '${player['score']} Puan',
            style: const TextStyle(color: YGColors.gold, fontWeight: FontWeight.w800, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent.withOpacity(0.4), accent.withOpacity(0.1)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: accent.withOpacity(0.6), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              rankLabel,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(Map<String, dynamic> player, int rank, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 18),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          AvatarBubble(avatar: player['avatar']?.toString() ?? '🍄', size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player['name']?.toString() ?? 'Oyuncu',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          Text(
            '${player['score']} Puan',
            style: const TextStyle(fontWeight: FontWeight.w900, color: YGColors.gold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
