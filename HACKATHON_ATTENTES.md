# Ilera — Ce qu'on attend de nous (Small AI for Development)

> **Principe : on ne tord pas le projet.** Ilera reste un simulateur de formation pour agents de santé. Ce document dit **ce que le brief demande**, **où Ilera répond déjà**, **ce qu'il reste à produire** et **quels outils utiliser**. La plupart des manques sont du **cadrage et des livrables**, pas du code.
>
> Source : *Concept Note — Small AI for Development Hackathon* (World Bank Youth Summit × Hack-Nation), sections 01–10 et Annexe A (Santé). Complète `ProjectGOAL.md`.

---

## 1. L'objectif en une phrase

Construire, en un week-end (**3–4 octobre 2026**), **un outil d'IA « Small AI » pour un seul secteur (ici : Santé)**, qui améliore la situation d'une personne type, **Noor**, et montrer qu'il **fonctionne dans les contraintes réelles** : peu ou pas de connexion, appareil modeste, langue locale.

Question à laquelle répondre à travers l'outil : **« Que signifie localiser le développement de l'IA pour vous ? »**

### Qui est Noor (à garder en tête, pas à reconstruire)

Agricultrice de 38 ans dans les hauts plateaux d'Ondera, téléphone de base pour appels, SMS et mobile money, pas de Wi-Fi, données 3G achetées à la demande. Côté santé (Annexe A) : une clinique proche mais **surchargée**, des soignants bien intentionnés mais **pas toujours à jour des dernières recommandations**, avec **peu de temps par patient** et beaucoup de paperasse.

---

## 2. Défi Santé : ce que le brief demande exactement

> *Concevoir et démontrer une solution Small AI qui améliore une part significative de l'accès de Noor aux soins primaires **ou la capacité d'un agent de première ligne à la servir** ; par exemple dépistage, documentation, orientation, suivi, continuité des soins.*

**Position d'Ilera :** elle agit sur **la capacité de l'agent à servir Noor** (entraînement sur des situations à risque, hors ligne). C'est un angle **indirect** mais défendable. Il suffit de **le dire explicitement** (voir §6, cadrage). Aucune fonctionnalité à ajouter pour cela.

**Limite à respecter :** l'Annexe A ne propose volontairement aucun jeu de données d'imagerie ou de diagnostic. Ilera est un outil d'**entraînement**, jamais de diagnostic de vrais patients. Le dire clairement.

---

## 3. Les règles du brief (section 06) et l'état d'Ilera

| Règle du brief | État d'Ilera | À faire (minimum) |
|---|---|---|
| Tourne sur un appareil que l'utilisateur a déjà | 🟡 Android arm64 / iOS 15+ | Écrire noir sur blanc le public visé (agents de santé avec smartphone Android d'entrée de gamme) et ses limites. |
| **Le cœur fonctionne hors ligne** | ✅ English avec Gecko/repli lexical ; prototype texte Yorùbá lexical | Faire de ce mode **le parcours principal de la démo**. Gemini Live = bonus connecté. Parcours Yorùbá à valider sur téléphone et en mode avion. |
| Modèle assez petit pour être transféré sur connexion faible | 🟡 Gecko annoncé à 114 Mo par sa fiche modèle | Afficher la taille ; reprise et side-load restent à vérifier. |
| **Au moins une interaction en langue locale, langue nommée** | 🟡 Un scénario Yorùbá textuel est implémenté, matcher lexical et réponses préécrites | Faire relire par une personne Yorùbá et valider le parcours sur appareil ; le STT Yorùbá n'est pas disponible. |
| Humain dans la boucle (« la personne décide ») | ✅ Outil d'entraînement | Le dire dans la vidéo et le README. |
| Éviter les hallucinations | ✅ hors ligne (réponses préécrites) · 🟡 Live et feedback générés par Gemini | Le signaler comme limite ; message « pas sûr — demandez à un formateur » sous le seuil de confiance. |

---

## 4. Ce qu'il faut rendre (section 08)

À la fin du week-end (**4 octobre**) :

| Livrable | Obligatoire ? | État |
|---|---|---|
| **Prototype** : l'outil avec le code, ou un lien | Oui | 🟡 Dépôt GitHub à pousser, instructions de lancement |
| **Vidéo de 2 à 5 minutes** | **Oui : sans elle, pas de shortlist** | ❌ À tourner |

### Contenu de la vidéo (les 5 blocs imposés)

1. **Énoncé du problème, une phrase** au format :
   > *Grâce à cet outil, [utilisateur] [action] **avant / à temps** alors qu'il ne le ferait **pas / tard / moins bien** ; nous le savons grâce à [preuve].*
