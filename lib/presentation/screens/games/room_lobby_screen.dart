import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/firebase_service.dart';
import '../../../providers/auth_provider.dart';
import 'live_game_screen.dart';

class RoomLobbyScreen extends ConsumerStatefulWidget {
  const RoomLobbyScreen({super.key});

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _busy = false;

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _createRoom() async {
    final profile = ref.read(profileProvider);
    final displayName = profile?.name ?? 'Oyuncu';
    final avatar = profile?.avatar ?? '🍄';

    setState(() => _busy = true);
    try {
      final res = Map<String, dynamic>.from(
        await FirebaseService.instance.callFunction('createRoom', {
          'name': displayName,
          'avatar': avatar,
        }),
      );
      final code = res['code']?.toString();
      if (!mounted) return;
      if (code != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LiveGameScreen(code: code, publicMode: false),
          ),
        );
      }
    } catch (e) {
      _showToast('Oda oluşturulamadı: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final profile = ref.read(profileProvider);
    final displayName = profile?.name ?? 'Oyuncu';
    final avatar = profile?.avatar ?? '🍄';

    setState(() => _busy = true);
    try {
      await FirebaseService.instance.callFunction('joinRoom', {
        'code': code,
        'name': displayName,
        'avatar': avatar,
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LiveGameScreen(code: code, publicMode: false),
        ),
      );
    } catch (e) {
      _showToast('Odaya girilemedi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oda Kur', style: TextStyle(fontWeight: FontWeight.w950)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups_2_outlined, color: YGColors.gold, size: 58),
                const SizedBox(height: 16),
                const Text(
                  'Özel Oyun Odası',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w950),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Arkadaşlarınla oynamak için yeni bir oda kur ya da mevcut bir odaya katıl.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 28),

                // Create Room Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _createRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YGColors.gold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Yeni Oda Kur', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('VEYA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Join Room Form
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 5,
                  decoration: InputDecoration(
                    hintText: 'Oda Kodu Gir',
                    counterText: '',
                    filled: true,
                    fillColor: isDark ? YGColors.darkBg : YGColors.lightBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _joinRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YGColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Koda Katıl', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
