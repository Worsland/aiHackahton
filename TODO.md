# TODO — Ilera

Plan de travail priorisé pour préparer la démo Hack-Nation, puis faire évoluer le projet. L'objectif n'est pas d'ajouter un maximum de fonctionnalités : c'est de prouver qu'Ilera fonctionne de façon fiable, utile et adaptée à son public.

## État déjà acquis

- [x] Parcours d'entretien, choix du diagnostic et récapitulatif pédagogique.
- [x] Mode local avec Gecko : sélection parmi les réponses pré-écrites, avec secours par mots-clés.
- [x] Rejet ciblé des entrées manifestement aléatoires, avec test de régression.
- [x] Bouton Feedback retiré de l'entretien ; le diagnostic reste l'action de fin.
- [x] Icônes Ilera générées pour Android, iOS et le web.
- [x] Build web vérifié ; 9 tests ciblés du matcher passent.
- [x] Build Android debug vérifié après les changements récents. Build iOS à vérifier sur macOS/Xcode.

## Priorité actuelle — forme et expérience multilingue

Cette tranche remplace l'ordre de priorité précédent : traiter d'abord la
cohérence visuelle et linguistique de l'expérience, puis mesurer la qualité du
parcours. Le contenu clinique et les sources de soumission restent à valider,
mais ne bloquent pas le travail d'interface.

- [ ] A. Localiser en Yorùbá toutes les pages accessibles lorsque la langue Yorùbá est sélectionnée.
  - Faire porter le choix de langue au niveau de l'application et le conserver lors de la navigation et du redémarrage.
  - Recenser et traduire les textes visibles, titres, boutons, états vides, erreurs, validations, dialogues et notifications dans les écrans scénarios, simulation, diagnostic, récapitulatif, progression, profil et compte.
  - Vérifier qu'aucun écran de ce parcours ne revient silencieusement en anglais ; préserver English comme langue par défaut.
  - Ajouter des tests de localisation pour les principales pages et interactions.
  - [x] Persister le choix de langue et le transmettre aux pages Profil, Progression, Compte, Diagnostic et Récapitulatif.

- [ ] B. Fournir tous les scénarios en Yorùbá.
  - Ajouter pour chaque scénario existant son titre neutre, sa description, les points clés, les réponses du patient, les choix de diagnostic, les conseils et le récapitulatif.
  - Afficher la langue choisie dans la liste et faire correspondre chaque scénario à ses données localisées.
  - Garder les contenus Yorùbá clairement marqués comme brouillon tant qu'ils ne sont pas relus ; ne pas inventer de traduction clinique validée.
  - Vérifier que chaque scénario est jouable du début au récapitulatif dans les deux langues.
  - [x] Ajouter les trois scénarios intégrés en version Yorùbá hors ligne et les exposer dans la liste.
  - [ ] Faire relire les textes et valider le parcours complet par une personne Yorùbá.

- [ ] C. Ajouter une commande micro en mode hors ligne, en disposition adaptative mobile et grand écran.
  - Cibles prioritaires : Android et iOS.
  - Sélectionner la locale STT en fonction de la langue active ; transcrire en texte puis réutiliser le même flux de matching que la saisie clavier.
  - Vérifier séparément sur les appareils cibles si le moteur et les données de langue permettent une reconnaissance réellement hors ligne en `en_US` et en Yorùbá. La simple disponibilité d'une locale ou de `onDevice` ne suffit pas comme preuve.
  - Si la langue n'est pas disponible hors ligne, expliquer l'indisponibilité et garder la saisie texte pleinement utilisable ; ne pas envoyer l'audio à un service distant sans consentement explicite.
  - Couvrir permissions micro, démarrage/arrêt, erreur, état d'écoute et adaptation petit/grand écran par tests.
  - [x] Relier le micro à la chaîne de matching existante en mobile, transmettre `en_US`/`yo_NG`, sélectionner uniquement une locale exposée par le moteur et ne jamais substituer l'anglais au Yorùbá.
  - [ ] Tester la disponibilité et la transcription réellement hors ligne sur les appareils Android et iOS ciblés.

