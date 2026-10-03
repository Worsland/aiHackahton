import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase/auth_service.dart';
import 'firebase/session_repository.dart';

/// Meilleur résultat connu pour un scénario donné, calculé à partir de
/// l'historique Firestore — voir [ScenarioScoreBoard].
class ScenarioBestScore {
  const ScenarioBestScore({
    required this.bestPercent,
    required this.attempts,
    required this.lastMode,
    this.lastPlayedAt,
  });

  final int bestPercent;
  final int attempts;

  /// 'live' / 'light' / 'offline' — le mode de la tentative la plus
  /// récente (voir `SessionRecord.mode`).
  final String lastMode;
  final DateTime? lastPlayedAt;

  Map<String, dynamic> toMap() => {
    'bestPercent': bestPercent,
    'attempts': attempts,
    'lastMode': lastMode,
    'lastPlayedAt': lastPlayedAt?.toIso8601String(),
  };

  factory ScenarioBestScore.fromMap(Map<String, dynamic> map) =>
      ScenarioBestScore(
        bestPercent: (map['bestPercent'] as num?)?.toInt() ?? 0,
        attempts: (map['attempts'] as num?)?.toInt() ?? 0,
        lastMode: map['lastMode'] as String? ?? 'offline',
        lastPlayedAt: map['lastPlayedAt'] != null
            ? DateTime.tryParse(map['lastPlayedAt'] as String)
            : null,
      );
}

/// Agrège l'historique de sessions (Firestore, via [SessionRepository]) en
/// un meilleur score par scénario, pour l'afficher sur les cartes de la
/// page principale — y compris hors ligne.
///
/// Architecture de synchronisation choisie : pas de base locale séparée
/// (pas de sqflite/Hive ajouté au projet). Le SDK Firestore garde déjà une
/// copie locale de `watchHistory` et continue à la servir sans réseau (cf.
/// le commentaire de `SessionRepository.save`) ; ce service ne fait
/// qu'agréger ce flux déjà disponible hors ligne, avec le même modèle que
/// `ScenarioCatalog` (`ChangeNotifier`, pour que l'écran se mette à jour
/// tout seul). Le seul ajout est un instantané JSON dans
/// `SharedPreferences` : il sert uniquement à peindre les scores dès la
/// toute première frame, le temps que Firestore livre son premier
/// événement (quasi instantané depuis son cache, mais pas synchrone).
class ScenarioScoreBoard extends ChangeNotifier {
  ScenarioScoreBoard._();
  static final ScenarioScoreBoard instance = ScenarioScoreBoard._();

  static const _prefsKey = 'scenario_scores_v1';

  Map<String, ScenarioBestScore> _scores = {};
  StreamSubscription<List<SessionRecord>>? _sub;
  bool _initialized = false;

  Map<String, ScenarioBestScore> get scores => Map.unmodifiable(_scores);

  ScenarioBestScore? scoreFor(String scenarioTitle) => _scores[scenarioTitle];

  /// À appeler une fois au démarrage de l'app, une fois `ensureSignedIn()`
  /// résolu (voir `main.dart`). Idempotent : un second appel ne recrée pas
  /// l'abonnement Firestore.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _loadCached();

    final uid = AuthService.instance.currentUser?.uid;
    // Pas de compte, même pas anonyme (tout premier lancement sans jamais
    // avoir eu de réseau) : on garde juste le cache local déjà chargé.
    if (uid == null) return;

    _sub = SessionRepository()
        .watchHistory(uid)
        .listen(
          _onHistory,
          onError: (e) => debugPrint('⚠️ Suivi des scores impossible : $e'),
        );
  }

  void _onHistory(List<SessionRecord> history) {
    // `history` arrive du plus récent au plus ancien (voir
    // `watchHistory`) : le premier enregistrement rencontré pour un titre
    // donné est donc sa tentative la plus récente.
    final next = <String, _Accumulator>{};
    for (final record in history) {
      final acc = next.putIfAbsent(record.scenarioTitle, () => _Accumulator());
      acc.attempts += 1;
      if (record.scorePercent > acc.bestPercent) {
        acc.bestPercent = record.scorePercent;
      }
      acc.lastMode ??= record.mode;
      acc.lastPlayedAt ??= record.completedAt;
    }

    _scores = {
      for (final entry in next.entries)
        entry.key: ScenarioBestScore(
          bestPercent: entry.value.bestPercent,
          attempts: entry.value.attempts,
          lastMode: entry.value.lastMode ?? 'offline',
          lastPlayedAt: entry.value.lastPlayedAt,
        ),
    };
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _scores = map.map(
        (key, value) => MapEntry(
          key,
          ScenarioBestScore.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Cache local des scores illisible, ignoré : $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_scores.map((key, value) => MapEntry(key, value.toMap()))),
      );
    } catch (e) {
      // La session en cours garde quand même les scores à jour en mémoire
      // (`_scores` déjà mis à jour) : seule la persistance entre deux
      // lancements de l'app est perdue.
      debugPrint('⚠️ Écriture du cache des scores impossible : $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class _Accumulator {
  int attempts = 0;
  int bestPercent = 0;
  String? lastMode;
  DateTime? lastPlayedAt;
}
