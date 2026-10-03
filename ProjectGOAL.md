# ProjectGOAL — Ilera : simulateur de formation des agents de santé

> **Statut :** plan de modifications pour le week-end du hackathon (**3–4 octobre 2026**).
> Track : *Small AI for Development* (Hack-Nation × World Bank Youth Summit), **Annexe A — Santé**.
> Ce document remplace l'ancienne version de `ProjectGOAL.md`. Les éléments marqués **[À VÉRIFIER]** ne doivent pas être affirmés dans la vidéo ou le README avant vérification.

---

## 1. Objectif

**Nom de l'application : Ilera.** *Ìlera* signifie « santé » en yoruba **[À faire confirmer par le/la relecteur·rice natif·ve, notamment l'écriture avec diacritiques]**. Le nom illustre directement la question du brief : *que signifie localiser le développement de l'IA ?*

Permettre à un agent de santé de première ligne de **s'entraîner à mener un entretien clinique** (recherche des signes d'alerte, orientation) avec un patient virtuel, **sur son téléphone, sans connexion, dans une langue locale : le yoruba**, et de recevoir un retour pédagogique reproductible.

L'outil est un **entraînement supervisé**. Il ne diagnostique pas de vrais patients et ne remplace ni un formateur ni les protocoles locaux.

### Énoncé du problème (format imposé par le brief, §08)

> Grâce à cet outil, **un agent de santé communautaire** s'**entraînera à repérer les signes d'alerte (fièvre de l'enfant, hémorragie du post-partum, déshydratation)** **avant sa première consultation réelle / entre deux formations** alors qu'il ne le ferait sinon **pas / tard / sans retour** ; nous le savons grâce à **[À COMPLÉTER : indicateur, source, pays, année]**.

Sources candidates pour la preuve (brief §7.2 et Annexe A) : Service Delivery Indicators (Banque mondiale), WHO Global Health Observatory (densité de personnel de santé), DHS / Service Provision Assessments. Choisir **un pays (Nigeria, si on reste sur le yoruba)** et citer l'année.

---

## 2. Lien avec Noor et le défi Santé

Le défi (Annexe A) demande d'améliorer *« une part significative de l'accès de Noor aux soins primaires, ou la capacité d'un agent de première ligne à la servir »*.

Notre lien, à rendre **explicite** dans le README et la vidéo :

- Noor consulte dans une clinique surchargée, où les soignants ne sont **pas toujours à jour des dernières recommandations** et manquent de temps par patient.
- Notre outil agit sur **la capacité de l'agent à la servir** : entraînement répété, hors ligne, sans formateur disponible, sur les situations à risque (fièvre de l'enfant, hémorragie du post-partum, déshydratation).
- Le critère « développement » (20 %) demande si le résultat compte pour la personne visée : on montre le chemin **entraînement → meilleur repérage des signes d'alerte → soin reçu par Noor**, **sans prétendre l'avoir mesuré**.

---

## 3. Décisions prises

