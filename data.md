# data.md — Sources et données d'Ilera

> Projet : **Ilera**, simulateur de formation hors ligne pour agents de santé (yoruba / anglais).
> Hackathon *Small AI for Development* — Annexe A (Santé). Ce fichier répond à la section 7.2 du brief : (1) données qui montrent le problème, (2) données avec lesquelles on construit, **et ce qu'elles ne couvrent pas** (partie notée).
> **Dernière vérification des liens et chiffres : 4 octobre 2026.** Tout ce qui est marqué **[À VÉRIFIER]** n'a pas été contrôlé à la source et ne doit pas être affirmé tel quel.

**Règle de citation.** Chaque chiffre est donné avec : constat, zone géographique, année des données, année de publication, population/échantillon, lien, emplacement dans la source, courte citation originale (≤ 15 mots, une seule par source), limites.

---

## 1. Chiffres à retenir (priorité Afrique subsaharienne, sources récentes)

| # | Chiffre | Source | Zone | Données | Où l'utiliser |
|---|---|---|---|---|---|
| 1 | La région n'a que **46 %** des agents de santé dont elle a besoin ; pénurie projetée de **5,85 millions** en 2030 (révisée de 6,1 M). | OMS Afrique, *State of the Health Workforce in Africa 2026* | Région africaine de l'OMS (47 pays) | 2024 | Vidéo (contexte), README |
| 2 | Les agents de santé posent un diagnostic correct dans environ **62 %** des cas et un traitement conforme aux recommandations dans environ **40 %** ; **27 %** dans les cas à plusieurs affections. | Même rapport (synthèse pondérée d'études multi-pays) | Région africaine de l'OMS | Études multi-pays, années non précisées dans le résumé | **Vidéo (chiffre principal)**, README |
| 3 | Les formations bien conçues améliorent la compétence de **7,5 à 12,1 %**, mais les gains sont difficiles à maintenir sans mentorat, supervision et assurance qualité. | Même rapport | Région africaine de l'OMS | idem | README (limites) : justifie la supervision humaine |
| 4 | **1,15 million** d'agents de santé communautaires (+35 % en 2 ans, 20 % de la main-d'œuvre) ; densité **9,94 pour 10 000** habitants contre un seuil de 11,63. | Même rapport | Région africaine de l'OMS | 2024 | README (public cible) |
| 5 | En Afrique subsaharienne, **27 %** de la population utilisait Internet mobile, avec un écart d'usage de **60 %** ; **presque deux tiers** des abonnés à Internet mobile utilisaient un smartphone 3G ou un téléphone basique. | GSMA, *State of Mobile Internet Connectivity 2024* | Afrique subsaharienne | Fin 2023 | Vidéo (pourquoi hors ligne), README |
| 6 | Un appareil d'entrée de gamme connecté coûte **99 %** du revenu mensuel moyen des 20 % les plus pauvres de la région. | Même rapport GSMA (2024) | Afrique subsaharienne | Fin 2023 | README |

> Les lignes 1 à 4 viennent d'un même rapport OMS ; ce n'est **pas** quatre sources indépendantes.

---

## 2. Données qui montrent le problème — sources principales (Afrique subsaharienne)

### S1. OMS Afrique — *State of the Health Workforce in Africa 2026: Plan, train and retain*

