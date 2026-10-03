import 'dart:math' as math;

import '../../widgets/patient_avatar.dart' show PatientLook;
import '../lang/app_language.dart';
import 'offline_text_match.dart';
import 'semantic_matcher.dart';

/// Un signe d'alerte que le patient peut révéler, avec l'explication de sa
/// cause : c'est ce qui est montré dans la page de récapitulatif, pas
/// pendant la conversation elle-même.
class AlertSign {
  const AlertSign({required this.trigger, required this.cause});

  /// Ce que le patient a dit ou laissé entendre (ex : "Moustiquaire trouée").
  final String trigger;

  /// Pourquoi c'est un signal important, en langage clair.
  final String cause;
}

/// Fiche clinique d'un scénario : diagnostic correct, distracteurs pour le
/// QCM, signaux d'alerte expliqués, symptômes typiques, conduite à tenir.
///
/// Contenu proposé à partir de repères médicaux généraux (OMS/PCIME pour le
/// paludisme, MSF/Merck Manual pour l'endométrite du post-partum) — À FAIRE
/// VALIDER par une personne compétente avant tout usage réel, y compris en
/// entraînement. Voir ROADMAP.md.
class ScenarioClinicalInfo {
  const ScenarioClinicalInfo({
    required this.displayTitle,
    required this.correctDiagnosis,
    required this.distractors,
    required this.alertSigns,
    required this.symptoms,
    required this.management,
  });

  /// Titre neutre affiché à l'agent (liste de scénarios, en-tête de
  /// conversation) : ne doit jamais trahir le diagnostic. Remplace
  /// `PatientScenario.title` / `OfflineScenario.title` dans l'UI ; ces
  /// derniers restent des identifiants internes.
  final String displayTitle;

  final String correctDiagnosis;

  /// Diagnostics plausibles mais faux, pour le QCM.
  final List<String> distractors;

  final List<AlertSign> alertSigns;
  final List<String> symptoms;

  /// Recommandations de premier niveau (agent de santé communautaire) :
  /// reconnaître + orienter, pas un protocole de traitement détaillé.
  final String management;

  /// Options du QCM, mélangées à chaque appel pour ne pas toujours montrer
  /// le bon diagnostic à la même position.
  List<String> shuffledOptions([math.Random? rng]) {
    final options = [correctDiagnosis, ...distractors];
    options.shuffle(rng ?? math.Random());
    return options;
  }
}

/// Un point clé que l'agent de santé est censé aborder pour bien évaluer
/// le patient (ex: "a-t-il demandé s'il y a une moustiquaire ?").
///
/// C'est la même idée que le `systemPrompt` envoyé à Gemini dans les autres
/// modes ("ne révèle X que si on te le demande"), mais rendue explicite et
/// mesurable puisqu'il n'y a plus d'IA pour en juger.
class KeyPoint {
  const KeyPoint({
    required this.id,
    required this.label,
    required this.keywords,
    required this.reply,
    this.examples = const [],
    this.critical = false,
  });

  /// Identifiant stable (sert de clé, jamais affiché).
  final String id;

  /// Ce qui est montré à l'agent dans le feedback ("A demandé la durée des
  /// saignements"), à l'infinitif ou en langage clair.
  final String label;

  /// Mots ou expressions qui, présents dans la phrase de l'agent,
  /// déclenchent ce point clé. Comparaison insensible aux accents et à la
  /// casse (voir [normalize]).
  final List<String> keywords;

  /// Ce que répond le patient la première fois que ce point est abordé.
  final String reply;

  /// Formulations d'exemple (dans n'importe quelle langue) d'une question
  /// qui doit déclencher ce point. Utilisées par la compréhension
  /// sémantique, en plus de [label] : 3 à 6 phrases variées suffisent.
  final List<String> examples;

  /// Point clé qu'un agent expérimenté ne devrait jamais manquer (ex: signe
  /// de danger). Mis en avant séparément dans le feedback.
  final bool critical;
}

/// Un scénario jouable hors-ligne : quelques points clés à couvrir, une
/// réplique de repli quand rien ne correspond, une réplique quand l'agent
/// revient sur un point déjà traité.
class OfflineScenario {
  const OfflineScenario({
    required this.title,
    required this.look,
    required this.keyPoints,
    required this.fallbackReplies,
    required this.repeatReplies,
    required this.clinicalInfo,
    this.language = AppLanguage.english,
  });

  final String title;
  final AppLanguage language;

  /// Le personnage qui incarne ce scénario : détermine à la fois l'avatar
  /// animé et, en mode hors-ligne, le dossier de voix pré-enregistrée à
  /// utiliser (`assets/audio/offline/<look.assetName>/...`). Centralisé
  /// ici plutôt que recalculé séparément côté écran, pour qu'il ne puisse
  /// pas se désynchroniser du reste du contenu du scénario.
  final PatientLook look;