- [ ] D. Ajouter les réponses audio Yorùbá préenregistrées.
  - Source demandée : enregistrements de locuteurs Yorùbá, pas de TTS présenté comme voix validée.
  - Produire les enregistrements pour les réponses fixes de tous les scénarios localisés, établir une correspondance stable entre identifiants de réponse et fichiers, puis les intégrer comme assets.
  - Gérer lecture, interruption et absence de fichier sans bloquer l'entretien ; garder un fallback clairement identifié.
  - Confirmer que les textes parlés ont été relus par une personne Yorùbá avant l'enregistrement.
  - [x] Préparer les chemins d'assets séparés et empêcher le fallback vers les enregistrements/voix anglais.
  - [ ] Enregistrer et fournir les fichiers audio Yorùbá : aucun enregistrement natif n'est disponible dans le workspace.

- [ ] E. Mesurer le parcours complet anglais et Yorùbá, texte et voix.
  - Constituer des formulations écrites et des enregistrements de test, séparés par langue et scénario, avec résultats attendus relus par des locuteurs.
  - Mesurer le STT (transcription, erreurs, latence et disponibilité réellement hors ligne) séparément du matcher (bon point clé, abstention, faux rapprochement, répétition).
  - Comparer la saisie texte et la chaîne audio→STT→matcher ; ne pas attribuer au matcher une erreur de transcription, ni annoncer un score représentatif à partir d'un petit jeu écrit par l'équipe.
  - Documenter appareils, versions, moteurs, packs de langue, protocole, réussites et échecs dans `docs/EVALUATION.md`.

## Nouveau plan de code après le ProjectGOAL rebasé (week-end hackathon)

### P0 — modifications code indispensables pour être conforme au brief

- [ ] 1. Ajouter le sélecteur de langue et brancher la langue dans l'UI + le moteur.
  - Fichiers : `lib/screens/simulation_screen.dart`, `lib/main.dart`, nouveau `lib/services/lang/app_language.dart`.
  - Implémenter un enum `AppLanguage { en, yo }` ; stocker la sélection locale dans le state global ou le service de configuration.
  - Faire passer la langue à l'interface, aux prompts système, au texte du patient, aux messages de fallback et aux libellés de l'app.
  - Gérer le cas sans connexion et le cas connecté avec un comportement explicite en fonction de la langue choisie.
  - [x] Première tranche : sélecteur sur l'écran des scénarios ; Yorùbá sélectionne le parcours hors ligne et n'utilise pas Gecko ni Gemini Live.

- [ ] 2. Introduire un modèle de contenu par langue pour les scénarios.
  - Fichiers : `lib/services/patient_scenario.dart`, `lib/services/offline/offline_scenarios.dart`, éventuellement `lib/services/lang/yoruba_scenario_data.dart` ou des JSON dédiés.
  - Ajouter un champ `language` / `locale` sur les scénarios.
  - Séparer le `title`, la description, le `systemPrompt`, les points clés, les réponses du patient, et les messages UI selon les langues disponibles.
  - Ne pas exposer le diagnostic dans le titre affiché ; garder le texte neutre et localisé.
  - [x] Premier scénario localisé en Yorùbá : fièvre chez l'enfant, avec QCM, signes d'alerte, score et récapitulatif localisés. Brouillon à relire par l'équipe.

