import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/firebase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/question_stage.dart';
import '../../widgets/avatar_bubble.dart';

class LiveGameScreen extends ConsumerStatefulWidget {
  const LiveGameScreen({super.key, this.code, this.publicMode = true});

  final String? code;
  final bool publicMode;

  @override
  ConsumerState<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends ConsumerState<LiveGameScreen> {
  String? _code;
  Map<String, dynamic> _room = {};
  StreamSubscription? _sub;
  final TextEditingController _inputController = TextEditingController();
  bool _loading = true;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _enterRoom();
  }

  Future<void> _enterRoom() async {
    final profile = ref.read(profileProvider);
    final displayName = profile?.name ?? 'Misafir Oyuncu';
    final avatar = profile?.avatar ?? '🍄';

    try {
      if (widget.publicMode) {
        final data = Map<String, dynamic>.from(
          await FirebaseService.instance.callFunction('enterPublicMode', {
            'mode': 'live',
            'name': displayName,
            'avatar': avatar,
          }),
        );
        _code = data['code']?.toString();
      } else {
        _code = widget.code;
      }

      if (_code == null) throw Exception("Oda kodu alınamadı.");

      _sub = FirebaseService.instance.roomsRef.child(_code!).onValue.listen((event) {
        if (!mounted) return;
        final val = event.snapshot.value;
        if (val != null) {
          setState(() {
            _room = Map<String, dynamic>.from(val as Map);
            _loading = false;
          });
          _startTimer();
        }
      });
    } catch (e) {
      _showToast('Odaya girilemedi: $e');
      Navigator.maybePop(context);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final round = Map<String, dynamic>.from(_room['currentRound'] ?? {});
    if (round.isEmpty) return;

    final endsAt = int.tryParse(round['endsAt']?.toString() ?? '0') ?? 0;
    if (endsAt == 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = ((endsAt - now) / 1000).round();
      setState(() {
        _secondsLeft = max(0, diff);
      });
      if (_secondsLeft <= 0) {
        _timer?.cancel();
      }
    });
  }

  Future<void> _startRound() async {
    if (_code == null) return;
    try {
      await FirebaseService.instance.callFunction('startRound', {
        'code': _code,
        'mode': widget.publicMode ? 'live' : 'daily',
      });
    } catch (e) {
      _showToast('Tur başlatılamadı: $e');
    }
  }

  Future<void> _submit() async {
    final round = Map<String, dynamic>.from(_room['currentRound'] ?? {});
    final answer = _inputController.text.trim();

    if (round.isEmpty || _code == null) return;
    if (answer.isEmpty) {
      _inputController.clear();
      return;
    }

    final letter = round['letter']?.toString() ?? '';
    if (!YGHelpers.normalizeAnswer(answer).startsWith(YGHelpers.normalizeAnswer(letter))) {
      _showToast('Cevap $letter harfiyle başlamalıdır.');
      return;
    }

    try {
      await FirebaseService.instance.callFunction('submitAnswer', {
        'code': _code,
        'roundId': round['id'],
        'answer': answer,
      });
      _inputController.clear();
    } catch (e) {
      _showToast('Cevap gönderilemedi: $e');
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: YGColors.gold)),
      );
    }

    final round = Map<String, dynamic>.from(_room['currentRound'] ?? {});
    final prompt = round['prompt']?.toString() ??
        (_room['status'] == 'lobby' ? 'Oyuncular bekleniyor' : 'Soru hazırlanıyor');
    final letter = round['letter']?.toString() ?? '';

    // Active players list
    final players = <Map<String, dynamic>>[];
    if (_room['players'] is Map) {
      final pMap = _room['players'] as Map;
      pMap.forEach((key, val) {
        players.add({'uid': key, ...Map<String, dynamic>.from(val as Map)});
      });
      players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.publicMode ? 'Tur (7/24 Canlı)' : 'Oda Kodu: $_code',
          style: const TextStyle(fontWeight: FontWeight.w950),
        ),
        actions: [
          if (_room['status'] == 'lobby')
            TextButton(
              onPressed: _startRound,
              child: const Text('BAŞLAT', style: TextStyle(color: YGColors.green, fontWeight: FontWeight.w950)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Game Round Stage
          Expanded(
            flex: 3,
            child: QuestionStage(
              questions: round.isEmpty ? const [] : [round],
              currentIndex: 0,
              secondsLeft: _secondsLeft,
              records: const {},
              prompt: prompt,
              letter: letter,
              controller: _inputController,
              onSubmit: _submit,
            ),
          ),

          // Live Scores list
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.stars, color: YGColors.gold),
                SizedBox(width: 8),
                Text('Canlı Skor Tablosu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: players.length,
              itemBuilder: (context, i) {
                final player = players[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 16),
                  child: Row(
                    children: [
                      Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      AvatarBubble(avatar: player['avatar']?.toString() ?? '🍄', size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          player['name']?.toString() ?? 'Oyuncu',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${player['score'] ?? 0} P',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: YGColors.gold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