  final List<KeyPoint> keyPoints;

  /// Réponses possibles quand aucun mot-clé ne correspond (choisies au
  /// hasard, pour ne pas sonner robotique).
  final List<String> fallbackReplies;

  /// Réponses possibles quand l'agent repose une question déjà couverte.
  final List<String> repeatReplies;

  /// Diagnostic, signaux d'alerte, symptômes, conduite à tenir : contenu
  /// utilisé par l'écran de diagnostic et le récapitulatif, dans les trois
  /// modes (pas seulement hors-ligne, malgré le nom de la classe).
  final ScenarioClinicalInfo clinicalInfo;
}

/// Résultat d'une évaluation hors-ligne : équivalent du texte de feedback
/// généré par Gemini, mais calculé localement à partir des points couverts.
class OfflineFeedback {
  const OfflineFeedback({
    required this.hit,
    required this.missed,
    required this.total,
  });

  final List<KeyPoint> hit;
  final List<KeyPoint> missed;
  final int total;

  double get score => total == 0 ? 0 : hit.length / total;

  /// Signaux critiques manqués (ex: signe de danger jamais recherché) :
  /// c'est ce qu'il faut mettre en avant en premier dans l'UI.
  List<KeyPoint> get missedCritical => missed.where((k) => k.critical).toList();

  /// Rendu texte prêt à afficher dans la même carte que le feedback Gemini.
  String toText() {
    final pct = (score * 100).round();
    final buf = StringBuffer('Score: $pct% of key points covered.\n\n');

    if (hit.isNotEmpty) {
      buf.writeln('Well done:');
      for (final k in hit) {
        buf.writeln('• ${k.label}');
      }
    }
    if (missed.isNotEmpty) {
      buf.writeln('\nDon\'t forget next time:');
      for (final k in missed) {
        buf.writeln(
          '• ${k.label}${k.critical ? ' (important warning sign)' : ''}',
        );
      }
    }
    if (missed.isEmpty && hit.isNotEmpty) {
      buf.write('\nAll key points of this scenario were covered.');
    }
    return buf.toString().trim();
  }
}

/// Fait vivre un [OfflineScenario] : reçoit ce que dit l'agent (texte déjà
/// transcrit par le STT du téléphone), renvoie ce que répond le patient.
///
/// Entièrement local, aucun réseau : c'est un simple index sur des
/// mots-clés, pas un vrai NLP. Volontairement simple, pour rester lisible
/// et pour que chacun puisse ajouter un scénario sans notion d'IA.
/// Une réplique du patient hors-ligne, avec l'identifiant qui permet de
/// retrouver le fichier audio pré-enregistré correspondant : soit
/// l'`id` d'un [KeyPoint] (ex: `'moustiquaire'`), soit une position dans
/// `fallbackReplies`/`repeatReplies` (ex: `'fallback_0'`).
class OfflineReply {
  const OfflineReply(this.text, this.audioId, {this.needsRephrase = false});
  final String text;
  final String audioId;
  final bool needsRephrase;
}

class OfflinePatientBrain {
  OfflinePatientBrain(this.scenario);

  final OfflineScenario scenario;
  final Set<String> _asked = {};
  final math.Random _rng = math.Random();

  /// Points déjà couverts, dans l'ordre où ils l'ont été (pour un futur
  /// historique/transcript si besoin).
  List<KeyPoint> get askedKeyPoints =>
      scenario.keyPoints.where((k) => _asked.contains(k.id)).toList();

  /// Traite une phrase de l'agent et renvoie la réplique du patient, avec
  /// son identifiant (`audioId`) : c'est ce qui permet à l'écran de
  /// retrouver le bon fichier audio pré-enregistré, voir
  /// `OfflineVoicePlayer`. Ne retourne jamais de texte vide : il y a
  /// toujours une réponse, même si c'est un aveu d'incompréhension du
  /// patient.
  OfflineReply reply(String agentText) {
    final ranked = TextMatch.rank<KeyPoint>(
      scenario.keyPoints,
      (k) => k.keywords,
      agentText,
    );
    if (ranked.isEmpty) return _pick(scenario.fallbackReplies, 'fallback');

    // On répond d'abord à un point pas encore abordé : si la phrase touche
    // à la fois un sujet déjà traité et un nouveau, le patient répond au
    // nouveau au lieu de dire "je te l'ai déjà dit".
    final fresh = ranked.where((m) => !_asked.contains(m.item.id)).toList();
    if (fresh.isEmpty) return _pick(scenario.repeatReplies, 'repeat');
    if (scenario.language.isYoruba &&
        fresh.length > 1 &&
        fresh[0].score == fresh[1].score) {
      return _pick(scenario.fallbackReplies, 'fallback');
    }

    final best = fresh.first.item;
    _asked.add(best.id);
    return OfflineReply(best.reply, best.id);
  }

