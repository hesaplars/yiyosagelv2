import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/economy_provider.dart';
import '../widgets/avatar_bubble.dart';
import '../widgets/soft_pill.dart';
import '../../data/services/firebase_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String _selectedAvatar = '🍄';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    if (profile != null) {
      _nameController.text = profile.name;
      _bioController.text = profile.bio ?? '';
      _selectedAvatar = profile.avatar;
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      _showToast('İsim alanı boş bırakılamaz.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(profileProvider.notifier).updateProfile(
            displayName: name,
            avatar: _selectedAvatar,
          );
      await ref.read(profileProvider.notifier).updateBio(bio);
      _showToast('Profil başarıyla güncellendi!');
    } catch (e) {
      _showToast('Güncelleme hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseService.instance.signOut();
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: YGColors.gold)),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Cover + Profile image card
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? YGColors.darkSurface : YGColors.lightSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? YGColors.lineDark : YGColors.lineLight),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Mock Cover Color (can be image if purchased coverId matches)
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: YGColors.gold.withOpacity(0.12),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 20,
                  child: AvatarBubble(
                    avatar: profile.avatar,
                    size: 82,
                    frameColor: profile.avatarFrameId != null ? YGColors.gold : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // User stats & details block
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Profil Bilgileri',
                  style: TextStyle(fontWeight: FontWeight.w950, fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _bioController,
                  maxLines: 2,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Biyografi',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 20),

                // Avatar Grid selector
                const Text(
                  'Profil Avatarı Seç',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppConstants.avatars.map((a) {
                    final selected = _selectedAvatar == a;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = a),
                      child: AvatarBubble(
                        avatar: a,
                        size: 38,
                        selected: selected,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Save profile button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YGColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Bilgileri Güncelle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log out Button card
          SizedBox(
            height: 52,
            child: ElevatedButton.styleFrom(
              child: OutlinedButton(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: YGColors.red, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Çıkış Yap', style: TextStyle(color: YGColors.red, fontWeight: FontWeight.w900)),
              ),
            ).child,
          ),
        ],
      ),
    );
  }
}
