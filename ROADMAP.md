# Évolution du projet — vers un vrai outil d'entraînement clinique

Ce document complète le `README.md` d'origine (setup technique du hackathon).
Il décrit où le projet en est après la phase de conception, ce qui a été
tranché, et ce qu'il reste à construire. Toutes les décisions ci-dessous
ont été prises en discussion, avec le contenu médical **à faire valider par
une personne compétente avant tout usage réel**, y compris en entraînement.

## 1. Pourquoi ce document existe

Le prototype de hackathon (voir `ProjectGOAL.md`) simulait une conversation
avec un patient virtuel, mais ne vérifiait jamais si l'agent tirait la
bonne conclusion de cette conversation. Une discussion agréable qui rate
tous les signaux d'alerte passait pour un succès. Ce n'est plus le cas :
l'objectif est maintenant de fermer la boucle complète **recueillir
l'information → la synthétiser → décider**, comme un vrai entretien
clinique.

## 2. Ce que l'agent fait maintenant, du début à la fin

1. Il choisit un scénario, présenté par une situation neutre (le diagnostic
   n'est jamais donné dans le titre ni la description affichés).
2. Il mène l'interrogatoire, en Live (voix naturelle), en mode léger (texte
   + voix native), ou hors ligne (texte/voix, sans réseau).
3. Le patient ne révèle un signe important **que si la bonne question est
   posée** — c'est le principe déjà en place, inchangé.
4. Une fois l'entretien terminé, l'agent appuie sur **« Poser mon
   diagnostic »**, choisit une réponse parmi une liste à choix multiples
   (le bon diagnostic + 2-3 distracteurs plausibles).
5. Une page de récapitulatif s'affiche : les questions pertinentes posées,
   les signaux d'alerte donnés par le patient et leur explication, le bon
   diagnostic, les symptômes typiques de la maladie, la conduite à tenir,
   et un score final.

## 3. Décisions actées

| Sujet | Décision |
|---|---|
| Étape diagnostic | Écran dédié à choix multiples, ouvert depuis un bouton sur l'écran de conversation, suivi d'un écran de récapitulatif complet |
| Score | 60 % sur les points clés couverts pendant l'entretien (les points critiques comptant double), 40 % sur le diagnostic choisi (tout ou rien) |
| Voix hors ligne | Pas de moteur TTS embarqué. Chaque réplique du patient hors-ligne est un fichier audio pré-enregistré (TTS cloud one-shot ou voix humaine), puisque les réponses hors-ligne sont un ensemble fermé de phrases connues à l'avance |
| Mode hors-ligne | Conversation en lecture/écriture (texte ou voix, au choix de l'agent), avec un arbre à mots-clés (`OfflinePatientBrain`, déjà construit) qui débloque les répliques et les signaux d'alerte |
| Connexion | Firebase Auth anonyme dès le premier lancement (fonctionne hors-ligne après la création initiale), avec liaison optionnelle à un email/mot de passe plus tard pour récupérer sa progression sur un autre appareil |
| Scénarios | Un socle de scénarios embarqué dans l'app dès l'installation ; à la connexion, l'app vérifie sur Firestore s'il existe de nouveaux scénarios non présents localement et les ajoute |
| Ajout de contenu | Se fait pour l'instant directement depuis la console Firebase (pas d'écran d'administration dans l'app pour ce MVP) |

## 4. Contenu médical proposé (à valider)

Chaque scénario a maintenant une fiche complète : titre neutre affiché à
l'agent, diagnostic correct, distracteurs, signaux d'alerte avec leur
cause, symptômes typiques, conduite à tenir.

### Fièvre chez un enfant
- **Titre affiché :** *Un enfant fébrile depuis deux jours*
- **Diagnostic :** Suspicion de paludisme
- **Distracteurs :** Angine virale banale · Otite · Poussée dentaire
- **Signaux d'alerte :** moustiquaire trouée (exposition), voyage récent en
  zone marécageuse (zone à risque), léthargie/enfant très mou (signe de
  gravité)