| Sujet | Décision |
|---|---|
| Langue locale | **Yoruba** (Nigeria, Bénin, Togo). Nommée dans le README, la vidéo et l'app. |
| Parcours principal de la démo | **Hors ligne** (le cœur doit fonctionner sans réseau, règle 06). |
| Gemini Live | **Mode connecté bonus** (voix), pas le parcours principal. |
| Claude | **Moteur de compréhension texte en ligne** pour le yoruba (voir §7), plus aide au développement (voir §7.5). |
| Génération libre de réponses cliniques | **Désactivée par défaut** (risque d'hallucination). Réponses issues d'une liste fixe relue par un·e natif·ve. |
| Scoring | Reste **déterministe** (60 % couverture, 40 % diagnostic). Aucun LLM ne note. |

---

## 4. Modifications à faire (priorisées)

### P0 — indispensable pour être conforme au brief

| # | Modification | Fichiers concernés |
|---|---|---|
| 1 | Ajouter un **sélecteur de langue** (English / Yorùbá) et passer la langue au moteur de dialogue et à l'interface. | `lib/screens/simulation_screen.dart`, nouveau `lib/services/lang/app_language.dart` |
| 2 | **Contenu yoruba pour au moins 1 scénario** : réponses du patient, points clés, formulations d'exemple, consignes d'interface. | `lib/services/offline/offline_scenarios.dart` (ou fichiers JSON dédiés par langue) |
| 3 | **Matcher lexical yoruba hors ligne** avec normalisation des diacritiques (§6.2). Gecko-110m-en reste utilisé **uniquement pour l'anglais**. | `lib/services/offline/offline_patient_brain.dart`, nouveau `lib/services/lang/yoruba_normalizer.dart` |
| 4 | **Fail-safe visible** : sous le seuil de confiance, le patient ne devine pas ; l'app affiche un message du type « pas sûr — reformulez ou demandez à un formateur ». Message yoruba relu par un·e natif·ve. | `offline_patient_brain.dart`, `simulation_screen.dart` |
| 5 | **Relecture native** des textes cliniques yoruba (voir §6.3). Sans relecture, les afficher comme **« brouillon non vérifié »**. | contenu + `docs/DATA_SOURCES.md` |
| 6 | **Mini-benchmark** (§9) : mots-clés vs sémantique, anglais vs yoruba, avec erreurs incluses. | nouveau `docs/EVALUATION.md`, `test/` |
| 7 | **Fichier de sources et de limites des données** (§8). | nouveau `docs/DATA_SOURCES.md` |
| 8 | **Vidéo 2–5 min** (§12). Sans elle, pas de shortlist. | hors dépôt |

### P1 — fortement recommandé

| # | Modification | Fichiers concernés |
|---|---|---|
| 9 | **Intégration Claude** en mode en ligne (§7). | nouveau `lib/services/claude/claude_patient_service.dart` + petit backend proxy |
| 10 | **Vérifier le modèle Gemini Live** et la langue yoruba (§5). | `lib/services/live/gemini_live_service.dart` |
| 11 | **Sortir la clé Gemini du client** (jetons éphémères, §11). | `lib/main.dart`, backend |
| 12 | **Consentement explicite** avant tout envoi d'audio ou de texte à un service en ligne. | `simulation_screen.dart`, nouvel écran de consentement |
| 13 | **Audio yoruba préenregistré** par une personne native, pour au moins un scénario. | `assets/audio/offline/yo/` |
| 14 | **Téléchargement du modèle** reprenable, avec taille affichée ; option de side-load documentée. | gestion du plugin d'embeddings |
| 15 | Mettre à jour le **README** : langue, modes, limites, sources. | `README.md` |
| 16 | **Renommer l'app en « Ilera »** (nom affiché uniquement, voir note ci-dessous). | `README.md`, `lib/main.dart` (titre), `android/app/src/main/AndroidManifest.xml` (`android:label`), `ios/Runner/Info.plist` (`CFBundleDisplayName`), `pubspec.yaml` (description) |

> **Note renommage :** ne changer **ni l'identifiant de package** (`applicationId`, bundle id), **ni le nom du package Dart**, **ni le projet Firebase** (`aihackaton-5120f`) ce week-end. Cela casserait `google-services.json` et `firebase_options.dart` pour aucun gain. Seul le **nom affiché** change.

### P2 — si le temps le permet

- Deuxième scénario en yoruba.
- Voix hors ligne en yoruba via TTS embarqué **seulement si** la qualité est validée par un·e natif·ve ; sinon rester sur l'audio préenregistré.
- Reconnaissance vocale yoruba hors ligne : **ne pas promettre**. La lister dans les limites.

---

## 5. Gemini Live et le yoruba

- La documentation Gemini Live API (page « Capabilities », mise à jour le 18 sept. 2026) liste **Yoruba (`yo`)** parmi les 99 langues supportées. **[À VÉRIFIER dans la doc actuelle avant la vidéo.]**
- **« Supporté » ne veut pas dire « bon »** : la qualité de compréhension, de prononciation et de ton en yoruba doit être **testée avec un·e locuteur·rice natif·ve** sur nos scénarios, puis documentée (réussites **et** échecs).
- Les modèles audio natifs **choisissent la langue automatiquement** et n'acceptent pas de code de langue explicite. Pour forcer le yoruba, l'indiquer dans le **system prompt** (« Réponds uniquement en yoruba »).
- La transcription de sortie suit la langue de la réponse ; l'afficher dans le fil de discussion et signaler son caractère automatique.
- **Modèle** : le README indique que le modèle est défini dans `gemini_live_service.dart`. La documentation actuelle recommande `gemini-3.8-live` ; `gemini-live-2.5-flash-native-audio` a une date de retrait annoncée (13 déc. 2026). **[À VÉRIFIER]** et mettre à jour la chaîne du modèle.
- Les sessions audio seules sont limitées à 15 minutes sans gestion de session : prévoir une fin d'entretien propre.

---

## 6. Yoruba : plan d'implémentation

### 6.1 Moteur hors ligne

- **Anglais** : inchangé (Gecko 110M quantifié, repli mots-clés).
- **Yoruba** : matcher **lexical** par point clé : mots-clés, variantes, paraphrases écrites à la main, termes médicaux souvent dits en anglais.
- Expérience **sur ordinateur uniquement** : tester un modèle d'embeddings multilingue couvrant le yoruba sur le jeu de test. Ne pas le porter sur le téléphone ce week-end (taille et conversion). Rapporter le résultat dans `docs/EVALUATION.md`.

### 6.2 Normalisation des diacritiques

Les gens tapent souvent sans signes (ẹ, ọ, ṣ, accents tonaux). Appliquer **aux deux côtés** (entrée et lexique) : minuscules, décomposition Unicode (NFD), suppression des marques combinantes (U+0300–U+036F, U+0323…), nettoyage de la ponctuation.

**Limite à documenter :** supprimer les tons peut fusionner des mots distincts ; le matcher peut donc produire de faux rapprochements.

### 6.3 Relecture et validation

- Brouillon possible avec NLLB-200 ou Claude, **étiqueté « non vérifié »**.
- Relecture clinique et linguistique par au moins un·e locuteur·rice natif·ve (idéalement un·e professionnel·le de santé). Noter le nombre de relecteurs et leur profil.
- Les formulations de test doivent être écrites **par des humains**, pas générées, au moins en partie (§9).

### 6.4 Voix

- Voix préenregistrées par une personne native (repli TTS existant). Un seul scénario suffit pour la démo.
- Tester le TTS Android yoruba : s'il est absent ou mauvais, le dire dans les limites.

### 6.5 Ce que les données yoruba ne couvrent pas (à écrire dans `DATA_SOURCES.md`)

- Dialectes (Ọ̀yọ́, Ìjẹ̀bú, etc.) et variantes orthographiques.
- Alternance yoruba / anglais / pidgin.
- Peu de relecteurs, formulations écrites par l'équipe plutôt que collectées auprès d'agents de santé.
- Aucune validation clinique indépendante.

---

## 7. Intégration Claude (mode en ligne)

### 7.1 Ce que Claude fait, et ne fait pas

| Oui | Non |
|---|---|
| Comprendre une question **écrite en yoruba** et choisir, dans une **liste fermée**, le point clé couvert. | Générer librement des réponses cliniques (désactivé par défaut). |
| Renvoyer un niveau de confiance et un indicateur « besoin d'un humain ». | Noter l'entretien ou valider un diagnostic. |
| Aider au développement (§7.5). | Traiter de la voix : l'API Claude ne fait pas d'entrée/sortie audio. Pour la voix en ligne, on garde Gemini Live. |

### 7.2 Principe : « compréhension, pas génération »

1. L'agent tape sa question en yoruba.
2. L'app envoie à Claude : la question, l'`id` du scénario et la **liste des points clés** (id + description courte). Aucun identifiant utilisateur.
3. Claude répond en **JSON strict** :
   ```json
   { "key_point_ids": ["kp_03"], "confidence": 0.82, "needs_human": false }
   ```
4. L'app affiche la **réponse yoruba préécrite et relue** correspondant à `kp_03` (audio préenregistré si disponible).
5. Si `confidence` est sous le seuil, ou si aucun point clé ne correspond : message fail-safe (« pas sûr — reformulez ou demandez à un formateur »). **Pas de devinette.**
6. Le score est calculé par le code existant à partir des `id` confirmés.

Avantage : le texte affiché est toujours **vérifiable à l'avance** (« fixed list of answers » du glossaire du brief), ce qui limite les hallucinations.

### 7.3 Architecture

```
App Flutter ──► Proxy backend (clé Claude côté serveur) ──► API Claude
      │
      └─ hors ligne / échec / timeout ──► matcher lexical yoruba local ──► fail-safe
```

- **La clé Claude ne va jamais dans l'application** (contrairement à la clé Gemini actuelle). Le proxy applique : limitation de débit par installation, taille maximale de question, journalisation désactivée par défaut.
- Proxy possible : Cloud Run, Cloudflare Worker ou fonction serverless **[choisir ce qui est déjà accessible]**.
- Nouveau service : `lib/services/claude/claude_patient_service.dart`, avec timeout court et **repli automatique** vers le matcher local.
- **Modèle** : commencer par `claude-sonnet-5-5` (meilleure qualité attendue sur une langue à faibles ressources) ; tester `claude-haiku-4-5-20251001` pour le coût et la latence. **[Confirmer les noms de modèles et la tarification dans la console avant d'intégrer.]**
- Les « crédits Claude » doivent être des **crédits API (Claude Platform)** ; l'abonnement à l'application de chat ne fournit pas de clé API. **[À VÉRIFIER sur le compte.]**

### 7.4 Contraintes de prompt (résumé)

- Rôle : classifieur de questions pour un simulateur de formation, pas un soignant.
- Entrée : question en yoruba (avec ou sans diacritiques, éventuellement mélangée à de l'anglais).
- Sortie : JSON uniquement, ids tirés **exclusivement** de la liste fournie.
- Si la question est ambiguë, hors sujet ou dangereuse : `key_point_ids: []`, `needs_human: true`.
- Ne jamais ajouter de contenu médical.

### 7.5 Aide au développement avec Claude (hors parcours utilisateur)

À utiliser ce week-end pour gagner du temps, **toujours étiqueté et relu** :

- Générer des **candidats de paraphrases** pour le lexique yoruba (à relire).
- Faire une **rétro-traduction** yoruba → français/anglais pour détecter des contresens avant la relecture native.
- Produire un jeu de test **synthétique** (étiqueté comme tel), distinct du jeu écrit par des humains.
- Comparer les sorties Gemini Live et Claude sur les mêmes questions.

> **Ne pas affirmer** que Claude comprend mieux le yoruba que Gemini sans l'avoir mesuré (§9).

### 7.6 Mode génération libre (expérimental, désactivé par défaut)

Si activé : réponses du patient générées **uniquement à partir de la fiche du scénario** ; si un fait n'est pas dans la fiche, le patient répond qu'il ne sait pas ; bandeau « réponse générée, non vérifiée » ; pas utilisé dans la démo principale.

---

## 8. Données et sources

À créer : `docs/DATA_SOURCES.md`, avec **nom, source, licence, taille, usage, ce que la donnée ne couvre pas**.

### 8.1 Données qui montrent le problème (brief §7.2, type 1)

| Besoin | Source candidate |
|---|---|
| Absentéisme et équipement des soignants | Service Delivery Indicators (Banque mondiale) |
| Densité de personnel de santé | WHO Global Health Observatory |
| Comportement de recours aux soins, disponibilité à l'arrivée | DHS / Service Provision Assessments |
| Possession d'un téléphone / smartphone | GSMA Mobile Gender Gap Report |

Citer **pays, année, source**. Indiquer si un chiffre vient d'une modélisation.

### 8.2 Données avec lesquelles on construit (type 2)

| Usage | Source candidate | Remarque |
|---|---|---|
| Contenu clinique des scénarios | Protocoles OMS correspondants (à citer précisément) | **[À VÉRIFIER]** version et chapitre |
| Embeddings anglais | Gecko-110m-en (Apache-2.0, ~114–115 Mo) | déjà documenté |
| Langue yoruba (voix / texte) | Common Voice (yo), FLEURS (yo_ng), FLORES-200 / NLLB-200 (yor_Latn), MMS, ressources Masakhane | **[À VÉRIFIER]** disponibilité, licence et taille de chaque ressource |
| Jeu de test | Formulations écrites par des humains (équipe + relecteurs natifs) | taille et profil des auteurs à indiquer |
| Jeu synthétique | Généré par un LLM | **étiqueter « synthétique »** |

---

## 9. Évaluation (pour les critères « preuve que ça marche » et « valeur de l'IA »)

### Protocole

- **Jeu de test** : 60 à 100 formulations par scénario, avec la bonne étiquette (point clé) ou « aucune réponse pertinente ». Au moins une partie écrite par un·e natif·ve. **Jeu de calibrage et jeu de test séparés.**
- **Moteurs comparés** :
  1. Mots-clés (anglais)
  2. Gecko sémantique (anglais)
  3. Lexical yoruba normalisé
  4. Claude en ligne (yoruba)
  5. *(optionnel)* embeddings multilingues sur ordinateur
- **Métriques** : bonne réponse top-1, faux rapprochements, taux d'abstention correct (« pas sûr »), latence, taille du modèle.

### Tableau à publier dans `docs/EVALUATION.md` et dans la vidéo

| Moteur | Langue | Top-1 | Faux rapprochements | Abstentions correctes | Latence | Taille |
|---|---|---|---|---|---|---|
| … | … | … | … | … | … | … |

Inclure **les erreurs** et ce qu'on en conclut. La franchise est valorisée par le brief.

### Réponse prête à « et dans une langue moins bien supportée ? »

Ajouter une langue = un scénario traduit et relu, un lexique, quelques enregistrements et 50–100 formulations de test. Le coût principal est la **relecture humaine**, pas le réentraînement.

---

## 10. Garde-fous et IA responsable (critère pass/fail)

- **Humain dans la boucle** : l'outil forme ; une personne décide. Il n'agit jamais à la place de l'utilisateur.
- **Liste fermée de réponses** par défaut ; tout contenu généré est signalé.
- **Fail-safe** : « pas sûr — reformulez ou demandez à un formateur » plutôt qu'une réponse devinée.
- **Contenu non validé cliniquement** : bandeau permanent dans l'app et dans le README.
- **Biais** : tests uniquement avec des formulations de l'équipe ; l'écrire. Pas de généralisation à d'autres dialectes ni langues.
- **Pas de preuve d'amélioration des soins** : ne jamais présenter le score comme tel.
- **Vie privée** : traitement hors ligne par défaut ; consentement explicite avant tout envoi en ligne ; préciser où les données résident, qui peut les lire, et ce qui se passe si le téléphone est perdu ou partagé (exigence de l'Annexe A).

---

## 11. Sécurité

- **Clé Gemini** : retirer la constante du client. La doc Gemini indique que, pour une connexion client → serveur, il faut utiliser des **jetons éphémères**. Les émettre depuis le même backend que le proxy Claude.
- **Clé Claude** : uniquement côté serveur.
- **Firestore** : vérifier que les règles limitent l'accès à `users/{uid}` et à ses sessions.
- Ne rien mettre de secret dans l'asset `.env` (déjà déclaré dans `pubspec.yaml`).
- Ne pas enregistrer de transcription ni d'audio sans consentement.

---

## 12. Livrables (brief §08)

- [ ] **Prototype** : code ou lien, avec instructions pour lancer.
- [ ] **Vidéo de 2 à 5 minutes** contenant :
  - [ ] **Énoncé du problème** en une phrase (format du §1) avec la preuve citée.
  - [ ] **Rôle de l'IA** et pourquoi un SMS, un tableur ou une recherche ne feraient pas le même travail ; garde-fous.
  - [ ] **Démo de bout en bout** : choix du scénario → entretien en yoruba hors ligne → diagnostic → récapitulatif.
  - [ ] **Place de l'outil dans la journée de l'utilisateur** et pile technique.
  - [ ] **« Votre vision de la localisation de l'IA »**.
- [ ] README, `DATA_SOURCES.md`, `EVALUATION.md` à jour.
- [ ] Nom **Ilera** cohérent partout : écran d'accueil, README, titre de la vidéo, dépôt, formulaire de soumission.

### Pourquoi l'IA et pas un simple outil

Un questionnaire à choix multiples ne permet pas de **poser ses propres questions dans ses propres mots**. L'IA sert à rapprocher une question libre (avec fautes, sans diacritiques, mélangée à l'anglais) d'un point clé. Le benchmark (§9) doit **montrer ce que le sémantique ou Claude apporte réellement par rapport aux mots-clés** ; s'il n'apporte rien en yoruba, le dire et l'expliquer.

---

## 13. Calendrier suggéré

| Moment | À faire |
|---|---|
| **Samedi 3 oct.** | Sélecteur de langue, un scénario yoruba, matcher lexical + normalisation, fail-safe visible, recherche d'un·e relecteur·rice natif·ve, test Gemini Live en yoruba. |
| **Samedi soir** | Proxy + service Claude, consentement, premiers chiffres du benchmark. |
| **Dimanche 4 oct. (matin)** | Relecture native, audio yoruba, tableau d'évaluation final, `DATA_SOURCES.md`. |
| **Dimanche 4 oct. (après-midi)** | Enregistrement de la vidéo, README, soumission **avant la fin du week-end**. |

---

## 14. Hors périmètre ce week-end

- Reconnaissance vocale yoruba hors ligne.
- Modèle d'embeddings multilingue sur téléphone.
- Interface d'administration des scénarios.
- Validation clinique indépendante et étude d'impact sur les soins.
- Autres langues.