2. **Capacités IA** : ce que fait l'IA et **pourquoi un outil plus simple (SMS, tableur, recherche) ne ferait pas le même travail**. Citer les garde-fous.
3. **Démo de bout en bout** : choix du scénario → entretien → diagnostic → récapitulatif (capture d'écran ou diaporama).
4. **Place de l'outil dans la journée de l'utilisateur** : quand il l'ouvre, ce qu'il fait, ce qui se passe ensuite. Ajouter la pile technique.
5. **« Votre vision »** : ce que localiser l'IA veut dire pour vous.

#### Plan de vidéo suggéré (≈ 4 min)

| Temps | Contenu |
|---|---|
| 0:00–0:30 | Noor et sa clinique surchargée (2–3 phrases) |
| 0:30–1:00 | Phrase de problème + preuve chiffrée |
| 1:00–2:30 | Démo **hors ligne**, en **yoruba**, d'un scénario |
| 2:30–3:15 | Rôle de l'IA, garde-fous, tableau de mesures (§7) |
| 3:15–4:00 | Limites assumées + « ma vision de la localisation de l'IA » |

---

## 5. Les critères de jugement (section 09) : où se joue la note

| Critère | Poids | Ce que les juges demandent | Réponse d'Ilera |
|---|---|---|---|
| **Solution construite (fidélité Small AI)** | 25 % | Marche-t-elle de bout en bout **dans les contraintes du secteur** ? | Démo hors ligne fluide : c'est le point fort à mettre en avant. |
| **Pertinence et impact pour le développement** | 20 % | Vrai problème du brief ? Le résultat compte-t-il pour la personne visée ? | Cadrage Noor + preuve chiffrée (§6). |
| **Ancrage dans les données** | 15 % | Combler une lacune identifiée ? Modélisation des données saine ? | Fichier de sources + ce que les données **ne couvrent pas**. |
| **Preuve que ça marche** | 15 % | Convient-elle aux contraintes ? Ajoute-t-elle d'autres contraintes ? | Petit tableau de mesures (§7). |
| **Clarté, design, inclusivité, valeur de l'IA** | 15 % | Que fait l'IA ? Un outil plus simple ferait-il pareil ? | Comparaison mots-clés vs sémantique, dite honnêtement. |
| **Reproductibilité et suite** | 10 % | Un autre contexte peut-il réutiliser l'idée ? | « Une langue de plus = un scénario traduit, relu, quelques enregistrements. » |
| **IA responsable, données, sécurité** | **Réussite / échec** | Limites respectées ? Vie privée, consentement, biais, supervision humaine crédibles ? | Voir §8. **Un échec ici élimine l'entrée.** |

---

## 6. Cadrage de Noor (sans changer le produit)

À mettre dans le README et en ouverture de la vidéo. Les chiffres et sources sont à compléter.

**Phrase de problème (brouillon) :**

> Grâce à Ilera, **un agent de santé communautaire** s'entraînera **à repérer les signes d'alerte d'urgences courantes (fièvre de l'enfant, hémorragie du post-partum, déshydratation)** **avant sa prochaine consultation réelle, hors connexion et en yoruba**, alors qu'il n'aurait sinon **ni formateur disponible ni pratique supervisée** ; nous le savons grâce à **[indicateur, source, pays, année]**.

