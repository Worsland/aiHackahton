# Refonte design — ce qui a changé

## Services (fournis par l'équipe, non modifiés)
- `lib/services/gemini_service.dart` — via `google_generative_ai`.
- `lib/services/patient_scenario.dart` — titre/description/systemPrompt
  uniquement (pas d'icône ni de difficulté : c'est purement de l'UI, voir
  `_ScenarioVisuals` dans `simulation_screen.dart`, qui mappe le titre à une
  icône et un niveau, avec un fallback neutre si un nouveau scénario est
  ajouté sans être listé — rien ne casse).
- `lib/services/voice_service.dart` — `flutter_tts` + `speech_to_text` +
  `permission_handler`.

## Fichiers de design
- `lib/theme/app_theme.dart` — palette (teal `#0F766E` + ambre `#F59E0B`),
  typographie, boutons/cartes/chips arrondis.
- `lib/widgets/patient_avatar.dart` — **mascotte placeholder** : avatar rond
  animé (respire, change de couleur selon l'état idle/écoute/réflexion/parle).
  Pensé pour être remplacé plus tard par une illustration ou un Lottie sans
  toucher au reste de l'écran.
- `lib/screens/simulation_screen.dart` — écran de choix de scénario (header
  dégradé + cartes avec badge de difficulté) et écran de simulation (avatar
  en haut, bulles de chat asymétriques, bouton micro circulaire animé,
  feedback en carte dédiée).
- `lib/main.dart` — applique le thème, écran "clé manquante" restylé.

## À ajouter dans `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_generative_ai: ^0.4.6
  speech_to_text: ^7.0.0
  flutter_tts: ^4.0.0
  permission_handler: ^11.3.0
```
Et pour Android/iOS, penser aux permissions micro (`RECORD_AUDIO` sur
Android, `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`
sur iOS).

## Prochaines pistes visuelles
- Remplacer l'avatar `PatientAvatar` par une illustration SVG ou une
  animation Lottie par scénario (enfant, femme, homme âgé) tout en gardant
  la même logique d'état (idle/listening/thinking/speaking).
- Ajouter une micro-animation sur les bulles de chat à l'arrivée.
- Écran de fin de session avec récap visuel (score de questions clés posées).