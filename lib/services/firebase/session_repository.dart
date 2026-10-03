import 'package:cloud_firestore/cloud_firestore.dart';

/// Le résultat d'une session, prêt à être écrit dans Firestore et à
/// alimenter un futur écran de progression (historique, moyenne par
/// maladie...). Volontairement plat : pas de sous-objets imbriqués, pour
/// rester facile à filtrer/agréger côté Firestore plus tard.
class SessionRecord {
  const SessionRecord({
    required this.scenarioTitle,
    required this.mode,
    required this.scorePercent,
    required this.diagnosisCorrect,
    required this.keyPointsHit,
    required this.keyPointsTotal,
    this.completedAt,
  });

  /// Identifiant interne du scénario (`PatientScenario.title` /
  /// `OfflineScenario.title`), pas le titre neutre affiché à l'agent.
  final String scenarioTitle;

  /// 'live' / 'light' / 'offline' — texte simple plutôt que l'enum
  /// `ConversationMode` de l'écran de simulation, pour ne pas faire
  /// dépendre ce service Firebase d'un écran UI.
  final String mode;

  final int scorePercent;
  final bool diagnosisCorrect;
  final int keyPointsHit;
  final int keyPointsTotal;

  /// `null` avant écriture : Firestore le remplit via `serverTimestamp()`
  /// pour éviter tout décalage lié à l'horloge locale de l'agent.
  final DateTime? completedAt;

  Map<String, dynamic> toMap() => {
    'scenarioTitle': scenarioTitle,
    'mode': mode,
    'scorePercent': scorePercent,
    'diagnosisCorrect': diagnosisCorrect,
    'keyPointsHit': keyPointsHit,
    'keyPointsTotal': keyPointsTotal,
    'completedAt': FieldValue.serverTimestamp(),
  };

  factory SessionRecord.fromMap(Map<String, dynamic> map) => SessionRecord(
    scenarioTitle: map['scenarioTitle'] as String? ?? '',
    mode: map['mode'] as String? ?? 'offline',
    scorePercent: (map['scorePercent'] as num?)?.toInt() ?? 0,
    diagnosisCorrect: map['diagnosisCorrect'] as bool? ?? false,
    keyPointsHit: (map['keyPointsHit'] as num?)?.toInt() ?? 0,
    keyPointsTotal: (map['keyPointsTotal'] as num?)?.toInt() ?? 0,
    completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
  );
}

/// Écrit et lit les sessions d'un agent dans Firestore, sous
/// `users/{uid}/sessions/{id}`.
///
/// Ne construit pas sa propre file d'attente hors-ligne : le SDK Firestore
/// le fait déjà (persistance locale activée par défaut sur Android/iOS ;
/// à activer explicitement sur web, voir `main.dart`). Un `save()` appelé
/// hors ligne s'écrit donc localement tout de suite et se synchronise
/// automatiquement au retour du réseau, sans code supplémentaire ici.
class SessionRepository {
  SessionRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _sessionsFor(String uid) =>
      _db.collection('users').doc(uid).collection('sessions');

  /// Enregistre une session. Si [uid] est `null` (aucun compte, même pas
  /// anonyme — cas rare : tout premier lancement, jamais eu de réseau), la
  /// session n'est pas perdue silencieusement : l'appelant reçoit `false`
  /// et peut choisir de réessayer plus tard (ex : au prochain
  /// `ensureSignedIn()` réussi).
  Future<bool> save(String? uid, SessionRecord record) async {
    if (uid == null) return false;
    try {
      await _sessionsFor(uid).add(record.toMap());
      return true;
    } catch (_) {
      // Hors ligne avec persistance désactivée (web sans IndexedDB
      // disponible, par ex.) : on échoue proprement plutôt que de planter
      // l'écran de récapitulatif, qui ne doit jamais dépendre du réseau
      // pour s'afficher.
      return false;
    }
  }

  /// Historique le plus récent d'abord, pour un futur écran de
  /// progression. `limit` évite de charger des centaines de sessions d'un
  /// coup sur une connexion lente.
  Stream<List<SessionRecord>> watchHistory(String uid, {int limit = 50}) {
    return _sessionsFor(uid)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SessionRecord.fromMap(d.data())).toList(),
        );
  }
}
