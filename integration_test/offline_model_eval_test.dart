import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:aihackaton/services/offline/embedder_setup.dart';
import 'package:aihackaton/services/offline/offline_patient_brain.dart';
import 'package:aihackaton/services/offline/offline_scenarios.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('evaluate offline answers with the installed on-device model', (
    _,
  ) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final casesFile = File(
      '${supportDirectory.path}${Platform.pathSeparator}'
      'offline_question_cases.json',
    );
    expect(
      await casesFile.exists(),
      isTrue,
      reason: 'Run tools/run_offline_model_eval.ps1 to stage the question set.',
    );

    final data =
        jsonDecode(await casesFile.readAsString()) as Map<String, dynamic>;
    await initGemmaEmbeddings();
    final model = await loadInstalledEmbedder();
    expect(
      model,
      isNotNull,
      reason:
          'Gecko is not installed. Open offline mode online once and download it first.',
    );

    var total = 0;
    var passed = 0;
    final failures = <String>[];
    final scenarioResults = <String, (int passed, int total)>{};
    final scenarios = OfflineScenarios.all;

    for (final scenarioData in data['scenarios'] as List<dynamic>) {
      final scenarioMap = scenarioData as Map<String, dynamic>;
      final scenarioId = scenarioMap['id'] as String;
      final scenario = scenarios.singleWhere(
        (candidate) => candidate.title == scenarioMap['title'],
      );
      final brain = OfflinePatientBrain(scenario);
      await brain.enableSemantic(model!);

      for (final rawCase in scenarioMap['cases'] as List<dynamic>) {
        final testCase = rawCase as Map<String, dynamic>;
        final caseId = testCase['id'] as String;
        final type = testCase['type'] as String;
        brain.reset();

        for (final setupQuestion
            in (testCase['setupQuestions'] as List<dynamic>? ??
                const <dynamic>[])) {
          await brain.replyAsync(setupQuestion as String);
        }

        final reply = await brain.replyAsync(testCase['question'] as String);
        final expectedKeyPointId = testCase['expectedKeyPointId'] as String?;
        final expectedReply = testCase['expectedReply'] as String?;
        final options = (testCase['expectedReplyOptions'] as List<dynamic>?)
            ?.cast<String>();
        final casePassed = switch (type) {
          'positive' =>
            reply.audioId == expectedKeyPointId && reply.text == expectedReply,
          'repeat' =>
            options!.contains(reply.text) &&
                reply.audioId.startsWith('repeat_'),
          'fallback' =>
            options!.contains(reply.text) &&
                reply.audioId.startsWith('fallback_'),
          _ => throw StateError('Unsupported test case type: $type'),
        };

        total++;
        final previous = scenarioResults[scenarioId] ?? (0, 0);
        scenarioResults[scenarioId] = (
          previous.$1 + (casePassed ? 1 : 0),
          previous.$2 + 1,
        );
        if (casePassed) {
          passed++;
        } else {
          failures.add(
            '$scenarioId/$caseId [$type] '
            'expected key=$expectedKeyPointId reply=$expectedReply options=$options; '
            'actual key=${reply.audioId} reply=${reply.text}',
          );
        }
        // ignore: avoid_print
        print(
          '[offline-eval] ${casePassed ? "PASS" : "FAIL"} '
          '$scenarioId/$caseId [$type] -> ${reply.audioId}',
        );
      }
    }

    // ignore: avoid_print
    print('[offline-eval] RESULT: $passed/$total passed');
    for (final entry in scenarioResults.entries) {
      // ignore: avoid_print
      print(
        '[offline-eval] SCENARIO ${entry.key}: '
        '${entry.value.$1}/${entry.value.$2} passed',
      );
    }
    for (final failure in failures) {
      // ignore: avoid_print
      print('[offline-eval] FAILURE: $failure');
    }
    expect(passed, total, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
