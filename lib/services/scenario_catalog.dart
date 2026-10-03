import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scenario_bundle.dart';
import 'patient_scenario.dart';

/// Source unique des scénarios disponibles dans l'app : le socle embarqué
/// (`PatientScenario.examples`, compilé dans le code, toujours disponible
/// même sans jamais avoir eu de réseau) + les scénarios synchronisés
/// depuis Firestore (collection `scenarios`), mis en cache localement pour
/// rester utilisables hors ligne une fois téléchargés.
///
/// Ajouter un scénario se fait uniquement côté Firestore (console, pour ce
/// MVP — pas d'écran d'admin dans l'app) : il apparaît chez l'agent dès
/// qu'une synchronisation a eu lieu au moins une fois avec du réseau.
///
/// `ChangeNotifier` plutôt qu'un simple service : les écrans qui affichent
/// la liste (le picker de scénarios) doivent se mettre à jour tout seuls
/// quand une synchronisation en arrière-plan ramène du nouveau contenu,
/// sans que l'agent ait besoin de recharger l'app.
class ScenarioCatalog extends ChangeNotifier {
  ScenarioCatalog._();
  static final ScenarioCatalog instance = ScenarioCatalog._();

  static const _prefsKey = 'synced_scenarios_v1';
  static const _collection = 'scenarios';

  List<ScenarioBundle> _synced = [];
  bool _localLoaded = false;
  bool _syncing = false;

  /// Les scénarios synchronisés uniquement (pas le socle) — utile pour un
  /// futur badge "nouveau" ou un écran dédié.
  List<ScenarioBundle> get synced => List.unmodifiable(_synced);

  bool get isSyncing => _syncing;

  /// Liste complète pour le sélecteur de scénarios : socle d'abord (ordre
  /// stable, toujours les mêmes en premier), puis les scénarios
  /// synchronisés dans leur ordre d'arrivée.
  List<PatientScenario> get scenarios => [
    ...PatientScenario.examples,
    ..._synced.map((b) => b.toPatientScenario()),
  ];

  /// Le scénario synchronisé correspondant à ce titre, `null` si c'est un
  /// scénario du socle (déjà géré ailleurs) ou si ce titre est inconnu.
  ScenarioBundle? bundleForTitle(String title) {
    for (final b in _synced) {
      if (b.title == title) return b;
    }
    return null;
  }

  /// Recharge le cache local. Aucun appel réseau : ce qui garantit que les
  /// scénarios déjà synchronisés une fois restent disponibles hors ligne,
  /// y compris au tout premier lancement sans réseau du tout (dans ce cas
  /// `_synced` reste simplement vide, et seul le socle est disponible).
  ///
  /// Idempotent et sûr à appeler plusieurs fois (ex: après déconnexion) ;
  /// utilise un drapeau pour éviter de relire le disque inutilement au
  /// sein d'une même session, sauf appel explicite avec `force: true`.
  Future<void> loadLocal({bool force = false}) async {
    if (_localLoaded && !force) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map(
              (e) =>
                  ScenarioBundle.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        _synced = list;
      }
    } catch (e) {
      debugPrint('⚠️ Cache local des scénarios illisible, ignoré : $e');
    }
    _localLoaded = true;
    notifyListeners();
  }

  /// Interroge Firestore pour les scénarios absents du socle ET du cache
  /// local, les ajoute aux deux. Best-effort : une erreur réseau ou un
  /// document mal formé ne doit jamais faire planter l'app ni perdre ce
  /// qui était déjà synchronisé — voir les `try/catch` imbriqués.
  ///
  /// Retourne le nombre de scénarios réellement ajoutés (0 si aucun de
  /// nouveau, ou si la synchronisation a échoué) : permet à l'appelant
  /// d'afficher "2 nouveaux scénarios disponibles" ou de rester silencieux.
  Future<int> syncFromCloud() async {
    if (_syncing) return 0;
    _syncing = true;
    notifyListeners();
    try {
      await loadLocal(); // s'assure d'avoir le cache le plus à jour avant de comparer

      final known = {
        ...PatientScenario.examples.map((s) => s.title),
        ..._synced.map((b) => b.title),
      };

      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .get();

      final added = <ScenarioBundle>[];
      for (final doc in snapshot.docs) {
        try {
          final bundle = ScenarioBundle.fromMap(doc.data());
          if (known.add(bundle.title)) {
            added.add(bundle);
          }
        } catch (e) {
          // Un document mal formé (champ manquant, mauvais type...) est
          // ignoré individuellement plutôt que de faire échouer toute la
          // synchronisation : un scénario cassé ne doit pas priver l'agent
          // des autres, valides.
          debugPrint('⚠️ Scénario Firestore ignoré (${doc.id}) : $e');
        }
      }

      if (added.isEmpty) return 0;

      _synced = [..._synced, ...added];
      await _persist();
      notifyListeners();
      return added.length;
    } catch (e) {
      debugPrint('⚠️ Synchronisation des scénarios impossible : $e');
      return 0;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_synced.map((b) => b.toMap()).toList()),
      );
    } catch (e) {
      // La session en cours garde quand même les nouveaux scénarios en
      // mémoire (`_synced` déjà mis à jour par l'appelant) : seule la
      // persistance entre deux lancements de l'app est perdue.
      debugPrint('⚠️ Écriture du cache des scénarios impossible : $e');
    }
  }
}
