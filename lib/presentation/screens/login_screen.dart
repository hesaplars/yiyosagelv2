import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/firebase_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nicknameController = TextEditingController();
  bool _termsAccepted = false;
  bool _loading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: YGColors.red,
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    if (!_termsAccepted) {
      _showToast("Devam etmek için Kullanım Şartları ve Kullanıcı Sözleşmesi'ni kabul etmelisiniz.");
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseService.instance.signInWithGoogle();
      if (cred != null) {
        // Authenticated successfully
      }
    } catch (e) {
      _showToast("Google Girişi başarısız: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    if (!_termsAccepted) {
      _showToast("Devam etmek için Kullanım Şartları ve Kullanıcı Sözleşmesi'ni kabul etmelisiniz.");
      return;
    }
    final name = _nicknameController.text.trim();
    if (name.isEmpty) {
      _showToast("Misafir oyuncu olmak için lütfen bir kullanıcı adı girin.");
      return;
    }
    if (name.length < 3 || name.length > 15) {
      _showToast("Kullanıcı adı 3-15 karakter arasında olmalıdır.");
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseService.instance.signInAnonymously();
      if (cred.user != null) {
        await FirebaseService.instance.syncProfile(displayName: name, avatar: '🍄');
      }
    } catch (e) {
      _showToast("Misafir girişi başarısız: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xff1f1a10), YGColors.darkBg]
                : [const Color(0xfffffcf4), YGColors.lightBg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Area
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: YGColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: YGColors.gold.withOpacity(0.3), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'YG',
                        style: TextStyle(
                          color: YGColors.gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 34,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'YiyosaGel',
                      style: TextStyle(
                        color: YGColors.gold,
                        fontWeight: FontWeight.w900,
                        fontSize: 36,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'Online Kelime Arenası',
                      style: TextStyle(
                        color: YGColors.gold2,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Inputs block with Glassmorphism Theme
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: AppTheme.premiumBoxDecoration(isDark: isDark),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Misafir Oyuncu Girişi',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nicknameController,
                            maxLength: 15,
                            decoration: InputDecoration(
                              hintText: 'Kullanıcı Adı Belirle',
                              prefixIcon: const Icon(Icons.person_outline),
                              counterText: '',
                              filled: true,
                              fillColor: isDark ? YGColors.darkBg : YGColors.lightBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: _loading ? null : _handleGuestLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: YGColors.gold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Misafir Olarak Giriş Yap', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'VEYA',
                      style: TextStyle(fontWeight: FontWeight.w800, color: YGColors.gold, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Google Login Button
                    OutlinedButton(
                      onPressed: _loading ? null : _handleGoogleLogin,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: YGColors.gold.withOpacity(0.5), width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                            height: 20,
                            width: 20,
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: YGColors.gold),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Google ile Giriş Yap',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: YGColors.gold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Terms and Conditions checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          activeColor: YGColors.gold,
                          onChanged: (val) {
                            setState(() {
                              _termsAccepted = val ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? YGColors.darkMuted : YGColors.lightMuted,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'YiyosaGel ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: YGColors.gold),
                                  ),
                                  TextSpan(
                                    text: 'Kullanım Şartları ve Kullanıcı Sözleşmesini ',
                                    style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: 'okudum, onaylıyorum ve kabul ediyorum.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
