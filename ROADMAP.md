# Roadmap — Ilera

Ilera is a prototype for clinical interview training. It helps learners gather information, identify important signs, and choose a diagnosis in a scenario. It is not a diagnostic tool and it does not replace clinical supervision or local protocols.

This roadmap distinguishes the functions that have been implemented from the validations that remain to be done. See [README.md](README.md) for the current overview and project status.

## Current flow

1. The learner chooses an integrated scenario.
2. They interview the simulated patient via Gemini Live or in offline mode.
3. In offline mode, the patient returns prewritten replies; it does not generate new responses.
4. The learner selects a diagnosis from a multiple-choice list.
5. The application displays the points covered, the diagnosis result, the educational information, and the score, then attempts to save the session in Firebase.

## Implemented features

### Conversation and response selection

- Gemini Live provides the online conversation flow in real time.
- Offline mode uses a local scenario and prewritten replies.
- In English, the Gecko embeddings model helps match a question to an existing reply. Explicit keywords remain prioritized; keyword matching also serves as a fallback if Gecko is unavailable or uncertain.
- In Yoruba, response selection relies on keywords, with text normalization and abstention when the system cannot choose with sufficient confidence. Gecko is not used in Yoruba.
- The embeddings model selects a written reply; it does not generate the patient text.

### Speech recognition and audio

- Offline speech input on native platforms uses the multilingual Whisper `tiny` model in English and Yoruba. The model is downloaded on first use, its progress is displayed, and the installed file is reused.
- The recording used for transcription is temporary and then deleted. Whisper transcribes on-device. This feature is separate from Gemini Live, which sends the conversation audio to the online service.
- Yoruba patient responses have dedicated asset paths. The 26 expected MP3 files are present in the repository. Their playback, pronunciation, source, and distribution rights remain to be verified by people.
- A missing Yoruba recording does not silently trigger an English voice.

### Scenarios, evaluation, and persistence

- Three integrated offline scenarios are available in English and Yoruba.
- Diagnosis selection and the educational summary are implemented.
- Firebase authentication, profiles, the scenario catalog, session score recording, and progress views are present.
- The main README and the Yoruba audio inventory describe the current operation of Whisper and the offline embeddings model.

## Next step: validate the flow on target devices

The priority is now verification rather than adding new features:

1. Test a full offline session after downloading Gecko and Whisper, including after a cold restart and in airplane mode.
2. Measure Whisper transcription in English and Yoruba on target Android/iOS devices; verify permissions, downloads, reuse, errors, and performance.
3. Reassess Gecko matching on device. A previous run on a Samsung SM-A055F reported 44 successful cases out of 51; reproduce the measurement and study paraphrase and repetition failures.
4. Listen to the 26 Yoruba recordings and compare them to their scripts; confirm the source of the voices and authorization to distribute the files.
5. Have diagnoses, warning signs, and advice reviewed by healthcare professionals. Have the Yoruba translations and wording reviewed by native speakers.
6. Verify Firestore access rules, Gemini key restrictions, and the information provided about data before any distribution.

The test cases, acceptance criteria, and pending tasks are detailed in [README.md](README.md). The small existing benchmark results are development checks, not a representative accuracy measurement or proof of clinical effectiveness.

## Later evolutions

To be considered after device validations and human review:

- Expand the evaluation with English and Yoruba formulations gathered from users, separating speech recognition and response selection measures.
- Improve the debrief and add a flow to retry a case if trials with learners justify it.
- Version and validate remotely managed scenario content.
- Study trainer tools or other languages/scenarios according to validated needs.

## Clinical and linguistic validation status

The clinical scenarios and the embedded Yoruba content are illustrative and must be reviewed before use in training. Do not present the cases, translations, recordings, or model scores as validated by professionals. Keep the draft warning in the application until the required validations have been performed and recorded.
