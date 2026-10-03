/// Normalizes Yorùbá orthography for lexical matching.
///
/// Tone marks are intentionally discarded for matching only; displayed
/// scenario text must retain its original spelling.
class YorubaNormalizer {
  YorubaNormalizer._();

  static final _combiningMarks = RegExp(
    '[\u0300-\u036f\u1ab0-\u1aff\u1dc0-\u1dff\u20d0-\u20ff\ufe20-\ufe2f]',
  );
  static final _accentedVowels = <RegExp, String>{
    RegExp('[àáâãäå]'): 'a',
    RegExp('[èéêë]'): 'e',
    RegExp('[ìíîï]'): 'i',
    RegExp('[òóôõö]'): 'o',
    RegExp('[ùúûü]'): 'u',
    RegExp('[ýÿ]'): 'y',
  };

  static String normalize(String text) {
    var normalized = text
        .toLowerCase()
        .replaceAll('ẹ', 'e')
        .replaceAll('ọ', 'o')
        .replaceAll('ṣ', 's')
        .replaceAll('ń', 'n')
        .replaceAll('ǹ', 'n')
        .replaceAll(_combiningMarks, '');
    for (final entry in _accentedVowels.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized;
  }
}