**Chaîne logique à énoncer (sans prétendre l'avoir mesurée) :**
entraînement répété → meilleur repérage des signes d'alerte → consultation de meilleure qualité pour une patiente comme Noor.

**Preuves candidates (section 7.2 et Annexe A) :** Service Delivery Indicators (Banque mondiale), WHO Global Health Observatory (densité de personnel de santé), DHS / Service Provision Assessments, GSMA Mobile Gender Gap Report (appareil réellement possédé). Citer **pays, année, source**, et préciser si un chiffre vient d'une modélisation.

---

## 7. Langue locale et preuve que ça marche

### Langue : yoruba (décision prise)

- Doc Gemini Live API : le yoruba (`yo`) est listé parmi les langues supportées **[À VÉRIFIER avant la vidéo]**. « Supporté » ne garantit pas la qualité : à tester avec un·e locuteur·rice natif·ve.
- **Gecko-110m-en est anglais seulement** : pour le yoruba, utiliser un matcher lexical avec **normalisation des diacritiques** (ẹ, ọ, ṣ, tons).
- Contenu clinique en yoruba : **relu par un·e natif·ve**, sinon étiqueté « brouillon non vérifié ».
- **Minimum acceptable :** un scénario complet en yoruba, nommé comme tel, avec ses limites écrites.

### Mini-tableau de mesures (à montrer dans la vidéo)

Quelques dizaines de formulations de test par scénario (dont une partie écrite par un·e natif·ve), comparées entre moteurs :

| Moteur | Langue | Bonnes réponses | Faux rapprochements | « Pas sûr » justifié | Latence | Taille |
|---|---|---|---|---|---|---|
| Mots-clés | EN | … | … | … | … | … |
| Gecko (sémantique) | EN | À mesurer | À mesurer | À mesurer | À mesurer | 114 Mo (fiche modèle) |
| Lexical Yorùbá | YO | 12/12 cas positifs | 0/5 faux rapprochements sur les cas négatifs | 5/5 abstentions négatives ; 1/1 répétition | À mesurer | Matcher lexical |

Les résultats Yorùbá sont issus de 18 cas écrits par l'équipe, non représentatifs
et non relus formellement. Ils ne mesurent pas la qualité sur des conversations
réelles. La comparaison anglaise et Gecko reste à faire ; voir
`docs/EVALUATION.md`. **Montrer aussi les erreurs.** Le brief valorise
l'honnêteté sur les limites, et c'est noté.

---

## 8. Garde-fous (critère réussite / échec)

À écrire noir sur blanc dans le README et à mentionner dans la vidéo :

- **Humain dans la boucle** : outil d'entraînement ; aucune action au nom de l'utilisateur.
- **Contenu non validé cliniquement** : bandeau permanent.
- **Fail-safe** : sous le seuil de confiance, « pas sûr — reformulez ou demandez à un formateur », jamais de réponse devinée.
- **Vie privée** : où sont les données, qui peut les lire, que se passe-t-il si le téléphone est perdu ou partagé (exigence de l'Annexe A). Hors ligne par défaut ; consentement explicite avant d'envoyer de l'audio à Gemini.
- **Biais et couverture** : tests faits par l'équipe, peu de relecteurs, un seul dialecte testé ; le dire.
- **Pas de promesse d'impact** : le score est un score d'entraînement, pas une preuve d'amélioration des soins.

---

## 9. Données : ce que le brief exige (section 07)

Chaque entrée doit **citer ses sources de données**. Deux types :

1. **Données qui montrent le problème** : source, année, pays.
2. **Données avec lesquelles on construit** : nom, source, **licence, taille**, et surtout **ce qu'elles ne couvrent pas** (**cette partie est notée**). Les données synthétiques sont permises **si elles sont étiquetées**.

Les jeux listés dans le brief sont des **suggestions** ; vérifier soi-même les conditions d'accès.

Le fichier `docs/DATA_SOURCES.md` est disponible avec les ressources du
prototype et leurs limites. Les références locales pour étayer le problème et
la source clinique applicable restent à choisir et à citer avant soumission.

---

## 10. Outils à utiliser

| Besoin | Outil / ressource | Statut |
|---|---|---|
| Application | Flutter (déjà en place) | ✅ |
| Voix en ligne | Gemini Live API (déjà en place) ; vérifier le modèle recommandé actuel | 🟡 |
| IA hors ligne anglais | Gecko-110m-en quantifié via LiteRT (déjà en place) | ✅ |
| IA hors ligne yoruba | Matcher lexical + normaliseur Unicode | 🟡 Prototype implémenté ; validation native et tests appareil à faire |
| Compréhension texte en ligne (option) | Claude via un petit proxy serveur ; **jamais la clé dans l'app** | Optionnel |
| Compte, progression, scénarios | Firebase (déjà en place) ; vérifier les règles Firestore | 🟡 |
| Données de langue | Common Voice, FLEURS, FLORES-200 / NLLB-200, MMS, Masakhane | À citer |
| Données de preuve du problème | SDI, WHO GHO, DHS / SPA, GSMA | À citer |
| Contenu clinique | Protocoles OMS correspondant aux scénarios | À citer |
| Mesures | Test Dart sur 18 formulations yoruba écrites par l'équipe | 🟡 Première mesure disponible ; corpus représentatif et comparaison des moteurs à faire |
| Vidéo | Enregistrement d'écran du téléphone + voix off (par exemple OBS Studio ou l'enregistreur de l'appareil) | ❌ |
| Code | GitHub : `Worsland/aiHackahton` | 🟡 |

---

## 11. Minimum vital vs bonus

### Le minimum pour être dans la course

- [ ] Prototype fonctionnel poussé sur GitHub, avec instructions de lancement.
- [ ] **Un scénario jouable en yoruba**, langue nommée.
- [ ] Parcours **hors ligne** démontré (idéalement en mode avion).
- [ ] **Vidéo 2–5 min** avec les 5 blocs.
- [ ] Phrase de problème avec **une preuve citée**.
- [x] `docs/DATA_SOURCES.md` décrit les ressources actuelles et les limites ; les sources du problème et du protocole clinique restent à compléter avant soumission.
- [ ] Garde-fous écrits (§8), dont le message « pas sûr ».
- [ ] Aucun secret dans le dépôt.

### Bonus si le temps le permet

- [ ] Mini-tableau de mesures (§7).
- [ ] Audio yoruba préenregistré par une personne native.
- [ ] Intégration Claude en ligne.
- [ ] Deuxième scénario en yoruba.

---

## 12. Calendrier officiel

| Date | Événement |
|---|---|
| Septembre 2026 | Ouverture des candidatures |
| **3–4 octobre 2026** | **Week-end de compétition : rendu à la fin** |
| 5–6 octobre | Présélection par les experts de chaque secteur |
| 19–22 octobre | Global AI & Digital Summit, Séoul |
| **21 octobre** | Ignite Talk des gagnants (un gagnant par secteur, trois au total) |

Éligibilité : 18 à 35 ans.
