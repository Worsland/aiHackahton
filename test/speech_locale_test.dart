import 'package:flutter_test/flutter_test.dart';

import '../lib/services/lang/speech_locale.dart';

void main() {
  test('resolves a matching locale independent of separator/case', () {
    expect(SpeechLocale.resolve('yo_NG', ['en-US', 'yo-ng']), 'yo-ng');
  });

  test('allows a regional English locale when en_US is not installed', () {
    expect(SpeechLocale.resolve('en_US', ['en-GB', 'fr-FR']), 'en-GB');
  });

  test('does not silently substitute English for Yoruba', () {
    expect(SpeechLocale.resolve('yo_NG', ['en-US', 'fr-FR']), isNull);
  });

  test('accepts an unqualified Yoruba locale when that is all the OS exposes', () {
    expect(SpeechLocale.resolve('yo_NG', ['yo']), 'yo');
  });
}
