# TODO — Ilera

Backlog actualisé : distinguer ce qui est implémenté dans le dépôt de ce qui
doit encore être vérifié sur appareil ou validé par des personnes compétentes.
Les scores de tests d'un petit jeu ne sont pas des mesures de qualité clinique
ou de performance en conditions réelles.

## État implémenté

- [x] Parcours d'entretien, sélection d'un diagnostic, score et récapitulatif.
- [x] Conversations Live avec Gemini et réponses hors ligne déterministes
  basées sur les scénarios embarqués.
- [x] En mode hors ligne anglais, Gecko peut sélectionner une réponse
  préécrite à partir d'une question. Les mots-clés restent prioritaires et
  servent de secours ; Gecko ne génère pas de texte.
- [x] En mode hors ligne yorùbá, trois scénarios utilisent le matching par
  mots-clés, avec normalisation et abstention en cas d'ambiguïté. Gecko n'est
  pas utilisé pour le yorùbá.
- [x] Whisper `tiny` intégré pour la reconnaissance vocale hors ligne sur
  mobile en anglais et en yorùbá ; téléchargement initial avec progression,
  réutilisation du modèle installé et enregistrement temporaire supprimé
  après transcription.
- [x] Les réponses yorùbá ont des chemins audio distincts et 26 fichiers MP3
  sont présents dans `assets/audio/offline/yo/`. Un enregistrement absent ne
  déclenche pas une voix anglaise.
- [x] Authentification Firebase, profils, sauvegarde des scores, catalogue et
  progression sont intégrés.
- [x] README principal et inventaire des enregistrements yorùbá mis à jour en
  anglais.
- [x] Les builds/tests Flutter ciblés et le build Android debug ont réussi
  lors des validations précédentes. Refaire les contrôles après modification
  du code, pas pour une simple modification documentaire.

## P0 — À valider avant une démonstration fiable

### Appareils, offline et voix

- [ ] Sur des téléphones Android et iOS cibles, télécharger une seule fois
  Gecko et Whisper, redémarrer à froid, puis vérifier leur réutilisation sans
  réseau.
- [ ] Vérifier que l'app démarre et que le matching anglais fonctionne après
  redémarrage et en mode avion, sans hot restart ni intervention manuelle.
- [ ] Tester Whisper en anglais et en yorùbá sur chaque appareil cible :
  permission micro, début/fin de capture, silence, erreur, durée, transcription
  et disponibilité réellement hors ligne.
- [ ] Tester l'expérience sur un appareil Android modeste et une installation
  propre sur un appareil supplémentaire ; vérifier stockage, mémoire, latence
  et stabilité des deux modèles locaux.
- [ ] Vérifier les 26 fichiers yorùbá par écoute : fichier lisible, bonne voix,
  texte prononcé conforme au script, identifiant et scénario corrects.
- [ ] Confirmer avec les personnes ayant fourni les enregistrements leur
  provenance et le droit de les distribuer ; marquer les audios non relus ou
  non validés.
- [ ] Parcourir chacun des trois scénarios hors ligne, en texte puis à la voix,
  jusqu'au diagnostic et au récapitulatif ; vérifier les répétitions, le score,
  les erreurs et le retour à la liste.
- [ ] Tester les erreurs de téléchargement et d'initialisation Gecko/Whisper :
  message compréhensible, annulation/réessai possibles, matching lexical
  utilisable si Gecko échoue, et aucun indicateur de chargement bloqué.
- [ ] Vérifier sur Android la version NDK demandée par `whisper_ggml` et
  confirmer la configuration iOS avec Xcode/macOS.

### Qualité de matching et localisation

- [ ] Faire relire les scénarios, formulations, traductions et scripts audio
  par des locuteurs yorùbá ; enrichir le jeu de tests avec leurs formulations.
- [ ] Tester toute l'interface en yorùbá (sélection de scénario, entretien,
  diagnostic, récapitulatif, progression, profil, compte, erreurs et dialogues)
  et relever les textes qui retombent encore en anglais.
