import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/firebase/auth_service.dart';
import 'services/gemini_service.dart';
import 'services/lang/app_language_controller.dart';
import 'services/scenario_catalog.dart';
import 'services/scenario_score_board.dart';
import 'screens/simulation_screen.dart';
import 'theme/app_theme.dart';

const geminiBackendUrl = String.fromEnvironment('ILERA_AI_BACKEND_URL');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguageController.instance.load();

  // Charge le cache local des scénarios déjà synchronisés (aucun réseau
  // requis) : garantit que ce qui a été téléchargé une fois reste
  // disponible hors ligne dès le lancement suivant.
  await ScenarioCatalog.instance.loadLocal();

  // Ne doit jamais empêcher l'app de démarrer : sans Firebase, l'app reste
  // utilisable (modes hors-ligne et léger en particulier), seule la
  // sauvegarde de la progression est indisponible. On ne bloque donc pas
  // le lancement sur cet appel, juste sur son issue (succès ou échec).
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // La persistance hors-ligne de Firestore est automatique sur
    // Android/iOS, mais doit être activée explicitement sur le web.
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    }
    // Un bref instant de réseau est nécessaire pour créer le compte
    // anonyme la toute première fois ; les lancements suivants réutilisent
    // la session locale, y compris hors ligne. Si ce tout premier
    // lancement se fait sans réseau, `ensureSignedIn()` renvoie `null`
    // sans lever d'exception (voir AuthService) : on retentera plus tard,
    // par exemple au moment de sauvegarder une première session.
    await AuthService.instance.ensureSignedIn();
    firebaseReady = true;
  } catch (e) {
    debugPrint('⚠️ Firebase indisponible au démarrage : $e');
  }

  // Ne bloque jamais le premier affichage : la synchronisation tourne en
  // arrière-plan et met à jour l'écran de sélection toute seule
  // (`ScenarioCatalog` est un `ChangeNotifier`) dès qu'elle se termine.
  if (firebaseReady) {
    unawaited(ScenarioCatalog.instance.syncFromCloud());
    // Idem pour les scores : l'agrégation démarre en tâche de fond dès
    // qu'un compte (même anonyme) est disponible, et met à jour la page
    // d'accueil toute seule (ScenarioScoreBoard est aussi un
    // ChangeNotifier) sans bloquer le premier affichage.
    unawaited(ScenarioScoreBoard.instance.init());
  }

  runApp(HackathonApp(firebaseReady: firebaseReady));
}

class HackathonApp extends StatelessWidget {
  const HackathonApp({super.key, required this.firebaseReady});

  /// Informatif seulement pour l'instant (pas encore utilisé pour changer
  /// l'UI) : permettra plus tard d'afficher un indicateur "progression non
  /// sauvegardée" si Firebase n'a jamais pu s'initialiser.
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ilera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: SimulationScreen(geminiService: GeminiService(geminiBackendUrl)),
    );
  }
}
