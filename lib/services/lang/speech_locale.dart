/// Resolves a requested BCP-47 locale to one exposed by the device speech
/// engine without ever substituting another language.
class SpeechLocale {
  const SpeechLocale._();

  static String? resolve(String requested, Iterable<String> available) {
    final normalizedRequested = _normalize(requested);
    final requestedLanguage = normalizedRequested.split('_').first;
    final candidates = available.toList();

    for (final candidate in candidates) {
      if (_normalize(candidate) == normalizedRequested) return candidate;
    }

    if (requestedLanguage == 'en') {
      for (final candidate in candidates) {
        final normalized = _normalize(candidate);
        if (normalized == 'en' || normalized.startsWith('en_')) {
          return candidate;
        }
      }
    }
    if (requestedLanguage == 'yo') {
      for (final candidate in candidates) {
        final normalized = _normalize(candidate);
        if (normalized == 'yo' || normalized.startsWith('yo_')) {
          return candidate;
        }
      }
    }
    return null;
  }

  static String _normalize(String locale) =>
      locale.replaceAll('-', '_').toLowerCase();
}
