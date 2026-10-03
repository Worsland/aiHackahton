import 'package:flutter_test/flutter_test.dart';

import '../lib/services/lang/yoruba_normalizer.dart';
import '../lib/services/offline/offline_text_match.dart';

void main() {
  group('YorubaNormalizer', () {
    test('normalizes Yoruba letters and tone marks', () {
      expect(
        YorubaNormalizer.normalize('Ṣé ọmọ náà ń ṣeré?'),
        'se omo naa n sere?',
      );
    });

    test('normalizes decomposed Yoruba diacritics', () {
      expect(YorubaNormalizer.normalize('Ṣe\u0323\u0301 ọmọ'), 'se omo');
    });
  });

  test('lexical matching accepts Yoruba text with or without diacritics', () {
    final withDiacritics = TextMatch.rank<String>(
      ['mosquito-net'],
      (_) => ['àwọn ẹ̀fọn', 'àpapọ̀ ẹ̀fọn'],
      'Ṣé ọmọ náà ń sùn lábẹ́ àwọ̀n ẹ̀fọn?',
    );
    final withoutDiacritics = TextMatch.rank<String>(
      ['mosquito-net'],
      (_) => ['àwọn ẹ̀fọn', 'àpapọ̀ ẹ̀fọn'],
      'Se omo naa n sun labe awon efon?',
    );

    expect(withDiacritics.single.item, 'mosquito-net');
    expect(withoutDiacritics.single.item, 'mosquito-net');
  });
}
