class YGHelpers {
  YGHelpers._();

  static String normalizeAnswer(String value) {
    final lower = value.toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
    return lower.replaceAll(RegExp(r'[^a-z0-9\s-]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String two(int value) => value.toString().padLeft(2, '0');

  static String todayKey() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  static String formatDateOnly(Object? ms) {
    if (ms == null) return '';
    final value = int.tryParse('$ms');
    if (value == null || value <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(value);
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  static String slotForType(String type) {
    switch (type) {
      case 'avatarFrame':
      case 'frame':
        return 'avatarFrameId';
      case 'cover':
        return 'coverId';
      case 'badge':
        return 'badgeIds';
      case 'avatarBadge':
        return 'avatarBadgeId';
      case 'title':
        return 'titleId';
      case 'chatStyle':
        return 'chatStyleId';
      default:
        return type;
    }
  }

  static const List<String> badWords = [
    "orospu", "orosbucocuk", "sik", "sike", "sikik", "sikim", "sikeyim", "bok",
    "boktan", "got", "amk", "amina", "amcik", "pic", "pizlik", "yarrak", "yarak",
    "oc", "ibne", "fahise", "kahpe", "pezevenk", "kancik", "gotveren", "pust",
  ];

  static bool containsBadWord(String text) {
    final normalized = normalizeAnswer(text).replaceAll(RegExp(r'[^a-z0-9]'), ' ');
    final tokens = normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    for (final word in badWords) {
      final normalizedWord = normalizeAnswer(word);
      if (tokens.contains(normalizedWord) || normalized.contains(normalizedWord)) {
        return true;
      }
    }
    return false;
  }
}
