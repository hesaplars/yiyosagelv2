import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/economy_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'social_screen.dart';
import 'store_screen.dart';
import 'profile_screen.dart';
import '../widgets/soft_pill.dart';
import '../widgets/avatar_bubble.dart';

class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        return const MainAppShell();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: YGColors.gold)),
      ),
      error: (e, __) => Scaffold(
        body: Center(child: Text('Hata oluştu: $e', style: const TextStyle(color: YGColors.red))),
      ),
    );
  }
}

class MainAppShell extends ConsumerStatefulWidget {
  const MainAppShell({super.key});

  @override
  ConsumerState<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends ConsumerState<MainAppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SocialScreen(),
    const StoreScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final profile = ref.watch(profileProvider);
    final economy = ref.watch(economyProvider);

    final balance = economy.wallet['balance'] as int? ?? 0;
    final avatar = profile?.avatar ?? '🍄';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Brand Header
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: YGColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'YG',
                        style: TextStyle(color: YGColors.gold, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YiyosaGel',
                          style: TextStyle(color: YGColors.gold, fontWeight: FontWeight.w900, fontSize: 18, height: 1.1),
                        ),
                        Text(
                          'Kelime Arenası',
                          style: TextStyle(
                            color: isDark ? YGColors.darkMuted : YGColors.lightMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),

                // Gold Coins Pill
                SoftPill(
                  onTap: () => setState(() => _currentIndex = 2), // Go to Store tab
                  child: Row(
                    children: [
                      const Text('✦', style: TextStyle(color: YGColors.gold, fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '$balance',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Theme Toggle
                IconButton(
                  onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: isDark ? YGColors.darkText : YGColors.lightText,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? YGColors.darkSurface : YGColors.lightSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? YGColors.lineDark : YGColors.lineLight),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Mini Avatar Tap
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 3), // Go to Profile tab
                  child: AvatarBubble(
                    avatar: avatar,
                    size: 42,
                    frameColor: profile?.avatarFrameId != null ? YGColors.gold : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: isDark ? YGColors.lineDark : YGColors.lineLight, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? YGColors.darkBg : YGColors.lightBg,
          selectedItemColor: YGColors.gold,
          unselectedItemColor: isDark ? YGColors.darkMuted : YGColors.lightMuted,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w900, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports_outlined),
              activeIcon: Icon(Icons.sports_esports),
              label: 'Oyna',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Sosyal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Mağaza',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