  /// Feedback à afficher en fin d'entretien, à la place de l'appel Gemini.
  OfflineFeedback feedback() {
    final hit = scenario.keyPoints.where((k) => _asked.contains(k.id)).toList();
    final missed = scenario.keyPoints
        .where((k) => !_asked.contains(k.id))
        .toList();
    return OfflineFeedback(
      hit: hit,
      missed: missed,
      total: scenario.keyPoints.length,
    );
  }

  void reset() => _asked.clear();

  // ---- Compréhension sémantique (modèle d'embeddings sur l'appareil) ----

  SemanticIndex<KeyPoint>? _semantic;

  /// Minimum de similarité cosinus requis pour une correspondance sémantique.
  /// Les mots-clés du scénario restent prioritaires.
  double semanticThreshold = 0.55;

  /// Écart minimal entre les deux meilleurs points afin d'éviter de répondre
  /// sur un sujet arbitraire lorsque le modèle hésite entre plusieurs sujets.
  double semanticMinimumMargin = 0.08;

  bool get semanticEnabled => _semantic != null;

  /// Indexe les réponses possibles et leur sujet. À l'arrivée d'une question,
  /// le modèle choisit la réponse existante la plus proche, sans générer de
  /// texte ni dépendre d'exemples de questions rédigés à la main.
  Future<void> enableSemantic(TextEmbedder embedder) async {
    final index = SemanticIndex<KeyPoint>(
      embedder: embedder,
      textsOf: (k) => ['${k.label}. ${k.reply}'],
    );
    await index.build(scenario.keyPoints);
    _semantic = index;
  }

  /// Comme [reply], mais comprend les reformulations et d'autres langues.
  /// Retombe sur les mots-clés si le modèle n'est pas prêt, échoue, ou ne
  /// trouve aucun point assez proche : le patient répond toujours.
  Future<OfflineReply> replyAsync(String agentText) async {
    final index = _semantic;
    if (index == null) return reply(agentText);

    final lexicalMatches = TextMatch.rank<KeyPoint>(
      scenario.keyPoints,
      (k) => k.keywords,
      agentText,
    );
    if (lexicalMatches.isNotEmpty) {
      return _replyForKeyPoint(lexicalMatches.first.item);
    }
    if (lexicalMatches.isEmpty && _looksLikeGibberish(agentText)) {
      return _pick(scenario.fallbackReplies, 'fallback');
    }

    final List<Scored<KeyPoint>> ranked;
    try {
      ranked = await index.rank(agentText);
    } catch (_) {
      return reply(agentText);
    }

    if (ranked.isEmpty || ranked.first.similarity < semanticThreshold) {
      return reply(agentText);
    }
    if (ranked.length > 1 &&
        ranked.first.similarity - ranked[1].similarity <
            semanticMinimumMargin) {
      return reply(agentText);
    }
    return _replyForKeyPoint(ranked.first.item);
  }

  OfflineReply _replyForKeyPoint(KeyPoint keyPoint) {
    if (!_asked.add(keyPoint.id)) {
      return _pick(scenario.repeatReplies, 'repeat');
    }
    return OfflineReply(keyPoint.reply, keyPoint.id);
  }

  /// Score fondé sur ce que le patient a RÉELLEMENT révélé pendant
  /// l'entretien. À utiliser en mode hors ligne à la place de
  /// `KeyPointScan.scan(...)` : avec la compréhension sémantique, une
  /// question peut déclencher un point sans contenir aucun mot-clé, et le
  /// scan par mots-clés l'ignorerait.
  KeyPointScan currentScan() => KeyPointScan(
    hit: askedKeyPoints,
    missed: scenario.keyPoints.where((k) => !_asked.contains(k.id)).toList(),
  );

  /// Choisit un élément au hasard dans [options] et construit son
  /// identifiant audio à partir de sa position (`fallback_0`, `repeat_1`,
  /// ...). Cette position doit donc rester stable : ne pas réordonner
  /// `fallbackReplies` / `repeatReplies` dans `offline_scenarios.dart`
  /// sans renommer les fichiers audio déjà enregistrés en conséquence.
  OfflineReply _pick(List<String> options, String prefix) {
    final i = _rng.nextInt(options.length);
    return OfflineReply(
      options[i],
      '${prefix}_$i',
      needsRephrase: prefix == 'fallback',
    );
  }

  bool _looksLikeGibberish(String text) {
    final words = RegExp(
      r'[a-z]+',
      caseSensitive: false,
    ).allMatches(text).map((match) => match.group(0)!.toLowerCase()).toList();
    if (words.length != 1 || words.single.length < 8) return false;

    final word = words.single;
    final vowels = RegExp(r'[aeiouy]').allMatches(word).length;
    return vowels / word.length < 0.15;
  }

