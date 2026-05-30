import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/question_stage.dart';
import '../../widgets/result_view.dart';
import '../../../data/services/firebase_service.dart';

class DailyGameScreen extends StatefulWidget {
  const DailyGameScreen({super.key});

  @override
  State<DailyGameScreen> createState() => _DailyGameScreenState();
}

class _DailyGameScreenState extends State<DailyGameScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _questions = [];
  final Map<String, Map<String, dynamic>> _records = {};
  int _currentIndex = 0;
  int _secondsLeft = 300;
  Timer? _timer;
  final TextEditingController _inputController = TextEditingController();
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    try {
      final data = Map<String, dynamic>.from(
        await FirebaseService.instance.callFunction('startDailySession'),
      );

      if (data['played'] == true) {
        setState(() {
          _result = Map<String, dynamic>.from(data['result'] ?? data);
          _loading = false;
        });
        return;
      }

      final rawList = data['questions'] as List;
      _questions = rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      _secondsLeft = int.tryParse(data['durationSeconds']?.toString() ?? '300') ?? 300;

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _secondsLeft = max(0, _secondsLeft - 1);
        });
        if (_secondsLeft == 0) {
          _finishSession();
        }
      });
    } catch (e) {
      _showToast('Oyun başlatılamadı: $e');
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    setState(() => _loading = true);

    final answers = _questions.map((q) {
      final r = _records[q['id']] ?? {};
      return {
        'id': q['id'],
        'letter': q['letter'],
        'userAnswer': r['userAnswer'] ?? '',
      };
    }).toList();

    try {
      final res = Map<String, dynamic>.from(
        await FirebaseService.instance.callFunction('finishDailySession', {'answers': answers}),
      );
      setState(() {
        _result = Map<String, dynamic>.from(res['result'] ?? res);
      });
    } catch (e) {
      _showToast('Skor kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _submit() {
    if (_questions.isEmpty || _result != null) return;
    final q = _questions[_currentIndex];
    final answer = _inputController.text.trim();
    final letter = q['letter']?.toString() ?? '';

    if (answer.isNotEmpty &&
        !YGHelpers.normalizeAnswer(answer).startsWith(YGHelpers.normalizeAnswer(letter))) {
      _showToast('Cevap $letter harfiyle başlamalıdır.');
      return;
    }

    final qId = q['id']?.toString() ?? '';
    final accepted = {
      YGHelpers.normalizeAnswer(q['answerNormalized']?.toString() ?? ''),
      ...(q['aliasesNormalized'] is List
          ? (q['aliasesNormalized'] as List).map((e) => YGHelpers.normalizeAnswer(e.toString()))
          : const [])
    };

    final status = answer.isEmpty
        ? 'pass'
        : (accepted.contains(YGHelpers.normalizeAnswer(answer)) ? 'correct' : 'wrong');

    setState(() {
      _records[qId] = {
        'status': status,
        'userAnswer': answer,
      };
    });

    _inputController.clear();

    final next = _getNextIndex();
    if (next == -1) {
      _finishSession();
    } else {
      setState(() {
        _currentIndex = next;
      });
    }
  }

  int _getNextIndex() {
    for (int offset = 1; offset <= _questions.length; offset++) {
      final next = (_currentIndex + offset) % _questions.length;
      final nextId = _questions[next]['id']?.toString() ?? '';
      if (!_records.containsKey(nextId)) return next;
    }
    return -1;
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
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

    if (_result != null) {
      return ResultView(
        title: 'GÜNLÜK REKABETÇİ',
        result: _result!,
        onDone: () => Navigator.pop(context),
      );
    }

    final q = _questions.isEmpty ? null : _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Rekabetçi', style: TextStyle(fontWeight: FontWeight.w950)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: q == null
          ? const Center(child: Text('Soru yüklenemedi.'))
          : QuestionStage(
              questions: _questions,
              currentIndex: _currentIndex,
              secondsLeft: _secondsLeft,
              records: _records,
              prompt: q['prompt']?.toString() ?? '',
              letter: q['letter']?.toString() ?? '',
              controller: _inputController,
              onSubmit: _submit,
            ),
    );
  }
}
