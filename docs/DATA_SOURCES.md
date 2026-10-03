# Sources et données utilisées

Ce document distingue les ressources réellement utilisées du prototype des
sources encore à sélectionner pour étayer le besoin et le contenu clinique.

| Nom | Source | Licence / accès | Taille | Usage dans Ilera | Limites |
|---|---|---|---:|---|---|
| Gecko-110m-en, variante 256 tokens quantifiée | [Dépôt LiteRT Community sur Hugging Face](https://huggingface.co/litert-community/Gecko-110m-en), fichiers `Gecko_256_quant.tflite` et `sentencepiece.model` | Le commentaire source du projet indique Apache-2.0 ; vérifier la notice de licence du dépôt avant redistribution | Le dépôt annonce 114 Mo pour le modèle ; le tokenizer est un fichier distinct | Embeddings sur l'appareil pour le parcours hors ligne anglais | Modèle anglais, non bilingue ; aucune performance Yorùbá n'est revendiquée. Les mesures publiées dans la fiche modèle sont celles d'un Samsung S23 Ultra et ne représentent pas les appareils du projet. |
| Cas de benchmark Yorùbá écrits par l'équipe | `test/data/offline_yoruba_question_cases.json` | Écrits par l'équipe du projet ; pas de corpus tiers importé | 18 cas | Tests du matcher lexical : questions positives, négatives, répétition et abstention | Petit échantillon non représentatif, à relire par des personnes Yorùbá ; il ne sert pas à entraîner un modèle. |
| Lexique, formulations et réponses du scénario Yorùbá | `lib/services/offline/offline_scenarios.dart` | Contenu rédigé par l'équipe du projet | Un scénario de fièvre infantile | Matching lexical déterministe et sélection de réponses préécrites hors ligne | Formulations non validées linguistiquement ; contenu clinique illustratif, non validé médicalement. |
| Problème de santé et besoin d'entraînement | À sélectionner à partir des références candidates du brief (OMS, DHS/SPA, SDI ou autres sources adaptées au pays) | À vérifier pour chaque source | À documenter | Étayer le problème, le pays et l'année dans la présentation | Aucune statistique ou référence locale n'est encore attribuée ici ; ne pas présenter de chiffre sans source vérifiée. |
| Recommandations cliniques du scénario | Protocole clinique applicable à sélectionner et citer | À vérifier | Sans objet | Réviser les éléments médicaux du scénario | Le scénario actuel est illustratif et ne constitue pas un protocole de prise en charge. |

Le prototype n'utilise pas de corpus Yorùbá externe pour entraîner le matcher :
celui-ci compare localement les textes à un lexique et à des formulations
écrites à la main. La suppression de tons et de diacritiques sert uniquement à
la normalisation du texte pour le matching ; elle ne valide pas la qualité
linguistique.

## Références encore nécessaires avant soumission

- Une source vérifiable pour le besoin, avec indicateur, pays et année.
- Une source clinique datée et applicable au scénario, avec validation par une
  personne compétente.
- Une relecture des formulations Yorùbá par des locuteurs, en documentant la
  portée et les limites de cette relecture.
