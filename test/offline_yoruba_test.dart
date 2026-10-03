import 'package:flutter_test/flutter_test.dart';

import '../lib/services/lang/app_language.dart';
import '../lib/services/offline/offline_patient_brain.dart';
import '../lib/services/offline/offline_scenarios.dart';

void main() {
  test('Yoruba selection loads a localized offline fever scenario', () {
    final scenario = OfflineScenarios.forTitle(
      OfflineScenarios.feverChild.title,
      language: AppLanguage.yoruba,
    );

    expect(scenario, isNotNull);
    expect(scenario!.language, AppLanguage.yoruba);
    expect(scenario.clinicalInfo.displayTitle, contains('Ọmọ'));
    expect(scenario.keyPoints.first.reply, contains('Ọjọ́'));
  });

  test('Yoruba lexical dialogue matches questions without tone marks', () {
    final scenario = OfflineScenarios.yorubaFeverChild;
    final brain = OfflinePatientBrain(scenario);

    final reply = brain.reply('Se omo naa n sun labe awon efon?');

    expect(reply.audioId, 'moustiquaire');
    expect(reply.text, scenario.keyPoints[1].reply);
    expect(reply.needsRephrase, isFalse);
    expect(brain.askedKeyPoints.map((point) => point.id), ['moustiquaire']);
  });

  test('Yoruba ambiguous lexical matches ask for a rephrase, not a guess', () {
    final brain = OfflinePatientBrain(OfflineScenarios.yorubaFeverChild);

    final reply = brain.reply('ìgbà àti ìlú');

    expect(reply.needsRephrase, isTrue);
    expect(brain.askedKeyPoints, isEmpty);
  });
}