- **Constats :** voir lignes 1 à 4 du tableau §1. Le rapport conclut aussi que la mauvaise compétence des prestataires est une contrainte plus forte pour la qualité des soins que le manque de ressources seul.
- **Zone et années :** Région africaine de l'OMS (47 pays). Données de stock au 31 déc. 2024 (National Health Workforce Accounts). Publication : **mai 2026** (lancement le 6 mai 2026, Accra).
- **Population :** effectifs déclarés par les États sur 27 groupes de professions ; la compétence repose sur des synthèses d'études, pas sur une enquête propre à ce rapport.
- **Lien :** [page de la publication](https://www.afro.who.int/publications/state-health-workforce-africa-2026-plan-train-and-retain) · [PDF](https://www.afro.who.int/sites/default/files/2026-05/State%20of%20the%20Health%20Workforce%20in%20Africa%202026.pdf) · [communiqué](https://www.afro.who.int/news/africas-health-workforce-expands-shortages-unemployment-and-migration-intensify-who-report)
- **Emplacement :** Foreword, p. vi (62 % / 40 %) ; Executive summary, p. xii (« competence remains a major bottleneck », 27 %, 7,5–12,1 %) ; Chapitre 3, key findings, p. 28 ; section 2.1.3.7, p. 20 (agents de santé communautaires) ; Executive summary, p. xiii (46 %, 5,85 M).
- **Citation (EN) :** « correct diagnosis rates around 62% and treatment accuracy approximately 40% » (Foreword, p. vi).
- **Limites :**
  - « Région africaine de l'OMS » **n'est pas** « Afrique subsaharienne » : elle compte 47 pays et inclut l'Algérie. Écrire « Région africaine de l'OMS » ou « Afrique », pas « Afrique subsaharienne » pour ces chiffres.
  - Le communiqué de presse dit que le traitement est approprié dans « 40 % de ces cas » ; le rapport dit « dans 40 % des cas ». **Utiliser la formulation du rapport.**
  - Les études sources de la synthèse sur la compétence (références 11 à 14) et la section 3.5 (p. 34) n'ont **pas été lues** : **[À VÉRIFIER]** avant de préciser la méthode (cas cliniques ou autre).
  - « 7,5 % à 12,1 % » : le résumé ne précise pas si ce sont des points de pourcentage ou une amélioration relative. **[À VÉRIFIER]**
  - Les définitions d'« agent de santé communautaire » varient selon les pays.
  - Le rapport ne dit rien sur la formation par simulation ni sur la langue.

### S2. Banque mondiale — Service Delivery Indicators (SDI), synthèse sur 9 pays africains

- **Constat :** les prestataires des établissements de niveau inférieur obtiennent des résultats nettement plus faibles aux cas cliniques simulés, alors que ce sont ces établissements que les patients consultent en premier. Les médecins et officiers cliniques obtiennent 67 % de diagnostics corrects, les infirmiers 55 % et les autres personnels 36 % (moyenne sur l'échantillon). La moyenne nationale va de 69 % (Tanzanie) à **40 % (Nigeria)**.
- **Zone et années :** neuf pays d'Afrique subsaharienne ; enquêtes de 2013 à 2018 (Kenya 2018, Madagascar 2016, Mozambique 2014, Niger 2015, Nigeria 2013, Sierra Leone 2018, Tanzanie 2016, Togo 2013, Ouganda 2013). Publication : 2021.
- **Échantillon :** 7 810 établissements, 66 151 prestataires listés, 13 996 entretiens sur cas cliniques.
- **Source :** Gatti, Andrews, Avitabile, Conner, Sharma, Chang (2021), *The Quality of Health and Education Systems Across Africa*, Banque mondiale. DOI 10.1596/978-1-4648-1675-8 · [PDF](https://documents1.worldbank.org/curated/en/380481637326015488/pdf/The-Quality-of-Health-and-Education-Systems-Across-Africa-Evidence-from-a-Decade-of-Service-Delivery-Indicators-Surveys.pdf)
- **Emplacement :** Executive summary, p. 3 ; chapitre 2, p. 31 (précision diagnostique) ; tableau 2.1, p. 23 (échantillon).
- **Citation (EN) :** « providers at lower-level facilities score noticeably worse » (p. 3).
- **Limites :**
  - Données **anciennes** (2013 à 2018) : à présenter comme historiques, à mettre à côté de S1 (2024).
  - Cas cliniques simulés : les auteurs reconnaissent qu'ils peuvent être moins fiables que des patients standardisés (p. 30).
  - Nigeria : enquête dans 12 États sur 36, **non représentative** nationalement (p. 22).
  - Catégories : médecins, infirmiers, « autres » ; les agents de santé communautaires ne sont pas isolés dans les chapitres consultés.
  - Aucune donnée sur l'efficacité d'une formation ni sur la langue.

### S3. Ekpin et al. — supervision et soutien des agents de santé communautaires en Afrique subsaharienne (revue systématique, préprint)

- **Constat :** les agents de santé communautaires de la région affrontent une formation, des ressources et un soutien limités. Vu leurs faibles exigences de recrutement dans de nombreux pays, une formation continue et des rappels sont essentiels ; la plupart des études incluses proposaient des formations initiales courtes.
- **Zone et années :** Afrique subsaharienne ; 55 études publiées de 2013 à 2023. Publication : préprint de **juillet 2024**.
- **Population :** 55 études sur les interventions de supervision, d'aides au travail, d'incitations et de formation.
- **Source :** Ekpin VI, Nwankwo HE, Akwaowo CD, Blencowe H. *Supervision and Support Interventions Targeted at Community Health Workers in Sub-Saharan Africa: A Systematic Review…* DOI 10.21203/rs.3.rs-4670975/v1 · [lien](https://www.researchsquare.com/article/rs-4670975/v1)
- **Emplacement :** Discussion (page non vérifiée).
- **Citation (EN) :** « ongoing in-service and refresher training are crucial ».
- **Limites :**
  - **Préprint** : à vérifier s'il a été publié depuis, et si les chiffres ont changé. **[À VÉRIFIER]**
  - Revue de synthèse, pas de données nouvelles ; ne teste pas la formation par simulation ni la langue.

### S4. GSMA — connectivité mobile en Afrique subsaharienne

- **Constat :** (fin 2023, rapport 2024) l'Afrique subsaharienne est la région la moins connectée : 27 % de la population utilise Internet mobile, 13 % n'a pas de couverture et 60 % vit sous couverture sans l'utiliser ; presque deux tiers des abonnés à Internet mobile utilisent un smartphone 3G ou un téléphone basique ; un appareil d'entrée de gamme représente 99 % du revenu mensuel moyen des 20 % les plus pauvres.
- **Mises à jour :** *State of Mobile Internet Connectivity 2025* (9 sept. 2025) : au niveau mondial, 58 % de la population utilise Internet mobile et l'écart d'usage est de 38 % ; 75 % des 40 millions de personnes nouvellement couvertes en 2024 vivent en Afrique subsaharienne. *2026* (sept. 2026) : 4,8 milliards d'utilisateurs fin 2025 (59 %), écart d'usage de 38 %, écart de couverture de 3 % ; le rapport examine aussi la hausse du coût de la mémoire, qui rend les appareils moins abordables.
- **Population :** population mondiale, ventilée par région ; échantillon d'enquêtes dans des pays à revenu faible et intermédiaire (taille non vérifiée).
- **Liens :** [communiqué 2024](https://www.gsma.com/newsroom/press-release/new-gsma-report-shows-mobile-internet-connectivity-continues-to-grow-globally-but-barriers-for-3-45-billion-unconnected-people-remain/) · [communiqué 2025](https://www.gsma.com/newsroom/press-release/gsma-calls-for-renewed-focus-on-closing-the-usage-gap-as-more-than-3-billion-people-remain-offline-despite-available-mobile-internet-services/) · [page du rapport 2026](https://www.gsma.com/somic/)
- **Emplacement :** communiqués (section « Closing the gaps » et « Breaking barriers » pour 2024).
- **Citation (EN) :** « almost two thirds in Sub-Saharan Africa » (2024, sur les 3G / téléphones basiques).
- **Limites :**
  - Le GSMA est l'organisme de l'industrie mobile, pas une institution intergouvernementale ; le rapport est financé par le FCDO britannique et Sida via la Fondation GSMA.
  - Les chiffres **spécifiques à l'Afrique subsaharienne 2025/2026** n'ont **pas** été vérifiés sur le rapport lui-même. Un article de presse cite 906 millions de personnes (≈ 60 % de la population de l'Afrique) dans l'écart d'usage en 2025 ; la page « Mobile Economy Africa 2026 » parle de près d'un milliard de personnes en Afrique. Ces deux chiffres portent sur **l'Afrique**, pas sur l'Afrique subsaharienne seule. **[À VÉRIFIER]**
  - Les chiffres mesurent l'usage d'Internet, pas la possession d'un téléphone : un agent peut avoir un téléphone sans utiliser Internet mobile.
  - Rien sur les agents de santé en particulier.

---

## 3. Complément local : Nigeria et contexte yoruba

> Le projet cible le yoruba (Nigeria, Bénin, Togo). Ces études nigérianes servent d'**exemples locaux**, pas de preuve de portée régionale.

### L1. Ajisegiri et al. — agents de santé communautaires et soins de l'hypertension et du diabète au Nigeria (*Frontiers in Public Health*, 2023)

- **Constat :** les agents citent comme obstacles les plus fréquents une formation insuffisante (84 %), un manque d'équipement (81 %), une infrastructure déficiente (71 %) et une supervision insuffisante (52 %). Ils réalisent plus d'activités que celles pour lesquelles ils ont reçu une formation, avec un écart de 8 à 31 points. 16 % ne reçoivent aucune supervision.
- **Pays et années :** Nigeria ; collecte juillet à septembre 2019 ; publication 26 janvier 2023.
- **Population :** 77 agents interrogés (9 CHO, 53 CHEW, 15 JCHEW ; 85 % de réponse) dans 13 centres de soins primaires de 4 États, avec 13 groupes de discussion et des entretiens.
- **Lien :** DOI 10.3389/fpubh.2023.1038062 · [texte](https://www.frontiersin.org/journals/public-health/articles/10.3389/fpubh.2023.1038062/full)
- **Emplacement :** Results → Survey findings ; tableaux 1 et 2.
- **Citation (EN) :** « CHWs engaged in more activities than they were formally trained for ».
- **Limites :** sujet = hypertension et diabète ; données déclaratives (biais de courtoisie reconnu par les auteurs) ; États **non nommés** (on ne sait pas s'ils sont yorubaphones) ; entretiens menés **en anglais** ; le résumé annonce 76 agents, les résultats 77 ; les auteurs recommandent surtout des algorithmes simplifiés au point de soin.

### L2. Banque mondiale — SDI Nigeria 2013

- **Constat :** diagnostic correct en moyenne dans **40 %** des cas simulés (le plus bas des neuf pays).
- **Pays et années :** Nigeria ; visites de juillet 2013 à janvier 2014.
- **Échantillon :** 2 385 établissements, 21 318 prestataires listés, 5 017 entretiens sur cas ; **12 États dont Ekiti et Osun** (États yorubaphones).
- **Liens :** [catalogue de microdonnées](https://microdata.worldbank.org/index.php/catalog/2559) ; chiffre repris de S2 (p. 31).
- **Limites :** voir S2 ; résultats non ventilés par État dans les chapitres consultés.

### L3. Akinwumi et al. — connaissances des agents de soins primaires, État d'Osun (*African Journal of Primary Health Care & Family Medicine*, 2021)

- **Constat :** sur 30 points, score moyen de 17,76 (rural) et 17,62 (urbain) ; connaissance « adéquate » chez 31,0 % des agents ruraux et 23,0 % des urbains, sans différence significative.
- **Pays et années :** Nigeria, État d'Osun ; année de collecte non indiquée dans le résumé ; publication 29 juin 2021.
- **Population :** 400 agents de soins primaires dans 6 zones rurales et 6 urbaines ; questionnaire de cas écrit sur 3 maladies non transmissibles.
- **Lien :** DOI 10.4102/phcfm.v13i1.2873 · [lien](https://phcfm.org/index.php/phcfm/article/view/2873)
- **Emplacement :** résumé (Results, Conclusion). Texte intégral non consulté : pas de page ni de tableau.
- **Citation (EN) :** « had a poor knowledge regarding the prevention and control of NCDs ».
- **Limites :** tous les agents de soins primaires, pas seulement les agents communautaires ; maladies non transmissibles seulement ; un seul État ; seuil d'« adéquat » défini par les auteurs ; n'aborde pas la langue.

### L4. Arogundade et al. — besoins de formation en vaccination (*BMC Health Services Research*, 2019)

- **Constat :** le résumé indique que 83 % des agents ne savaient pas distinguer vaccins vivants atténués et vaccins inactivés ; le texte des résultats dit plutôt que plus de 50 % ne le savaient pas dans les trois États. Seuls 53 % savaient calculer le taux d'abandon vaccinal.
- **Pays et années :** Nigeria ; année de collecte non précisée (article reçu en février 2018, publié le 14 septembre 2019).
- **Population :** 90 agents de santé (surtout CHO et CHEW) et 27 formateurs ; États de Bauchi, Niger et Rivers.
- **Lien :** DOI 10.1186/s12913-019-4514-2 · [lien](https://link.springer.com/article/10.1186/s12913-019-4514-2)
- **Emplacement :** résumé ; Results → « Findings from health workers' assessment », fig. 3.
- **Citation (EN) :** « could not differentiate between the live attenuated and killed vaccines ».
- **Limites :** sujet = vaccination ; échantillon restreint et choisi volontairement ; aucun de ces États n'est majoritairement yorubaphone ; mesure en partie déclarative (Méthodes) ; chiffres du résumé et des résultats différents ; les auteurs rappellent que financement, supervision et redevabilité pèsent autant que la formation.

---

## 4. Données avec lesquelles on construit (brief §7.2, type 2)

> **À compléter par l'équipe avant la soumission.** Les licences et tailles marquées [À VÉRIFIER] n'ont pas été contrôlées.

| Élément | Source | Licence | Taille | Usage | Ce que ça ne couvre pas |
|---|---|---|---|---|---|
| Modèle d'embeddings anglais | Gecko-110m-en, quantifié (LiteRT) | Apache-2.0 (d'après le README) | ≈ 114–115 Mo | Rapprocher une question en anglais d'une réponse préécrite | **Anglais seulement** ; non calibré sur des questions de vrais agents |
| Scénarios cliniques | Rédigés par l'équipe | À définir | _n_ scénarios | Patient virtuel, points clés | **Non validés cliniquement** ; protocoles OMS de référence à citer **[À COMPLÉTER]** |
| Lexique et réponses yoruba | Équipe + relecteur·rice natif·ve | À définir | _n_ réponses | Compréhension et réponses en yoruba | Dialectes, alternance yoruba/anglais/pidgin, orthographe variable ; _n_ relecteurs |
| Jeu de test | Formulations écrites par des humains (équipe + natifs) | À définir | _n_ formulations | Mesurer mots-clés vs sémantique | Pas collecté auprès d'agents de santé réels |
| Jeu de test synthétique (si utilisé) | Généré par un LLM | — | _n_ | Compléter le jeu de test | **Étiqueter « synthétique »** ; ne pas mélanger avec le jeu humain |
| Ressources de langue (voix, texte) | Common Voice (yo), FLEURS (yo_ng), FLORES-200 / NLLB-200, MMS, Masakhane (cités par le brief) | **[À VÉRIFIER]** | **[À VÉRIFIER]** | Brouillon de traduction, tests | Qualité du yoruba à valider avec un·e natif·ve |

### Ce que nos données ne couvrent pas (à garder dans le README)

- **Aucune donnée d'utilisateurs réels** : pas de test avec des agents de santé.
- **Aucune validation clinique indépendante** des scénarios.
- **Une seule langue locale** (yoruba) ; pas de garantie pour une autre langue peu dotée.
- **Les sources du §2 et §3 mesurent un besoin général**, pas l'efficacité de la formation par simulation, ni un besoin en yoruba.

---

## 5. Ce qu'on ne peut pas affirmer

- **« Ilera améliore le diagnostic ou les soins. »** Aucune source ne le montre ; Ilera n'a pas été évaluée sur des soins.
- **« 40 % / 62 % des agents de santé communautaires diagnostiquent correctement. »** Les chiffres portent sur des prestataires de profils différents ; les agents communautaires ne sont pas isolés.
- **« La formation par simulation fonctionne. »** L'OMS 2026 indique qu'une formation bien conçue améliore la compétence, mais pas que la simulation en particulier le fait, ni que les gains durent sans supervision.
- **« Les agents de santé yorubaphones ont besoin d'une formation en yoruba. »** Aucune source récupérée ne le traite.
- **« Afrique subsaharienne » pour les chiffres OMS.** C'est la Région africaine de l'OMS (47 pays, Algérie incluse).
- **Chiffres GSMA 2025/2026 pour l'Afrique subsaharienne.** À lire dans le rapport avant de les citer.

---

## 6. Formulations prêtes à l'emploi

### Phrase de problème (vidéo, format du brief)

> Grâce à Ilera, **un agent de santé communautaire** pourra s'**entraîner, hors ligne et en yoruba, à poser les bonnes questions et à repérer les signes d'alerte** **avant sa prochaine consultation**, alors que les formations ponctuelles sont difficiles à maintenir sans supervision continue ; nous le savons grâce au rapport **OMS Afrique 2026** (diagnostic correct dans environ 62 % des cas, traitement conforme dans environ 40 %). **Nous ne prétendons pas qu'Ilera améliore ces résultats.**

### Paragraphe README (« Contexte et problème »)

> Noor consulte dans une clinique surchargée, où les soignants manquent de temps et ne sont pas toujours à jour des dernières recommandations. En Afrique, la Région africaine de l'OMS ne dispose que de 46 % des agents de santé nécessaires, et une synthèse d'études rapportée par l'OMS en 2026 indique un diagnostic correct dans environ 62 % des cas et un traitement conforme aux recommandations dans environ 40 %. L'OMS note aussi que les formations bien conçues améliorent la compétence, mais que ces gains sont difficiles à maintenir sans supervision. Ilera propose un entraînement supplémentaire, utilisable hors ligne et en yoruba, destiné à **compléter** la supervision humaine, pas à la remplacer. En Afrique subsaharienne, près de deux tiers des abonnés à Internet mobile utilisent un smartphone 3G ou un téléphone basique (GSMA, fin 2023), ce qui motive le fonctionnement hors ligne. Ces sources décrivent un besoin général : elles ne mesurent ni l'efficacité de la simulation ni un besoin propre au yoruba.

### One-liner (EN, slide)

> *WHO Africa (2026): about 62% correct diagnoses and about 40% guideline-aligned treatment across studies. Ilera offers offline practice in Yoruba — a complement to supervision, not proof of better care.*

---

## 7. Checklist avant soumission

- [ ] Ouvrir le PDF OMS 2026 et vérifier p. vi, p. xii, p. xiii, p. 20 ; lire la section 3.5 (p. 34) et les références 11 à 14.
- [ ] Remplacer « Région africaine de l'OMS » par ce que dit la source ; ne pas écrire « Afrique subsaharienne » pour ces chiffres.
- [ ] Ouvrir le rapport GSMA 2026 et lire les chiffres spécifiques à l'Afrique subsaharienne, ou garder ceux de 2024 en indiquant l'année.
- [ ] Vérifier si le préprint Ekpin et al. (2024) est publié et si les chiffres ont changé.
- [ ] Compléter le tableau §4 (nombre de scénarios, de relecteurs, de formulations ; licences et tailles).
- [ ] Mettre les liens et l'année à l'écran dans la vidéo (2 chiffres maximum).

---

## 8. Références

1. WHO Regional Office for Africa. *State of the health workforce in Africa 2026: Plan, train and retain.* Brazzaville, 2026. https://www.afro.who.int/publications/state-health-workforce-africa-2026-plan-train-and-retain
2. WHO AFRO. *Africa's health workforce expands but shortages, unemployment and migration intensify: WHO report.* 6 mai 2026. https://www.afro.who.int/news/africas-health-workforce-expands-shortages-unemployment-and-migration-intensify-who-report
3. Gatti R, Andrews K, Avitabile C, Conner R, Sharma J, Chang AY. *The Quality of Health and Education Systems Across Africa.* World Bank, 2021. DOI 10.1596/978-1-4648-1675-8
4. World Bank. *Service Delivery Indicators Health Survey 2013 — Nigeria.* https://microdata.worldbank.org/index.php/catalog/2559
5. Ekpin VI, Nwankwo HE, Akwaowo CD, Blencowe H. *Supervision and Support Interventions Targeted at CHWs in Sub-Saharan Africa* (préprint). 2024. DOI 10.21203/rs.3.rs-4670975/v1
6. GSMA. *The State of Mobile Internet Connectivity 2024* (communiqué du 23 oct. 2024) ; *2025* (communiqué du 9 sept. 2025) ; *2026* (sept. 2026). https://www.gsma.com/somic/
7. Ajisegiri WS, Abimbola S, Tesema AG, Odusanya OO, Peiris D, Joshi R. *« We just have to help »…* Front Public Health 2023;11:1038062. DOI 10.3389/fpubh.2023.1038062
8. Akinwumi AF, Esimai OA, Fajobi O, Idowu A, Esan OT, Ojo TO. *Knowledge of primary healthcare workers regarding the prevention and control of NCDs in Osun State, Nigeria.* Afr J Prim Health Care Fam Med 2021;13(1):a2873. DOI 10.4102/phcfm.v13i1.2873
9. Arogundade L, Akinwumi T, Molemodile S, et al. *Lessons from a training needs assessment… in Nigeria.* BMC Health Serv Res 2019;19:664. DOI 10.1186/s12913-019-4514-2
