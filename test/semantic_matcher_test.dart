// À placer dans test/. Ces tests vérifient la mécanique (index, seuils)
// avec un faux embedder : ils ne mesurent PAS la qualité du vrai modèle.
// Pour cela, utilise evaluateThresholds avec le modèle réel sur ton
// appareil.
import 'package:flutter_test/flutter_test.dart';

import '../lib/services/offline/offline_patient_brain.dart';
import '../lib/services/offline/semantic_matcher.dart';
import '../lib/widgets/patient_avatar.dart' show PatientLook;

/// Faux modèle : chaque "concept" est un axe, les synonymes partagent le
/// même axe, ce qui imite (très grossièrement) la proximité sémantique.
class FakeEmbedder implements TextEmbedder {
  static const concepts = [
    ['long', 'days', 'since', 'lasted', 'duration'],
    ['fever', 'hot', 'temperature', 'feverish'],
    ['travel', 'trip', 'village', 'away'],
  ];

  @override
  Future<List<double>> embed(String text) async {
    final words = text.toLowerCase().split(RegExp(r'[^a-z]+'));
    return [
      for (final c in concepts) words.where(c.contains).length.toDouble(),
    ];
  }

  @override
  Future<List<double>> embedDocument(String text) => embed(text);
}

class AlwaysSimilarEmbedder implements TextEmbedder {
  @override
  Future<List<double>> embed(String text) async => [1, 0];

  @override
  Future<List<double>> embedDocument(String text) => embed(text);
}

class MappedEmbedder implements TextEmbedder {
  MappedEmbedder(this.vectors);

  final Map<String, List<double>> vectors;

  @override
  Future<List<double>> embed(String text) async => vectors[text] ?? [0, 0];

  @override
  Future<List<double>> embedDocument(String text) => embed(text);
}

class TaskAwareEmbedder implements TextEmbedder {
  final indexedTexts = <String>[];
  final queryTexts = <String>[];

  @override
  Future<List<double>> embed(String text) async {
    queryTexts.add(text);
    return [1, 0];
  }

  @override
  Future<List<double>> embedDocument(String text) async {
    indexedTexts.add(text);
    return [0, 1];
  }
}

