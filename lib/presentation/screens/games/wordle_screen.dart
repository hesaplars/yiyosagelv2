import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/soft_pill.dart';

class WordleScreen extends StatefulWidget {
  const WordleScreen({super.key});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  static const String _targetWord = 'KUBBE'; // Default target word (can be fetched from service)
  final List<String> _guesses = [];
  String _currentInput = '';
  final int _maxGuesses = 5;

  void _onKeyPress(String ch) {
    if (_currentInput.length < 5) {
      setState(() {
        _currentInput += ch;
      });
    }
  }

  void _onDelete() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      });
    }
  }

  void _onSubmit() {
    if (_currentInput.length == 5) {
      setState(() {
        _guesses.add(_currentInput);
        _currentInput = '';
      });

      if (_guesses.last == _targetWord) {
        _showToast('Tebrikler! Kelimeyi doğru bildiniz! 🎉');
      } else if (_guesses.length >= _maxGuesses) {
        _showToast('Oyun bitti! Doğru kelime: $_targetWord idi.');
      }
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: YGColors.gold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Tahmin', style: TextStyle(fontWeight: FontWeight.w950)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Wordle grid (5 rows of 5 letter blocks)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_maxGuesses, (rowIndex) {
                      final guess = rowIndex < _guesses.length ? _guesses[rowIndex] : (rowIndex == _guesses.length ? _currentInput : '');
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (charIndex) {
                          final char = charIndex < guess.length ? guess[charIndex] : '';
                          
                          Color cellColor = isDark ? YGColors.darkSurface : YGColors.lightSurface;
                          Color textColor = isDark ? YGColors.darkText : YGColors.lightText;
                          
                          if (rowIndex < _guesses.length && char.isNotEmpty) {
                            if (_targetWord[charIndex] == char) {
                              cellColor = YGColors.green;
                              textColor = Colors.white;
                            } else if (_targetWord.contains(char)) {
                              cellColor = YGColors.gold2;
                              textColor = Colors.white;
                            } else {
                              cellColor = isDark ? Colors.white10 : Colors.black12;
                            }
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.all(4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? YGColors.lineDark : YGColors.lineLight,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              char,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w950,
                                color: textColor,
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Virtual Keyboard (Turkish Letters)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? YGColors.darkSurface : YGColors.lightSurface,
                border: Border(top: BorderSide(color: isDark ? YGColors.lineDark : YGColors.lineLight)),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildKeyboardRow('ERTÝUÝOPÐÜ'), // Turkish Keyboard Layout compatibility
                  _buildKeyboardRow('ASDFGHJKLÞÝ'),
                  _buildKeyboardRow('ZXCVBNMÖÇ'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _currentInput.isNotEmpty ? _onDelete : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: YGColors.red.withOpacity(0.15),
                              foregroundColor: YGColors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('SİL', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _currentInput.length == 5 ? _onSubmit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: YGColors.green.withOpacity(0.15),
                              foregroundColor: YGColors.green,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('ONAYLA', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(String rowLetters) {
    // Standardize to Turkish equivalents if mapped with typos
    final List<String> lettersList = rowLetters
        .replaceAll('Ý', 'I')
        .replaceAll('Ð', 'Ğ')
        .replaceAll('Þ', 'Ş')
        .replaceAll('Ý', 'İ')
        .split('');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Wrap(
        spacing: 4,
        alignment: WrapAlignment.center,
        children: lettersList.map((ch) {
          return SizedBox(
            width: 32,
            height: 38,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onKeyPress(ch),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.black05,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ch,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
