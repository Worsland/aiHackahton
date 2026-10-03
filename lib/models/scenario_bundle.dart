import 'package:flutter/material.dart';

import '../services/offline/offline_patient_brain.dart';
import '../services/patient_scenario.dart';
import '../widgets/patient_avatar.dart';

/// Icônes utilisables par un scénario synchronisé. Volontairement une
/// liste fermée plutôt que de faire voyager une `IconData` brute : un
/// document Firestore ne doit jamais pouvoir injecter n'importe quoi dans
/// l'app, juste choisir parmi un catalogue connu et sûr.
const Map<String, IconData> scenarioIconCatalog = {
  'child_care': Icons.child_care_rounded,
  'pregnant_woman': Icons.pregnant_woman_rounded,
  'water_drop': Icons.water_drop_rounded,
  'coronavirus': Icons.coronavirus_rounded,
  'sick': Icons.sick_rounded,
  'bloodtype': Icons.bloodtype_rounded,
  'elderly': Icons.elderly_rounded,
  'medical_default': Icons.medical_information_rounded,
};

/// Version "sur le fil" d'un [KeyPoint] (défini dans
/// `offline_patient_brain.dart`) : mêmes champs, mais avec un
/// `toMap`/`fromMap` pour Firestore, ce qu'une classe `const` ne peut pas
/// avoir proprement.
class RemoteKeyPoint {
  const RemoteKeyPoint({
    required this.id,
    required this.label,
    required this.keywords,
    required this.reply,
    this.critical = false,
  });

  final String id;
  final String label;
  final List<String> keywords;
  final String reply;
  final bool critical;

  factory RemoteKeyPoint.fromMap(Map<String, dynamic> map) => RemoteKeyPoint(
    id: map['id'] as String,
    label: map['label'] as String,
    keywords: List<String>.from(map['keywords'] as List? ?? const []),
    reply: map['reply'] as String,
    critical: map['critical'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'keywords': keywords,
    'reply': reply,
    'critical': critical,
  };

  KeyPoint toKeyPoint() => KeyPoint(
    id: id,
    label: label,
    keywords: keywords,
    reply: reply,
    critical: critical,
  );
}

class RemoteAlertSign {
  const RemoteAlertSign({required this.trigger, required this.cause});

  final String trigger;
  final String cause;

  factory RemoteAlertSign.fromMap(Map<String, dynamic> map) =>
      RemoteAlertSign(
        trigger: map['trigger'] as String,
        cause: map['cause'] as String,
      );

  Map<String, dynamic> toMap() => {'trigger': trigger, 'cause': cause};

  AlertSign toAlertSign() => AlertSign(trigger: trigger, cause: cause);
}

/// Un scénario complet tel qu'il peut être ajouté depuis la console
/// Firestore (collection `scenarios`), sans toucher au code de l'app.
///
/// Reprend exactement les champs qu'un scénario embarqué (`PatientScenario`
/// + `OfflineScenario` + `ScenarioClinicalInfo`) réunit à la main dans le
/// code — c'est la version "donnée" du même contenu, convertible vers les
/// mêmes types internes via [toPatientScenario] / [toOfflineScenario].
class ScenarioBundle {
  const ScenarioBundle({
    required this.title,
    required this.description,
    required this.systemPrompt,
    required this.iconName,
    required this.difficulty,
    required this.lookName,
    required this.keyPoints,
    required this.fallbackReplies,
    required this.repeatReplies,
    required this.displayTitle,
    required this.correctDiagnosis,
    required this.distractors,
    required this.alertSigns,
    required this.symptoms,
    required this.management,
  });

  /// Identifiant interne, jamais montré à l'agent (sert de clé partout,
  /// comme `PatientScenario.title` pour les scénarios embarqués).
  final String title;
  final String description;
  final String systemPrompt;

  /// Clé dans [scenarioIconCatalog].
  final String iconName;

  /// 'Easy' / 'Medium' / 'Hard'. (Les anciens documents Firestore en
  /// 'Facile' / 'Moyen' / 'Difficile' sont convertis à la lecture, voir
  /// `ScenarioBundle.fromMap`.)
  final String difficulty;

  /// Nom d'une valeur de [PatientLook] (ex: 'woman', 'man'...) : un
  /// scénario synchronisé choisit parmi les personnages déjà dessinés, il
  /// ne peut pas en introduire un nouveau (ça demanderait de nouveaux SVG).
  final String lookName;

  final List<RemoteKeyPoint> keyPoints;
  final List<String> fallbackReplies;
  final List<String> repeatReplies;

  final String displayTitle;
  final String correctDiagnosis;
  final List<String> distractors;
  final List<RemoteAlertSign> alertSigns;
  final List<String> symptoms;
  final String management;

  IconData get icon =>
      scenarioIconCatalog[iconName] ?? scenarioIconCatalog['medical_default']!;

  PatientLook get look => PatientLook.values.firstWhere(
    (l) => l.name == lookName,
    orElse: () => PatientLook.woman,
  );

  PatientScenario toPatientScenario() => PatientScenario(
    title: title,
    description: description,
    systemPrompt: systemPrompt,
  );

  OfflineScenario toOfflineScenario() => OfflineScenario(
    title: title,
    look: look,
    keyPoints: keyPoints.map((k) => k.toKeyPoint()).toList(),
    fallbackReplies: fallbackReplies,
    repeatReplies: repeatReplies,
    clinicalInfo: ScenarioClinicalInfo(
      displayTitle: displayTitle,
      correctDiagnosis: correctDiagnosis,
      distractors: distractors,
      alertSigns: alertSigns.map((a) => a.toAlertSign()).toList(),
      symptoms: symptoms,
      management: management,
    ),
  );

  static String _normalizeDifficulty(String? raw) {
    switch (raw) {
      case 'Easy':
      case 'Facile':
        return 'Easy';
      case 'Hard':
      case 'Difficile':
        return 'Hard';
      default:
        return 'Medium';
    }
  }

  factory ScenarioBundle.fromMap(Map<String, dynamic> map) {
    return ScenarioBundle(
      title: map['title'] as String,
      description: map['description'] as String,
      systemPrompt: map['systemPrompt'] as String,
      iconName: map['iconName'] as String? ?? 'medical_default',
      difficulty: _normalizeDifficulty(map['difficulty'] as String?),
      lookName: map['lookName'] as String? ?? 'woman',
      keyPoints: (map['keyPoints'] as List? ?? const [])
          .map((e) => RemoteKeyPoint.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      fallbackReplies: List<String>.from(
        map['fallbackReplies'] as List? ?? const [],
      ),
      repeatReplies: List<String>.from(
        map['repeatReplies'] as List? ?? const [],
      ),
      displayTitle: map['displayTitle'] as String? ?? map['title'] as String,
      correctDiagnosis: map['correctDiagnosis'] as String,
      distractors: List<String>.from(map['distractors'] as List? ?? const []),
      alertSigns: (map['alertSigns'] as List? ?? const [])
          .map(
            (e) => RemoteAlertSign.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      symptoms: List<String>.from(map['symptoms'] as List? ?? const []),
      management: map['management'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'systemPrompt': systemPrompt,
    'iconName': iconName,
    'difficulty': difficulty,
    'lookName': lookName,
    'keyPoints': keyPoints.map((k) => k.toMap()).toList(),
    'fallbackReplies': fallbackReplies,
    'repeatReplies': repeatReplies,
    'displayTitle': displayTitle,
    'correctDiagnosis': correctDiagnosis,
    'distractors': distractors,
    'alertSigns': alertSigns.map((a) => a.toMap()).toList(),
    'symptoms': symptoms,
    'management': management,
  };
}
