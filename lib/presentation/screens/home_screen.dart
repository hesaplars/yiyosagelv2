import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/mode_card.dart';
import '../widgets/leaderboard_modal.dart';
import '../widgets/soft_pill.dart';
import '../widgets/avatar_bubble.dart';
import '../../data/services/firebase_service.dart';

// Game Screen Imports (We will create these next)
import 'games/daily_game_screen.dart';
import 'games/live_game_screen.dart';
import 'games/room_lobby_screen.dart';
import 'games/custom_quiz_list_screen.dart';
import 'games/wordle_screen.dart';
import 'social_screen.dart'; // To open user profile sheets

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _searching = true);
    // Query users database from RTDB
    FirebaseService.instance.profileRef.get().then((snapshot) {
      if (!mounted) return;
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final List<Map<String, dynamic>> matches = [];
        data.forEach((key, val) {
          final p = Map<String, dynamic>.from(val as Map);
          final name = p['name']?.toString() ?? '';
          if (name.toLowerCase().contains(query.toLowerCase())) {
            matches.add({'uid': key, ...p});
          }
        });
        setState(() {
          _searchResults = matches.take(5).toList();
          _searching = false;
        });
      } else {
        setState(() => _searching = false);
      }
    }).catchError((_) {
      if (mounted) setState(() => _searching = false);
    });
  }

  void _openGame(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          // Leaderboard Shortcuts Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Arenalar & Modlar',
                style: TextStyle(fontWeight: FontWeight.w950, fontSize: 18),
              ),
              SoftPill(
                onTap: () => LeaderboardModal.show(context),
                child: const Row(
                  children: [
                    Icon(Icons.leaderboard_outlined, color: YGColors.gold, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Sıralama',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // User Search Bar
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Kullanıcı ara...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? YGColors.darkSurface : YGColors.lightSurface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: isDark ? YGColors.lineDark : YGColors.lineLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: isDark ? YGColors.lineDark : YGColors.lineLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: YGColors.gold, width: 1.5),
              ),
            ),
          ),

          // Search Results Dropdown
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 18),
              child: Column(
                children: _searchResults.map((user) {
                  return ListTile(
                    leading: AvatarBubble(avatar: user['avatar'] ?? '🍄', size: 36),
                    title: Text(user['name'] ?? 'Oyuncu', style: const TextStyle(fontWeight: FontWeight.w800)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Reset search
                      setState(() {
                        _searchResults = [];
                        _searchQuery = '';
                      });
                      // Open social details sheet or chat
                      SocialScreen.showUserProfile(context, user['uid'], user);
                    },
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 20),

          // GAME MODES CARDS
          ModeCard(
            title: 'GÜNLÜK (REKABETÇİ)',
            subtitle: 'Bugünün soru setini oyna, zirveye çık!',
            icon: Icons.calendar_month,
            accentColor: YGColors.red,
            actionLabel: 'Oyna',
            onTap: () => _openGame(const DailyGameScreen()),
          ),

          ModeCard(
            title: 'TUR (7/24 CANLI)',
            subtitle: 'Canlı tur odasında rakiplerinle yarış!',
            icon: Icons.radio_button_checked,
            accentColor: YGColors.green,
            actionLabel: 'Gir',
            onTap: () => _openGame(const LiveGameScreen()),
          ),

          ModeCard(
            title: 'ODA KUR',
            subtitle: 'Arkadaşlarınla özel oyun odası kur!',
            icon: Icons.groups_2,
            accentColor: YGColors.gold,
            actionLabel: 'Oda Aç',
            onTap: () => _openGame(const RoomLobbyScreen()),
          ),

          ModeCard(
            title: 'OYUN OLUŞTUR',
            subtitle: 'Kendi soru setini oluştur veya keşfet!',
            icon: Icons.edit_note,
            accentColor: const Color(0xff3aa7d8),
            actionLabel: 'Keşfet',
            onTap: () => _openGame(const CustomQuizListScreen()),
          ),

          ModeCard(
            title: 'KELİME TAHMİN',
            subtitle: '5 harfli gizli kelimeyi en az denemede bul!',
            icon: Icons.grid_4x4,
            accentColor: const Color(0xff8b5cf6),
            actionLabel: 'Oyna',
            onTap: () => _openGame(const WordleScreen()),
          ),
        ],
      ),
    );
  }
}