void main() {
  final examples = {
    'duree': ['how many days since it started'],
    'fievre': ['is he hot with a temperature'],
    'voyage': ['did you travel away'],
  };

  Future<SemanticIndex<String>> buildIndex() async {
    final index = SemanticIndex<String>(
      embedder: FakeEmbedder(),
      textsOf: (k) => examples[k]!,
    );
    await index.build(examples.keys);
    return index;
  }

  test('cosine', () {
    expect(cosine([1, 0], [1, 0]), closeTo(1, 1e-9));
    expect(cosine([1, 0], [0, 1]), closeTo(0, 1e-9));
    expect(cosine([0, 0], [1, 1]), 0);
  });

  test('rank : la formulation différente trouve le bon point', () async {
    final index = await buildIndex();
    final r = await index.rank('for how long now');
    expect(r.first.item, 'duree');
    expect(r.first.similarity, greaterThan(0.5));
  });

  test('rank : phrase vide et hors sujet', () async {
    final index = await buildIndex();
    expect(await index.rank('   '), isEmpty);
    final r = await index.rank('hello');
    expect(r.first.similarity, 0);
  });

  test('build : indexe les documents avec la voie dédiée', () async {
    final embedder = TaskAwareEmbedder();
    final index = SemanticIndex<String>(
      embedder: embedder,
      textsOf: (_) => ['candidate answer'],
    );

    await index.build(['item']);

    expect(embedder.indexedTexts, ['candidate answer']);
    final ranked = await index.rank('question');
    expect(embedder.queryTexts, ['question']);
    expect(ranked.single.similarity, 0);
  });

  test(
    'evaluateThresholds : un seuil trop bas accepte le hors-sujet',
    () async {
      final index = await buildIndex();
      final res = await index.evaluateThresholds(
        [('for how long now', 'duree'), ('hello', null)],
        [0.0, 0.5],
      );
      expect(res[0.0], 0.5);
      expect(res[0.5], 1.0);
    },
  );

  test('replyAsync : un mot aléatoire ne valide aucun point clé', () async {
    const scenario = OfflineScenario(
      title: 'Test',
      look: PatientLook.woman,
      keyPoints: [
        KeyPoint(
          id: 'duration',
          label: 'Asked about duration',
          keywords: ['how long', 'days'],
          examples: ['When did this begin?'],
          reply: 'It started two days ago.',
        ),
      ],
      fallbackReplies: ['Could you rephrase that?'],
      repeatReplies: ['I already told you.'],
      clinicalInfo: ScenarioClinicalInfo(
        displayTitle: 'Test',
        correctDiagnosis: 'Test',
        distractors: [],
        alertSigns: [],
        symptoms: [],
        management: '',
      ),
    );
    final brain = OfflinePatientBrain(scenario);
    await brain.enableSemantic(AlwaysSimilarEmbedder());

    final reply = await brain.replyAsync('kdjjhfytehgffdhg');

    expect(reply.text, 'Could you rephrase that?');
    expect(brain.askedKeyPoints, isEmpty);
  });

  test(
    'replyAsync : les mots-clés du scénario priment sur les embeddings',
    () async {
      const scenario = OfflineScenario(
        title: 'Test',
        look: PatientLook.woman,
        keyPoints: [
          KeyPoint(
            id: 'duration',
            label: 'Asked about duration',
            keywords: ['how long'],
            examples: ['duration example'],
            reply: 'It started two days ago.',
          ),
          KeyPoint(
            id: 'fever',
            label: 'Asked about fever',
            keywords: ['fever'],
            examples: ['fever example'],
            reply: 'I have a fever.',
          ),
        ],
        fallbackReplies: ['Could you rephrase that?'],
        repeatReplies: ['I already told you.'],
        clinicalInfo: ScenarioClinicalInfo(
          displayTitle: 'Test',
          correctDiagnosis: 'Test',
          distractors: [],
          alertSigns: [],
          symptoms: [],
          management: '',
        ),
      );
      final brain = OfflinePatientBrain(scenario);
      await brain.enableSemantic(
        MappedEmbedder({
          'Asked about duration. It started two days ago.': [0, 1],
          'Asked about fever. I have a fever.': [1, 0],
          'How long has this been happening?': [0, 1],
        }),
      );

      final reply = await brain.replyAsync('How long has this been happening?');

      expect(reply.text, 'It started two days ago.');
    },
  );

  test(
    'replyAsync : une paraphrase du même point reçoit une réponse répétition',
    () async {
      const scenario = OfflineScenario(
        title: 'Test',
        look: PatientLook.woman,
        keyPoints: [
          KeyPoint(
            id: 'duration',
            label: 'Asked about duration',
            keywords: ['how long'],
            examples: ['duration example'],
            reply: 'It started two days ago.',
          ),
          KeyPoint(
            id: 'fever',
            label: 'Asked about fever',
            keywords: ['fever'],
            examples: ['fever example'],
            reply: 'I have a fever.',
          ),
        ],
        fallbackReplies: ['Could you rephrase that?'],
        repeatReplies: ['I already told you.'],
        clinicalInfo: ScenarioClinicalInfo(
          displayTitle: 'Test',
          correctDiagnosis: 'Test',
          distractors: [],
          alertSigns: [],
          symptoms: [],
          management: '',
        ),
      );
      final brain = OfflinePatientBrain(scenario);
      await brain.enableSemantic(
        MappedEmbedder({
          'Asked about duration. It started two days ago.': [1, 0],
          'Asked about fever. I have a fever.': [0, 1],
          'Describe the duration, please.': [1, 0],
          'Could you tell me its timespan?': [1, 0],
        }),
      );

      expect(
        (await brain.replyAsync('Describe the duration, please.')).text,
        'It started two days ago.',
      );
      expect(
        (await brain.replyAsync('Could you tell me its timespan?')).text,
        'I already told you.',
      );
    },
  );

  test(
    'replyAsync : une correspondance sémantique ambiguë retombe en fallback',
    () async {
      const scenario = OfflineScenario(
        title: 'Test',
        look: PatientLook.woman,
        keyPoints: [
          KeyPoint(
            id: 'duration',
            label: 'Asked about duration',
            keywords: ['how long'],
            examples: ['duration example'],
            reply: 'It started two days ago.',
          ),
          KeyPoint(
            id: 'fever',
            label: 'Asked about fever',
            keywords: ['fever'],
            examples: ['fever example'],
            reply: 'I have a fever.',
          ),
        ],
        fallbackReplies: ['Could you rephrase that?'],
        repeatReplies: ['I already told you.'],
        clinicalInfo: ScenarioClinicalInfo(
          displayTitle: 'Test',
          correctDiagnosis: 'Test',
          distractors: [],
          alertSigns: [],
          symptoms: [],
          management: '',
        ),
      );
      final brain = OfflinePatientBrain(scenario);
      await brain.enableSemantic(
        MappedEmbedder({
          'Asked about duration. It started two days ago.': [1, 0],
          'Asked about fever. I have a fever.': [0, 1],
          'An unrelated ambiguous question': [1, 1],
        }),
      );

      final reply = await brain.replyAsync('An unrelated ambiguous question');

      expect(reply.text, 'Could you rephrase that?');
      expect(brain.askedKeyPoints, isEmpty);
    },
  );
}