- [ ] Réexécuter l'évaluation réelle de Gecko sur appareil. Une mesure antérieure
  rapportait 44/51 cas sur un Samsung SM-A055F, avec des erreurs de paraphrase
  et de répétition : reproduire ce résultat, corriger les cas et consigner les
  nouvelles mesures plutôt que supposer qu'ils sont résolus.
- [ ] Évaluer séparément le matcher lexical yorùbá, le matcher anglais et
  Gecko avec cas positifs, paraphrases, répétitions, texte aléatoire et
  questions hors scénario. Consigner les cas, seuils, faux rapprochements,
  abstentions et latences dans `docs/EVALUATION.md`.
- [ ] Mesurer séparément la qualité de Whisper et celle du matcher afin de
  distinguer une erreur de transcription d'une erreur de sélection de réponse.

### Validation clinique et sécurité

- [ ] Faire valider par un professionnel de santé les diagnostics, signes
  d'alerte, conseils et distracteurs ; consigner les sources et la date de
  révision.
- [ ] Faire valider par des personnes yorùbá les textes cliniques localisés ;
  garder visible leur statut de brouillon jusqu'à cette validation.
- [ ] Vérifier les règles Firestore : catalogue lisible selon la politique
  prévue et profils/sessions accessibles uniquement à leur propriétaire.
- [ ] Ne pas distribuer de clé Gemini secrète dans le client. Pour une démo,
  vérifier restrictions et quotas ; prévoir un backend avant une diffusion
  publique.
- [ ] Confirmer et documenter les données envoyées à Gemini et Firebase. Ne pas
  transmettre l'audio Whisper hors de l'appareil ni stocker de transcript sans
  besoin explicite et information adaptée.

## P1 — Après la validation de base

- [ ] Compléter `docs/EVALUATION.md` avec le protocole et les résultats
  reproductibles sur les appareils cibles, sans présenter le petit jeu actuel
  comme représentatif.
- [ ] Vérifier avec des agents/formateurs le besoin local prioritaire, les
  scénarios et le débrief pédagogique.
- [ ] Ajouter une action « Refaire le cas » et une progression entre tentatives
  si les essais utilisateurs confirment leur utilité.
- [ ] Versionner et valider les bundles Firestore avant publication ; tester
  les mises à jour des scénarios déjà en cache.
- [ ] Vérifier les garanties de synchronisation des sessions hors ligne sur
  les plateformes prises en charge, notamment web.
- [ ] Préparer le parcours de démonstration, l'APK, une installation propre et
  une courte vidéo de secours.

## P2 — Évolutions à décider après les essais

- [ ] Concevoir un pilote utilisateur avec critères définis à l'avance ; ne pas
  revendiquer un impact clinique avant de l'avoir mesuré.
- [ ] Envisager un tableau de bord formateur avec minimisation des données.
- [ ] Étudier une solution d'administration pour le contenu si la gestion
  directe via Firebase ne suffit plus.
- [ ] Ajouter d'autres langues, scénarios ou services IA seulement après
  validation linguistique, clinique, technique et consentement adapté.

## Critère de feu vert pour une démo

- [ ] Démarrage à froid reproductible ; les téléchargements terminés ne
  recommencent pas sans raison.
- [ ] Le parcours hors ligne fonctionne en mode avion après préparation des
  modèles ; le fallback lexical est utilisable si Gecko est indisponible.
- [ ] Les entrées hors sujet n'attribuent pas de point clinique par erreur.
- [ ] Les trois scénarios aboutissent au diagnostic et au récapitulatif avec
  un score cohérent.
- [ ] La reconnaissance vocale et les fichiers yorùbá ont été vérifiés sur
  les appareils/langues annoncés.
- [ ] Les utilisateurs comprennent qu'Ilera est un outil de formation et ne
  remplace ni un professionnel de santé ni les protocoles locaux.
