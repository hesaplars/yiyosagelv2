import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/firebase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/question_stage.dart';
import '../../widgets/result_view.dart';

class CustomGameScreen extends ConsumerStatefulWidget {
  const CustomGameScreen({super.key, required this.quiz});

  final Map<String, dynamic> quiz;

  @override
  ConsumerState<CustomGameScreen> createState() => _CustomGameScreenState();
}

class _CustomGameScreenState extends ConsumerState<CustomGameScreen> {
  late List<Map<String, dynamic>> _questions;
  final TextEditingController _inputController = TextEditingController();
  final Map<String, Map<String, dynamic>> _records = {};
  int _currentIndex = 0;
  int _secondsLeft = 300;
  Timer? _timer;
  Map<String, dynamic>? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initQuiz();
  }

  void _initQuiz() {
    final rawList = widget.quiz['questions'] as List? ?? [];
    _questions = rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    _secondsLeft = int.tryParse(widget.quiz['totalSeconds']?.toString() ?? '300') ?? 300;

    FirebaseService.instance.callFunction('startCustomQuizSession', {'quizId': widget.quiz['id']}).catchError((_) {});

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsLeft = max(0, _secondsLeft - 1);
      });
      if (_secondsLeft <= 0) {
        _finishSession();
      }
    });
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
    final status = answer.isEmpty
        ? 'pass'
        : (YGHelpers.normalizeAnswer(answer) == YGHelpers.normalizeAnswer(q['answerNormalized']?.toString() ?? '')
            ? 'correct'
            : 'wrong');

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

  Future<void> _finishSession() async {
    _timer?.cancel();
    setState(() => _loading = true);

    final profile = ref.read(profileProvider);
    final displayName = profile?.name ?? 'Oyuncu';
    final avatar = profile?.avatar ?? '🍄';

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
        await FirebaseService.instance.callFunction('submitCustomQuizResult', {
          'quizId': widget.quiz['id'],
          'name': displayName,
          'avatar': avatar,
          'answers': answers,
        }),
      );
      setState(() {
        _result = Map<String, dynamic>.from(res['summary'] ?? res);
      });
    } catch (e) {
      _showToast('Skor kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: YGColors.gold)),
      );
    }

    if (_result != null) {
      return ResultView(
        title: widget.quiz['title']?.toString() ?? 'OYUN SONUCU',
        result: _result!,
        onDone: () => Navigator.pop(context),
      );
    }

    final q = _questions.isEmpty ? null : _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz['title']?.toString() ?? 'Kelime Oyunu', style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: q == null
          ? const Center(child: Text('Soru bulunamadı.'))
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