- [ ] 3. Mettre en place le matcher lexical yoruba hors ligne avec normalisation des diacritiques.
  - Fichiers : nouveau `lib/services/lang/yoruba_normalizer.dart`, `lib/services/offline/offline_patient_brain.dart`, `lib/services/offline/offline_text_match.dart`.
  - Normaliser en minuscule, Unicode NFD, retirer les marques combinantes et la ponctuation.
  - Appliquer la normalisation aux deux côtés : entrée utilisateur et lexique de mots-clés.
  - Ajouter des variantes de mots-clés et des paraphrases écrites à la main pour le yoruba.
  - Garder Gecko/embedding seulement pour l'anglais ; ne pas l'affirmer comme solution yoruba.
  - [x] Première fondation : normaliseur des lettres yoruba précomposées et combinantes, branché au matcher lexical ; tests avec et sans diacritiques dans `test/yoruba_normalizer_test.dart`.
  - [x] Ajouter un premier lexique yoruba (avec mots souvent employés en anglais) et un fallback en cas d'égalité ambiguë ; tests dans `test/offline_yoruba_test.dart`.

- [ ] 4. Implémenter le fail-safe visible et non ambigu.
  - Fichiers : `lib/services/offline/offline_patient_brain.dart`, `lib/screens/simulation_screen.dart`.
  - Sous le seuil de confiance, ne pas “deviner” un point clé.
  - Afficher un message explicite du type : « Pas sûr — reformulez ou demandez à un formateur. »
  - Ajouter la version yoruba relue par un natif, avec label de statut : "non vérifié" si le texte n'a pas été validé.
  - S'assurer que le score ne crédite pas un point non réellement couvert.
  - [x] Premier fallback yoruba visible dans la conversation et par notification ; les correspondances lexicales à égalité ne valident aucun point.

- [ ] 5. Marquer le contenu yoruba comme brouillon/à valider avant diffusion.
  - Fichiers : `lib/services/offline/offline_scenarios.dart`, `docs/DATA_SOURCES.md`, `README.md`.
  - Ajouter un statut ou une note visible dans l'UI : « contenu yoruba en relecture / non vérifié ».
  - Ne pas présenter les textes comme validés cliniquement tant qu'une relecture native n'a pas eu lieu.
  - Documenter les limites de couverture linguistique et clinique.
  - [x] Avertissement brouillon affiché au choix du scénario et au récapitulatif ; README mis à jour. La relecture linguistique reste à faire.

