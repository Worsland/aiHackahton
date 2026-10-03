import 'package:flutter_test/flutter_test.dart';

import '../lib/services/lang/app_language.dart';
import '../lib/services/offline/offline_patient_brain.dart';
import '../lib/services/offline/offline_scenarios.dart';
import '../lib/services/offline/offline_voice_player.dart';
import '../lib/widgets/patient_avatar.dart' show PatientLook;

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

  test('all built-in scenarios have Yorùbá offline variants', () {
    for (final scenario in OfflineScenarios.all) {
      final localized = OfflineScenarios.forTitle(
        scenario.title,
        language: AppLanguage.yoruba,
      );

      expect(localized, isNotNull, reason: scenario.title);
      expect(localized!.language, AppLanguage.yoruba, reason: scenario.title);
      expect(localized.keyPoints, isNotEmpty, reason: scenario.title);
      expect(localized.clinicalInfo.correctDiagnosis, isNotEmpty);
    }
  });

  test('Yorùbá postpartum and dehydration inputs use localized dialogue', () {
    final postpartum = OfflinePatientBrain(
      OfflineScenarios.yorubaPostpartumBleeding,
    );
    final postpartumReply = postpartum.reply(
      'Ọjọ́ mélòó ni ó ti kọjá tí o ti bí ọmọ?',
    );
    expect(postpartumReply.audioId, 'delai_accouchement');
    expect(postpartumReply.text, contains('Mo bí ọmọ'));

    final dehydration = OfflinePatientBrain(OfflineScenarios.yorubaDehydration);
    final dehydrationReply = dehydration.reply('Omi mélòó ni o mu lónìí?');
    expect(dehydrationReply.audioId, 'boisson');
    expect(dehydrationReply.text, contains('Mi ò mu omi'));
  });

  test('Yorùbá audio lookup never falls back to the English asset folder', () {
    final reply = OfflineReply('Ọ̀rọ̀ Yorùbá', 'fallback_0');
    expect(
      OfflineVoicePlayer.assetPathFor(
        PatientLook.woman,
        reply,
        AppLanguage.yoruba,
      ),
      'audio/offline/yo/woman/fallback_0.mp3',
    );
    expect(
      OfflineVoicePlayer.assetPathFor(
        PatientLook.woman,
        reply,
        AppLanguage.english,
      ),
      'audio/offline/woman/fallback_0.mp3',
    );
  });
}
