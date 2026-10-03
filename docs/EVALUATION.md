# Évaluation du prototype hors ligne Yorùbá

## Portée

Cette évaluation mesure le comportement du matcher lexical Yorùbá sur un petit
jeu de cas écrit par l'équipe. Elle ne mesure ni la qualité d'un modèle
sémantique en Yorùbá, ni la reconnaissance vocale, ni la qualité clinique ou
linguistique des formulations.

## Protocole reproductible

À la racine du projet, exécuter :

```powershell
flutter test test/offline_yoruba_benchmark_test.dart
```

Le test charge `test/data/offline_yoruba_question_cases.json` et vérifie les
correspondances attendues, l'abstention sur les cas négatifs et la détection
d'une répétition. Une erreur sur n'importe quel cas fait échouer le test.

## Résultat observé

Dernière exécution du test :

| Mesure | Résultat |
|---|---:|
| Questions positives correspondant au point clé attendu | 12/12 |
| Cas négatifs où le système s'abstient sans valider de point clé | 5/5 |
| Répétition reconnue sans compter le point clé deux fois | 1/1 |
| Total de cas | 18 |

Ces nombres décrivent uniquement les cas présents dans le jeu actuel. Ils ne
sont pas une estimation de précision sur des conversations réelles et ne
doivent pas être présentés comme tels. Les cas ont été rédigés par l'équipe ;
ils ne constituent pas un corpus représentatif ni une validation par des
locuteurs Yorùbá.

## Limites et prochaines validations

- Faire relire et enrichir les formulations par des locuteurs Yorùbá, y compris
  des variantes dialectales et des formulations mixtes Yorùbá/anglais.
- Faire réviser le contenu médical par une personne qualifiée et le confronter
  aux protocoles applicables.
- Ajouter des cas issus de cette relecture, y compris les échecs observés,
  sans retirer les cas difficiles pour améliorer artificiellement le score.
- Construire séparément un jeu de comparaison anglais et mesurer le matcher
  lexical et Gecko sur les mêmes critères ; les résultats ci-dessus ne
  constituent pas cette comparaison.
- Tester le parcours complet sur téléphone et en mode avion.
- Le STT Yorùbá/anglais hors ligne n'est pas inclus dans ce benchmark.