- **Conduite à tenir :** orientation vers un centre de santé pour test
  rapide ; urgence si torpeur, convulsions ou refus de boire

### Saignement post-partum
- **Titre affiché :** *Une jeune mère inquiète, 5 jours après l'accouchement*
- **Diagnostic :** Suspicion d'endométrite (infection utérine du
  post-partum)
- **Distracteurs :** Simples suites de couches normales · Hémorroïdes ·
  Infection urinaire
- **Signaux d'alerte :** odeur inhabituelle des pertes, fièvre associée,
  douleur pelvienne
- **Conduite à tenir :** orientation urgente pour antibiothérapie ;
  saignement abondant + fièvre = signal à ne jamais minimiser

### Déshydratation
- **Titre affiché :** *Un agriculteur épuisé après une journée au champ*
- **Diagnostic :** Déshydratation / épuisement dû à la chaleur
- **Distracteurs :** Simple fatigue musculaire · Hypoglycémie · Début de
  grippe
- **Signaux d'alerte :** absence d'urine depuis le matin, crampes et
  vertiges
- **Conduite à tenir :** mise à l'ombre, réhydratation immédiate, repos ;
  urgence si confusion ou absence de transpiration malgré la chaleur
  (suspicion de coup de chaleur)

## 5. Ce qu'il reste à construire

### Contenu et données
- [ ] Valider le contenu médical ci-dessus avec une personne compétente
- [ ] Étendre le modèle `PatientScenario` : ajouter diagnostic correct,
      liste de distracteurs, signaux d'alerte structurés, symptômes,
      conduite à tenir (au-delà du simple `systemPrompt` actuel)
- [ ] Écrire le texte des ~9-10 répliques par personnage nécessaires au
      mode hors-ligne (déjà en grande partie fait dans
      `offline_scenarios.dart`)

### Audio hors-ligne
- [ ] Choisir la méthode de production (TTS cloud one-shot ou
      enregistrement humain)
- [ ] Générer/enregistrer les fichiers, nommés par
      `assets/audio/offline/<personnage>/<id_point_clé>.m4a`
- [ ] Service de lecture avec repli sur `flutter_tts` si un fichier manque

### Écrans
- [ ] Écran « Poser mon diagnostic » (liste à choix multiples)
- [ ] Écran de récapitulatif (questions posées, signaux d'alerte,
      diagnostic, symptômes, conduite à tenir, score)
- [ ] Adapter le feedback des modes Live/léger pour que Gemini juge aussi
      le diagnostic formulé librement par l'agent, avec la même grille que
      le mode hors-ligne

### Firebase
- [ ] Créer le projet Firebase (apps Android + iOS)
- [ ] Ajouter `firebase_core`, `firebase_auth`, `cloud_firestore`
- [ ] Authentification anonyme + flux de liaison à un compte email/mot de
      passe
- [ ] Modèle de données : profil utilisateur, historique de sessions
      (scénario, score, date, mode utilisé)
- [ ] Règles de sécurité Firestore (chacun ne lit/écrit que ses propres
      scores ; contenu des scénarios public en lecture)
- [ ] Logique de synchronisation : scénarios embarqués + détection des
      nouveaux scénarios disponibles en ligne, ajout à la base locale

### Stockage local
- [ ] Choisir `sqflite` ou `Hive` pour la persistance locale des scénarios
      téléchargés et des sessions en attente de synchronisation
- [ ] File d'attente des scores faits hors-ligne, envoyée dès le retour de
      connexion

## 6. Ce qui ne change pas

- Les trois paliers de conversation (Live / léger / hors-ligne) restent
  tels quels.
- `OfflinePatientBrain` et son système de mots-clés ne changent pas de
  logique, ils gagnent seulement une voix pré-enregistrée à la place de la
  synthèse en direct.
- Le principe central reste inchangé : le patient ne donne jamais son
  diagnostic lui-même, et ne révèle un signe important que si la bonne
  question est posée.