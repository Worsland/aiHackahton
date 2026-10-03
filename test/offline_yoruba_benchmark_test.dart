import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aihackaton/services/offline/offline_patient_brain.dart';
import 'package:aihackaton/services/offline/offline_scenarios.dart';

void main() {
  test('Yoruba lexical benchmark: positives, repeats and safe abstentions', () {
    final benchmark =
        jsonDecode(
              File(
                'test/data/offline_yoruba_question_cases.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final cases = benchmark['cases'] as List<dynamic>;
    final scenario = OfflineScenarios.yorubaFeverChild;
    var positiveCorrect = 0;
    var positiveTotal = 0;
    var negativeAbstained = 0;
    var negativeTotal = 0;
    var repeatsCorrect = 0;
    var repeatTotal = 0;

    for (final rawCase in cases) {
      final testCase = rawCase as Map<String, dynamic>;
      final brain = OfflinePatientBrain(scenario);
      final type = testCase['type'] as String;
      final setupQuestions =
          (testCase['setupQuestions'] as List<dynamic>?)?.cast<String>() ??
          const <String>[];
      for (final question in setupQuestions) {
        brain.reply(question);
      }

      final reply = brain.reply(testCase['question'] as String);
      final expectedKeyPointId = testCase['expectedKeyPointId'] as String?;

      switch (type) {
        case 'positive':
          positiveTotal++;
          final matched = scenario.keyPoints
              .where((point) => point.id == expectedKeyPointId)
              .single;
          final correct =
              reply.audioId == matched.id &&
              !reply.needsRephrase &&
              brain.askedKeyPoints.any((point) => point.id == matched.id);
          if (correct) positiveCorrect++;
          expect(
            correct,
            isTrue,
            reason: 'Failed benchmark case ${testCase['id']}',
          );
        case 'negative':
          negativeTotal++;
          final safelyAbstained =
              reply.needsRephrase && brain.askedKeyPoints.isEmpty;
          if (safelyAbstained) negativeAbstained++;
          expect(
            safelyAbstained,
            isTrue,
            reason: 'Unsafe or non-abstaining case ${testCase['id']}',
          );
        case 'repeat':
          repeatTotal++;
          final repeated =
              reply.audioId.startsWith('repeat_') &&
              brain.askedKeyPoints
                      .where((point) => point.id == expectedKeyPointId)
                      .length ==
                  1;
          if (repeated) repeatsCorrect++;
          expect(
            repeated,
            isTrue,
            reason: 'Failed repeat case ${testCase['id']}',
          );
        default:
          fail('Unknown benchmark case type: $type');
      }
    }

    // Exact lexical fixture performance for this authored, non-representative
    // set. Device STT, embeddings and human language quality are not measured.
    // ignore: avoid_print
    print(
      'YO lexical benchmark: positives $positiveCorrect/$positiveTotal, '
      'safe abstentions $negativeAbstained/$negativeTotal, '
      'repeats $repeatsCorrect/$repeatTotal',
    );
  });
}