  /// Minuscules, sans accents, espaces multiples réduits : rend la
  /// comparaison de mots-clés tolérante aux petites variations d'écriture
  /// ou de transcription vocale ("depuis quand" vs "Depuis Quand ?").
  ///
  /// Exposée publiquement (alias ci-dessous) : `KeyPointScan` en a besoin
  /// pour comparer les phrases de l'agent aux mots-clés, hors du contexte
  /// d'une conversation hors-ligne pas à pas.
  static String normalizeForScan(String s) => TextMatch.normalize(s);

  /// Le mot-clé doit COMMENCER à une frontière de mot dans la phrase : "eat"
  /// reconnaît "eating" mais plus "breathing", "pee" ne se déclenche plus
  /// dans "speech", "hot" pas dans "shot". Les radicaux fonctionnent
  /// toujours ("hydrat" → "hydration", "vomit" → "vomiting").
  /// [normalizedText] doit déjà être normalisé (voir [normalizeForScan]).
  static bool hasKeyword(String normalizedText, String keyword) =>
      TextMatch.containsPhrase(TextMatch.tokenize(normalizedText), keyword);
}

/// Calcule le score des points clés couverts, **de la même façon dans les
/// trois modes** (hors ligne, léger, Live) : ce n'est plus
/// `OfflinePatientBrain` qui calcule ce score en mode hors-ligne (il reste
/// responsable de faire vivre la conversation elle-même, tour par tour),
/// mais cette fonction, appliquée après coup à l'ensemble des phrases de
/// l'agent.
///
/// L'avantage : Gemini n'a plus besoin d'être consulté pour obtenir un
/// score cohérent — utile en particulier hors ligne, mais ça simplifie
/// aussi les modes Live/léger, où la couverture des points clés est
/// maintenant déterministe plutôt que jugée en langage libre.
class KeyPointScan {
  const KeyPointScan({required this.hit, required this.missed});

  final List<KeyPoint> hit;
  final List<KeyPoint> missed;

  int get total => hit.length + missed.length;
  double get coverage => total == 0 ? 0 : hit.length / total;

  List<KeyPoint> get missedCritical => missed.where((k) => k.critical).toList();

  /// Parcourt toutes les phrases de l'agent (peu importe le mode) et
  /// marque chaque point clé comme couvert dès qu'un de ses mots-clés
  /// apparaît quelque part dans la conversation.
  ///
  /// Chaque phrase ne peut valider que [maxPerUtterance] points clés (les
  /// mieux classés) : une phrase "fièvre chaud odeur douleur combien"
  /// ne donne plus tous les points d'un coup.
  factory KeyPointScan.scan(
    List<KeyPoint> keyPoints,
    Iterable<String> agentUtterances, {
    int maxPerUtterance = 2,
  }) {
    final covered = <String>{};
    for (final utterance in agentUtterances) {
      final ranked = TextMatch.rank<KeyPoint>(
        keyPoints,
        (k) => k.keywords,
        utterance,
      );
      covered.addAll(ranked.take(maxPerUtterance).map((m) => m.item.id));
    }
    final hit = <KeyPoint>[];
    final missed = <KeyPoint>[];
    for (final k in keyPoints) {
      (covered.contains(k.id) ? hit : missed).add(k);
    }
    return KeyPointScan(hit: hit, missed: missed);
  }
}

/// Score global d'une session : couverture des points clés (60 %, les
/// points critiques comptant double) + exactitude du diagnostic (40 %,
/// tout ou rien). Pondération définie dans ROADMAP.md, ajustable ici.
class SessionScore {
  const SessionScore({
    required this.scan,
    required this.diagnosisCorrect,
    this.questionsWeight = 0.6,
    this.diagnosisWeight = 0.4,
  });

  final KeyPointScan scan;
  final bool diagnosisCorrect;
  final double questionsWeight;
  final double diagnosisWeight;

  /// Couverture pondérée : chaque point critique compte pour 2, un point
  /// normal pour 1 (numérateur comme dénominateur), pour que rater un
  /// signal important pèse plus qu'une question secondaire oubliée.
  double get _weightedCoverage {
    double weight(KeyPoint k) => k.critical ? 2 : 1;
    final earned = scan.hit.fold(0.0, (sum, k) => sum + weight(k));
    final total = (scan.hit + scan.missed).fold(
      0.0,
      (sum, k) => sum + weight(k),
    );
    return total == 0 ? 0 : earned / total;
  }

  double get total =>
      _weightedCoverage * questionsWeight +
      (diagnosisCorrect ? 1 : 0) * diagnosisWeight;

  int get percent => (total * 100).round();
}
