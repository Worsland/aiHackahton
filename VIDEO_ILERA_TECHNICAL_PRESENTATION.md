# Ilera — Technical Presentation Video

**Durée visée :** 60 secondes  
**Format :** narration en anglais avec des images de l’application et de son architecture  
**Texte parlé :** environ 130 mots

| Temps | Actions à l’écran | Paroles en anglais |
|---|---|---|
| 0:00–0:08 | Montre une courte scène d’un agent communautaire en consultation, puis le projet Flutter. | “Community health workers are often the first point of care, making ongoing practical training essential.” |
| 0:08–0:20 | Lance l’application, puis montre la conversation en ligne et le mode hors ligne. | “Ilera is built in Flutter. Online, Gemini Live supports conversation; offline, a local engine selects authored replies, making practice repeatable without generating clinical dialogue.” |
| 0:20–0:34 | Montre le micro, la progression du téléchargement, puis une question transcrite. | “On supported native platforms, Whisper Tiny records temporary audio and transcribes English or Yorùbá on-device. Its model downloads once, is reused locally, and the temporary recording is removed.” |
| 0:34–0:46 | Montre le matching d’une question, puis un schéma simple : mots-clés, Gecko, réponse préécrite. | “For English, keyword matches take priority, while Gecko embeddings can select a prepared reply for a paraphrased question. If semantic matching is unavailable or uncertain, the app falls back to keywords. Yorùbá currently uses keyword matching.” |
| 0:46–1:00 | Montre le diagnostic, le récapitulatif et une session Firebase, puis termine par l’avertissement. | “The learner then selects a diagnosis and receives a scored recap. Scenario content can be reviewed as local guidance evolves. Firebase stores accounts and session history. This training prototype supports learning; device performance, language quality, and clinical content still need validation.” |

## Conseils pour le tournage

- Fais bien apparaître la différence entre la transcription Whisper, le choix
  d’une réponse et Gemini Live : ce sont des traitements distincts.
- Gecko sélectionne une réplique existante ; il ne génère pas la réponse du
  patient.
- Tu peux montrer que les fichiers audio yorùbá sont présents dans le projet,
  mais ne les qualifie pas de validés professionnellement tant que cette
  vérification n’a pas été faite.
- Évite d’afficher des clés API, des identifiants ou des données Firebase
  privées.