- [ ] 6. Compléter le mini-benchmark comparatif mots-clés / sémantique et anglais / yoruba.
  - Fichiers : nouveau `docs/EVALUATION.md`, `test/` (ou `test/data` selon l'organisation actuelle).
  - Créer des jeux de cas positifs, paraphrases, questions courtes, répétitions, cas négatifs et hors-sujet.
  - Tester le même scénario en anglais et en yoruba.
  - Conserver un petit tableau de résultats reproductibles ; le brancher dans l'évaluation de la démo.
  - [x] Première mesure limitée : 18 cas yoruba écrits par l'équipe ; matcher lexical 12/12 positifs, 5/5 abstentions négatives et 1/1 répétition. Voir `docs/EVALUATION.md`.
  - [ ] Faire relire/enrichir les cas par des locuteurs yoruba puis mesurer la comparaison anglaise et Gecko séparément.

- [ ] 7. Compléter le fichier de sources et de limites des données.
  - Fichier : nouveau `docs/DATA_SOURCES.md`.
  - Décrire : origine, source, licence, taille, usage, limites, et ce qu'il ne couvre pas.
  - Ajouter les références du brief et les données candidates pour le problème et le contexte de santé.
  - Indiquer clairement la limite d'usage : ce n'est pas une preuve clinique validée.
  - [x] Documenter les ressources effectivement utilisées et signaler les références locales/cliniques qui restent à choisir.

- [ ] 8. Rendre le nom affiché cohérent avec le brief et la démo.
  - Fichiers : `README.md`, `lib/main.dart`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `pubspec.yaml`.
  - Renommer l'UI en `Ilera`, sans changer `applicationId`, `bundle id`, `package name` ni le projet Firebase.
  - Garder la preuve de la différence entre le nom affiché et le package technique.

### P1 — modifications fortes recommandées avant la présentation / jury

- [ ] 9. Ajouter l'intégration Claude en mode en ligne pour la compréhension des questions yoruba.
  - Fichiers : nouveau `lib/services/claude/claude_patient_service.dart`, proxy backend (Cloud Run / Worker / serverless), éventuelles variables d'environnement.
  - Envoyer uniquement la question, le `scenarioId` et les points clés ; jamais d'identifiant utilisateur.
  - Réponse JSON strict avec `key_point_ids`, `confidence`, `needs_human`.
  - Fallback automatique vers le matcher local si Claude est indisponible ou timeout.
  - Vérifier le modèle et la tarification avant intégration.

- [ ] 10. Vérifier le mode Gemini Live en yoruba et le rendre optionnel / bonus.
  - Fichiers : `lib/services/live/gemini_live_service.dart`, `lib/screens/simulation_screen.dart`.
  - Vérifier la langue `yo`, le système prompt, la transcription, la qualité de réponse et les limites documentées.
  - Ne pas faire du live le parcours principal de la démo.
  - Gérer le cas où la voix ou la compréhension est médiocre ou absente.

- [ ] 11. Sortir la clé Gemini du client.
  - Fichiers : `lib/main.dart`, backend / configuration serveur, éventuellement `lib/services/gemini_service.dart`.
  - Supprimer tout stockage de clé dans le build client.
  - Utiliser une clé côté serveur avec quota, limitation, logs minimisés et mode de secours si la clé est absente.

- [ ] 12. Ajouter un consentement explicite avant tout envoi d'audio / texte à un service distant.
  - Fichiers : `lib/screens/simulation_screen.dart`, nouvel écran de consentement / composant de dialog.
  - Déclarer ce qui est envoyé en ligne, dans quels cas, et avec quel usage.
  - Exiger une confirmation claire avant le mode connecté.

- [ ] 13. Ajouter au moins un scénario yoruba avec audio préenregistré.
  - Fichiers : `assets/audio/offline/yo/`, `lib/services/offline/offline_voice_player.dart`, `lib/services/offline/offline_scenarios.dart`.
  - Préparer un seul scénario pour la démo avec voix native / audio validé.
  - Si le TTS Android yoruba n'est pas bon, ne pas le promettre ; documenter le fallback audio.

- [ ] 14. Mettre à jour le README pour refléter le nouveau brief.
  - Fichiers : `README.md`.
  - Inclure : langue cible, parcours principal hors ligne, limites, usage, sources, modes disponibles et avertissement médical.
  - Faire apparaître clairement que ce n'est pas un diagnostiquer médical et qu'un formateur doit relire le contenu.

### P2 — si le temps le permet

- [ ] 15. Ajouter un second scénario yoruba complet.
- [ ] 16. Vérifier le TTS embarqué yoruba uniquement si une personne native a validé la qualité ; sinon rester sur le préenregistré.
- [ ] 17. Préparer la reconnaissance vocale yoruba hors ligne comme une limite de la version actuelle, sans la promettre.
- [ ] 18. Ajouter un vrai flux de test de comparaison Gemini Live vs Claude sur les mêmes questions yoruba.
- [ ] 19. Évaluer la faisabilité du STT hors ligne sur téléphone, en anglais et en yoruba — absorbé dans la priorité C ci-dessus.

### Ordre de mise en œuvre recommandé

1. Sélecteur de langue + contenu localisé.
2. Matcher yoruba + fail-safe + score robuste.
3. Benchmarks + validation + docs sources.
4. UI/nom affiché + README.
5. Claude proxy + consentement + Gemini Live bonus.
6. Audio yoruba + préparation vidéo / démo.

## P0 — Indispensable avant la démo

### Fiabilité du modèle offline

- [x] Télécharger le modèle une seule fois, fermer complètement l'app, puis la relancer au moins 5 fois.
- [x] Vérifier qu'après installation, le modèle est retrouvé sans nouveau téléchargement.
- [ ] Répéter un scénario après redémarrage et en mode avion.
- [ ] Vérifier qu'aucun échec du worker d'embeddings ne nécessite un hot restart. Les logs précédents ont montré un worker d'abord en échec, puis chargé après redémarrage.
- [ ] Afficher sans ambiguïté l'état réel : « IA locale prête », « préparation », ou « mode simplifié par mots-clés ».
- [ ] En cas d'échec du modèle, garder l'envoi utilisable, expliquer le mode de secours et ne jamais laisser un indicateur tourner indéfiniment.

**Critère de validation :** 5 démarrages à froid réussis de suite, dont un essai en mode avion après le téléchargement initial.

### Qualité des réponses locales

- [x] Comparer la question au sujet et au texte des réponses candidates avec les embeddings Gecko ; aucun texte n'est généré.
- [x] Donner priorité aux mots-clés explicites, refuser une correspondance sémantique ambiguë et répondre par le fallback si le modèle hésite.
- [x] Traiter une nouvelle formulation d'un point déjà abordé comme une répétition, sans compter le point une seconde fois.
- [x] Constituer un jeu de questions positives, paraphrases, questions courtes, répétitions et cas négatifs pour les 3 scénarios (`test/data/offline_question_cases.json`).
- [x] Première exécution sur le modèle réel du SM A055F : 44/51 cas réussis (fièvre 14/18, post-partum 17/18, déshydratation 13/15). Lanceur : `.\tools\run_offline_model_eval.ps1`.
- [ ] Corriger les 7 échecs observés : paraphrases durée/symptômes/hydratation/saignement, question sur l'activité avant malaise et deux détections de répétition.
- [ ] Ajouter des cas négatifs : texte aléatoire, texte vide, salutations et questions médicales hors scénario.
- [ ] Mesurer sur le vrai modèle du téléphone les faux positifs, les points manqués et le temps de réponse ; calibrer le seuil et la marge d'ambiguïté avec ces résultats.
- [ ] Vérifier que le fallback par mots-clés ne valide pas les cas négatifs et que le score ne crédite pas un point non réellement abordé.
- [ ] Tester au minimum l'anglais prévu pour la démo, y compris les erreurs de frappe et variantes de formulation réalistes.

**Critère de validation :** conserver un petit tableau de résultats reproductibles par scénario ; aucune question hors sujet ne doit déclencher ou noter une réponse clinique.

### Parcours complet et réseau

- [ ] Parcourir chaque scénario du début au récapitulatif dans le mode offline.
- [ ] Vérifier que l'envoi accepte plusieurs messages successifs et que le bouton redevient disponible après réponse, erreur, annulation ou timeout.
- [ ] Vérifier que le bouton Diagnostic reste désactivé avant la première question et que le Feedback ne révèle aucun indice pendant l'entretien.
- [ ] Vérifier score, diagnostic choisi, points couverts/manqués et retour vers la liste des scénarios.
- [ ] Si le mode Live est présenté : tester autorisation micro, connexion perdue, reconnexion, refus/absence de clé et erreurs de service.
- [ ] Tester une installation propre sur un second téléphone Android, pas seulement sur l'appareil de développement.

### Sécurité et contenu médical

- [ ] Faire relire les scénarios, signes d'alerte, diagnostics et conduites à tenir par un professionnel de santé compétent ; consigner les sources et la date de révision.
- [ ] Garder visible la mention « outil de formation, ne remplace pas un professionnel ni les protocoles locaux ».
- [ ] Vérifier les règles Firestore : lecture publique limitée au catalogue, données de profil et sessions accessibles uniquement à leur propriétaire.
- [ ] Ne pas distribuer une clé Gemini secrète embarquée dans l'application ; pour la démo, restreindre la clé et ses quotas, puis prévoir un backend avant une diffusion publique.
- [ ] Clarifier quelles données sont envoyées à Gemini et à Firebase ; ne pas enregistrer de transcript sensible sans nécessité et consentement.

## P1 — Renforcer la proposition face au jury

### Débrief réellement pédagogique

- [ ] Pour chaque point manqué, expliquer le risque clinique associé et pourquoi il importe, sans afficher de question-indice avant la fin de l'entretien.
- [ ] Ajouter une action « Refaire le cas » après le récapitulatif, avec remise à zéro complète du scénario.
- [ ] Présenter une progression simple : couverture des points clés, signes d'alerte identifiés et évolution entre les tentatives.
- [ ] Garder séparés le score pédagogique et toute recommandation médicale réelle.

### Pertinence locale et langues

- [ ] Choisir avec des agents ou formateurs une population cible et un besoin prioritaire précis pour la démo.
- [ ] Faire valider le vocabulaire et les détails de scénario par des personnes du contexte ciblé.
- [ ] Ajouter une seule langue cible à la fois : interface, prompt, réponses, exemples de paraphrases, diagnostic et audio doivent être cohérents dans cette langue.
- [ ] Vérifier que le modèle d'embeddings et la reconnaissance vocale prennent réellement en charge la langue choisie ; ne pas promettre une langue uniquement parce que les textes sont traduits.

### Ajout et mise à jour de scénarios à distance

- [ ] Ajouter une version de contenu aux bundles Firestore et mettre à jour le cache lorsqu'un document existant change.
- [ ] Valider les bundles avant publication : champs requis, liste de réponses non vide, identifiants uniques, exemples et règles de score.
- [ ] Prévoir des scénarios localisés par langue et des médias/audio avec fallback explicite.
- [ ] Documenter un modèle de scénario et un processus de revue clinique avant publication.
- [ ] À plus long terme, remplacer l'édition directe dans la console Firebase par un outil d'administration avec prévisualisation et validation.

### Démonstration en ligne

- [ ] Précharger le modèle sur le téléphone de démo ; ne pas dépendre du téléchargement pendant la présentation.
- [ ] Préparer une vidéo courte de secours et un parcours de démo de 2 minutes.
- [ ] Montrer une question pertinente reformulée, une question hors sujet, puis le diagnostic et le récapitulatif.
- [ ] Montrer le mode avion après téléchargement pour rendre la valeur offline visible.
- [ ] Préparer un APK de démonstration, les étapes d'installation et un README propre ; confirmer les versions Android réellement prises en charge.

## P2 — Après le hackathon

- [ ] Tester l'expérience avec de vrais agents de santé et formateurs ; mesurer compréhension, facilité d'usage et amélioration avant/après.
- [ ] Concevoir une étude pilote avec des critères définis à l'avance, sans revendiquer un impact clinique non mesuré.
- [ ] Construire un tableau de bord formateur avec progression de groupe et lacunes récurrentes, en limitant les données personnelles.
- [ ] Ajouter une file locale fiable pour les sessions hors ligne et une synchronisation idempotente au retour du réseau.
- [ ] Envisager un mode de contenu signé/versionné pour les mises à jour et la traçabilité des révisions cliniques.
- [ ] Optimiser taille du modèle, consommation mémoire, stockage et temps de préparation sur les appareils d'entrée de gamme.
- [ ] Ajouter les plateformes et langues uniquement après tests sur des appareils et avec des locuteurs de ces langues.

## Feu vert démo

- [ ] L'app démarre à froid et ouvre le scénario sans manipulation spéciale.
- [ ] Le statut montre correctement si Gecko est prêt ou si le fallback est utilisé.
- [ ] Une question reformulée déclenche la bonne réplique ; une entrée aléatoire ne révèle aucun point clinique.
- [ ] Plusieurs messages peuvent être envoyés sans spinner bloqué.
- [ ] Le diagnostic et le récapitulatif correspondent aux réponses réellement recueillies.
- [ ] La démonstration fonctionne sans réseau après le téléchargement du modèle, avec une vidéo de secours prête.
- [ ] Le jury entend clairement la limite : Ilera entraîne à l'entretien clinique et ne diagnostique pas de vrais patients.
