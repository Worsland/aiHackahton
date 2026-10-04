# Feuille de route — Ilera

Ilera est un prototype de formation à l'entretien clinique. Il aide les
apprenants à recueillir des informations, repérer les signes importants et
choisir un diagnostic dans un scénario. Ce n'est pas un outil de diagnostic
et il ne remplace ni l'encadrement clinique ni les protocoles locaux.

Cette feuille de route distingue les fonctions implémentées des validations
qui restent à faire. Voir [TODO.md](TODO.md) pour la liste d'actions détaillée.

## Parcours actuel

1. L'apprenant choisit un scénario intégré.
2. Il interroge le patient simulé via Gemini Live ou en mode hors ligne.
3. En mode hors ligne, le patient renvoie des répliques rédigées à l'avance ;
   il ne génère pas de nouvelles réponses.
4. L'apprenant sélectionne un diagnostic dans une liste à choix multiples.
5. L'application affiche les points abordés, le résultat du diagnostic, les
   informations pédagogiques et le score, puis tente d'enregistrer la session
   dans Firebase.

## Fonctionnalités implémentées

### Conversation et sélection des réponses

- Gemini Live fournit le parcours de conversation en ligne et en temps réel.
- Le mode hors ligne utilise un scénario local et des répliques préécrites.
- En anglais, le modèle d'embeddings Gecko aide à faire correspondre une
  question à une réplique existante. Les mots-clés explicites restent
  prioritaires ; le matching par mots-clés sert aussi de secours si Gecko est
  indisponible ou hésite.
- En yorùbá, la sélection des réponses repose sur les mots-clés, avec
  normalisation du texte et abstention lorsque le système ne peut pas choisir
  de façon suffisamment sûre. Gecko n'est pas utilisé en yorùbá.
- Le modèle d'embeddings sélectionne une réplique écrite ; il ne génère pas
  le texte du patient.

### Reconnaissance vocale et audio

- La saisie vocale hors ligne sur les plateformes natives utilise le modèle
  multilingue Whisper `tiny` en anglais et en yorùbá. Le modèle est téléchargé
  lors de la première utilisation, sa progression est affichée et le fichier
  installé est réutilisé.
- L'enregistrement utilisé pour la transcription est temporaire, puis
  supprimé. Whisper transcrit sur l'appareil. Cette fonction est distincte de
  Gemini Live, qui transmet l'audio de conversation au service en ligne.
- Les réponses patient yorùbá ont des chemins d'assets dédiés. Les 26 fichiers
  MP3 attendus sont présents dans le dépôt. Leur lecture, prononciation,
  provenance et droits de distribution restent à vérifier par des personnes.
- Un enregistrement yorùbá manquant ne déclenche pas silencieusement une voix
  anglaise.

### Scénarios, évaluation et persistance

- Trois scénarios hors ligne intégrés sont disponibles en anglais et en
  yorùbá.
- La sélection du diagnostic et le récapitulatif pédagogique sont implémentés.
- L'authentification Firebase, les profils, le catalogue de scénarios,
  l'enregistrement des scores de session et les vues de progression sont
  présents.
- Le README principal et l'inventaire des audios yorùbá décrivent le
  fonctionnement actuel de Whisper et du modèle d'embeddings hors ligne.

## Prochaine étape : valider le parcours sur les appareils cibles

La priorité est maintenant la vérification, plutôt que l'ajout de nouvelles
fonctionnalités :

1. Tester une session complète hors ligne après téléchargement de Gecko et
   Whisper, y compris après redémarrage à froid et en mode avion.
2. Mesurer la transcription Whisper en anglais et en yorùbá sur des appareils
   Android/iOS cibles ; vérifier les permissions, le téléchargement et sa
   réutilisation, les erreurs et les performances.
3. Réévaluer le matching Gecko sur appareil. Une exécution antérieure sur un
   Samsung SM-A055F rapportait 44 cas réussis sur 51 ; reproduire la mesure et
   étudier les échecs de paraphrase et de répétition.
4. Écouter les 26 enregistrements yorùbá et les comparer à leurs scripts ;
   confirmer la provenance des voix et l'autorisation de distribuer les
   fichiers.
5. Faire relire les diagnostics, signes d'alerte et conseils par des
   professionnels de santé. Faire relire les traductions et formulations
   yorùbá par des locuteurs de cette langue.
6. Vérifier les règles d'accès Firestore, les restrictions de la clé Gemini et
   les informations fournies sur les données avant toute distribution.

Les cas de test, critères d'acceptation et tâches en attente sont détaillés
dans [TODO.md](TODO.md). Les petits résultats de benchmark existants sont des
vérifications de développement, pas une mesure de précision représentative ni
une preuve d'efficacité clinique.

## Évolutions ultérieures

À envisager après les validations sur appareils et les relectures humaines :

- Étendre l'évaluation avec des formulations anglaises et yorùbá recueillies
  auprès d'utilisateurs, en séparant les mesures de reconnaissance vocale et
  de sélection de réponse.
- Améliorer le débrief et ajouter un parcours pour refaire un cas si les
  essais avec les apprenants le justifient.
- Versionner et valider le contenu des scénarios gérés à distance.
- Étudier des outils formateur ou d'autres langues/scénarios selon les besoins
  validés.

## Statut de validation clinique et linguistique

Les scénarios cliniques et le contenu yorùbá intégrés sont illustratifs et
doivent être relus avant usage en formation. Ne pas présenter les cas, les
traductions, les enregistrements ou les scores de modèle comme validés par des
professionnels. Conserver l'avertissement de brouillon dans l'application
jusqu'à ce que les validations nécessaires aient été effectuées et consignées.
