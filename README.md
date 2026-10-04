# AI Healthcare Simulation App

## Context and problem

Noor's story captures a frontline-care challenge: the clinic is nearby, but
it is overcrowded; health workers face heavy caseloads, limited time with each
patient, demanding records, and guidance that may not always be current. In
remote catchments, clinician shortages, distance to care, limited on-site
diagnostics, and low digital literacy can add further barriers.

Community health workers are often the first point of contact for people like
Noor. Supporting them means more than providing information: they need
opportunities to refresh their knowledge, practise the expected professional
attitude, ask respectful and relevant questions, recognize warning signs, and
know when to refer a patient or seek supervision.

Ilera is designed to support this ongoing learning. It offers repeatable,
scenario-based practice in which learners interview a simulated patient,
identify important signs, choose a diagnosis, and receive a score and
learning summary. The scenarios can be reviewed and updated as training
requirements and local guidance evolve. Offline conversation and on-device
speech recognition are designed to make practice available even when
connectivity is limited. Ilera aims to strengthen the preparation of
frontline health workers; it does not diagnose Noor or replace official
guidance, supervision, or care.

The WHO African Region's 2026 health workforce report summarizes studies in
which providers made a correct diagnosis in about 62% of cases and provided
guideline-concordant treatment in about 40%. It also estimates that the
Region has 46% of the health workers it needs and projects a shortfall of
5.85 million by 2030. Separately, the [GSMA State of Mobile Internet
Connectivity 2024 report](https://www.gsma.com/newsroom/press-release/new-gsma-report-shows-mobile-internet-connectivity-continues-to-grow-globally-but-barriers-for-3-45-billion-unconnected-people-remain/)
reports that at the end of 2023, 27% of the population in Sub-Saharan Africa
used mobile internet, alongside a 60% usage gap.

These regional figures describe providers and populations across diverse
settings; they are not specific to community health workers, Yoruba-speaking
learners, or Noor's location. They motivate the challenge, but do not by
themselves demonstrate Ilera's impact. Sources, dates, definitions, and
limitations are documented in [`data.md`](data.md).

## About Ilera

A Flutter learning application for community and frontline health workers.
Through simulated patient interviews, it supports continued practice in
clinical reasoning, communication, recognizing warning signs, and selecting
an appropriate next step. Reviewed scenario content can be refreshed as
requirements change. Ilera is a training aid, not a diagnostic tool or a
replacement for official guidance, clinical supervision, or local protocols.

## Features

- Built-in fever, postpartum bleeding, and dehydration scenarios.
- Online conversations with a patient powered by Gemini Live through an
  authenticated server-side proxy. The proxy keeps the provider key out of
  the app and enforces a shared three-minute quota.
- A structured offline conversation mode that follows a local dialogue tree
  and can match questions using on-device text embeddings, with a keyword
  fallback when the embedding runtime is unavailable.
- Offline microphone input on supported native platforms using a cached,
  multilingual Whisper `tiny` model. English and Yorùbá are supported for the
  built-in offline scenarios.
- Text input remains available as an alternative to speaking.
- Yorùbá prerecorded patient audio assets are organized by scenario and voice;
  see [the Yorùbá audio inventory](assets/audio/offline/yo/README.md).
- Firebase authentication, scenario synchronization, and session-score
  persistence.

## Device and download requirements

Offline practice needs internet **once** to download the models. The sizes
below have not all been measured yet.

| Component | Needed for | Size | Notes |
|---|---|---|---|
| App package | Everything | _To measure_ | Android debug build size is not representative. |
| Whisper `tiny` (multilingual) | Offline speech input | _To measure_ | Downloaded on first microphone use; progress is shown. |
| Gecko 110M quantized | Semantic matching (English only) | About 115 MB (_to confirm on device_) | Downloaded separately; keyword matching is used if unavailable. |
| Yorùbá prerecorded audio | Spoken patient replies | _To measure_ | Some files may still be missing; see the audio inventory. |

Side-loading models and resuming interrupted downloads are not yet documented
here. On a slow or metered connection, the first download may be costly, so
this is a limit for the settings described above.

## Conversation modes

| Mode | Patient responses and selection | Speech input | Network use |
|---|---|---|---|
| Live | Gemini Live | Audio is streamed to Gemini; text input is also available. | Internet required. |
| Offline | The patient uses prewritten, scenario-specific replies. For English, the Gecko embedding model helps select the matching reply after keyword matching; if it is unavailable or uncertain, keyword matching is used. For Yorùbá, selection uses keyword matching. The embedding model selects a reply; it does not generate one. | Native builds use Whisper on-device after its model is installed. Text input is also available. | The first Whisper model download requires internet; the separate Gecko embedding model also needs to be downloaded before semantic matching can be used. Speech recognition and patient-response selection then run locally. Firebase may still synchronize profile or session data when connectivity is available. |

Offline conversation quality depends on the scenario's authored replies and
question-matching data. The local patient does not invent new responses. In
English, semantic matching is applied only when the embedding model and its
native runtime are available; otherwise, and for Yorùbá, the app uses keyword
matching.

### When the app is not sure

The offline patient says only what the scenario authors wrote. If a question
does not match any authored reply, the app should say so instead of guessing,
and invite the learner to rephrase or ask a supervisor.

> **TODO before submission:** confirm this against `OfflinePatientBrain` and
> the simulation screen, then replace this note with the exact on-screen
> message in English and Yorùbá (reviewed by a native speaker). If the code
> currently returns a default in-character reply instead, either change the
> behavior or describe it here accurately.

In Live mode, replies are generated by Gemini and can be wrong or invented.
Treat Live conversations as practice, not as a source of clinical facts.

### Offline Whisper speech recognition

On a native build, the first offline microphone use downloads the multilingual
Whisper `tiny` model. The app shows download progress beneath the microphone.
The completed model is stored in the app's support directory and reused on
later uses; it is downloaded again only if the app data/model file is removed
or the download did not complete.

Whisper records mono, 16 kHz WAV audio temporarily, transcribes it locally
using the selected language (`en` or `yo`), and removes the temporary
recording afterward. Recording ends after silence or after a 20-second limit.
The app needs microphone permission. The initial model download requires an
internet connection; transcription does not send the recorded speech to
Gemini.

The Whisper native integration is not available on web. Web speech handling
uses the existing browser-specific path and has different language and
offline capabilities.

### Offline embedding model

The Gecko 110M quantized embedding model is downloaded separately from the
Whisper speech-recognition model. In English offline conversations, it helps
match the agent's question to a prewritten patient response; it does not
generate the response. Yorùbá response selection currently uses keyword
matching instead. Gecko is distributed under the
Apache-2.0 license from
[litert-community/Gecko-110m-en](https://huggingface.co/litert-community/Gecko-110m-en).
The download requires a connection and is retained in plugin-managed local
storage. If it cannot be downloaded or initialized, the app falls back to
keyword matching. This embedding model is separate from Whisper and is not
used to transcribe speech.

## Typical user journey

1. Choose a scenario and a conversation mode.
2. In Live mode, connect to Gemini and conduct the interview by voice or text.
3. In Offline mode, use the local scenario dialogue; on a native device, tap
   the microphone to speak or type a question.
4. Review the feedback and score at the end of the session.
5. Sign in anonymously or link an email account to retain progress across
   sessions.

## Project structure

```text
lib/
  main.dart
  models/                 Scenario, patient, and session models
  screens/                Authentication, home, scenario, and simulation UI
  services/
    offline/              Local dialogue, matching, voice, and Whisper STT
    lang/                 App-language and speech-locale helpers
    ...                   Gemini, Firebase, scenario, profile, and score services
  widgets/                Shared UI components
assets/
  patients/               Patient avatar artwork
  audio/offline/          Optional prerecorded patient speech
```

`SimulationScreen` coordinates the interview and delegates work to services.
The online Gemini conversation, offline scenario engine, speech recognition,
and Firebase persistence have separate implementations.

### Main services

- `GeminiService` generates scenario-based text and session feedback.
- `GeminiLiveService` manages the online, real-time audio conversation.
- `VoiceService` selects speech handling for the current platform, language,
  and conversation mode. Offline native speech recognition is implemented by
  `offline_whisper_io.dart`; the browser uses its separate adapter.
- `OfflinePatientBrain` selects authored local patient responses. It uses
  semantic matching when available and keyword matching as a fallback.
- `ScenarioCatalog` combines built-in scenarios with Firestore scenarios and
  caches synchronized scenarios locally.
- `ScenarioScoreBoard` observes session history and calculates scenario
  statistics.
- `SessionRepository` saves session scores under
  `users/{uid}/sessions`.
- `UserProfileService` reads and writes the user's profile under
  `users/{uid}`.

## Data and synchronization

The repository's Firebase configuration currently targets the
`aihackaton-5120f` project. The app uses:

| Location | Data |
|---|---|
| Firestore `scenarios` collection | Downloadable scenario definitions, prompts, difficulty, key points, responses, and clinical notes. |
| Firestore `users/{uid}` document | User profile, including name and an optional base64-encoded photo. |
| Firestore `users/{uid}/sessions` subcollection | Scenario, mode, score, diagnosis outcome, key points covered, and date. |
| Firestore `iaUsage/global` document | Server-maintained shared Gemini usage and remaining-time budget. |
| Firestore `iaUsageLocks/global` document | Private server-only lock for serializing Gemini sessions. |
| `SharedPreferences` | Local cache of synchronized scenarios and score summaries. |

The complete interview transcript is not saved in a session record. In Live
mode, microphone audio is sent through the Gemini proxy for the conversation.
Offline Whisper transcription is performed on-device; its temporary recording is deleted
after transcription. Profile and score data can still synchronize with
Firebase when connectivity is available.

Anonymous authentication lets a user start without creating a password.
After connecting, the anonymous account can be linked to an email account.
Signing in to a different account switches the active account; anonymous
progress is not automatically merged into an existing account.

### Who can read the data, and lost or shared phones

- **Cloud data.** Access to Firestore data is governed by the project's
  security rules.
  > **TODO before submission:** confirm that the rules limit `users/{uid}` and
  > its sessions to the signed-in owner, and document the result here.
- **On the device.** Locally cached scenarios and score summaries are kept in
  `SharedPreferences`. Anyone who can open the app on an unlocked phone can see
  the signed-in user's progress and profile (name and optional photo). Use a
  screen lock on shared phones.
- **No transcripts, no stored audio.** Interview transcripts are not saved,
  and the temporary offline recording is deleted after transcription. In Live
  mode, audio is sent to Gemini, so avoid real patient information.
- **No real patient data.** Ilera is designed for simulated patients. Do not
  enter information about real people.

Scenarios are currently managed through the Firestore `scenarios` collection;
the app does not include an administration screen. The expected data shape is
defined by `ScenarioBundle` in `lib/models/scenario_bundle.dart`.

## Setup

### Requirements

- Flutter and Dart compatible with the SDK constraint in `pubspec.yaml`
  (`^3.10.8`).
- Android Studio/Android SDK, Xcode for iOS, or another configured Flutter
  target.
- A Gemini API key for online AI features.
- A Firebase project with Authentication and Cloud Firestore configured.
- Internet access for dependency resolution and first-time model downloads.

### Install dependencies

Run from the repository root:

```bash
flutter pub get
```

### Configure Gemini safely

Online text and Live audio use the authenticated Cloud Run proxy in
[`server/`](server/). The provider key belongs in Secret Manager, not in
Firestore, `.env`, a Flutter asset, source code, or a build define. The proxy
enforces a shared three-minute allowance in Firestore. See the
[Gemini proxy deployment guide](docs/gemini-proxy.md) for setup, rules, and
Firebase Hosting deployment.

### Configure Firebase

The repository includes `lib/firebase_options.dart`, `firebase.json`, and
`android/app/google-services.json` for its existing Firebase configuration.
To use a different Firebase project:

1. Create or select a Firebase project and enable Authentication and
   Cloud Firestore.
2. Register each target application with Firebase.
3. Regenerate the Flutter configuration (for example, with the FlutterFire
   CLI) and replace the platform configuration files with those for your
   project.
4. Review Firestore security rules before deploying.

## Run the app

```bash
flutter run
```

To build an Android debug APK:

```bash
flutter build apk --debug
```

The Whisper plugin may request a newer Android NDK than the one currently
selected by the project. If Gradle reports an NDK-version warning, install
the version named in the warning and configure the Android build to use it.

## Offline Yorùbá audio assets

The files under `assets/audio/offline/yo/` are prerecorded patient utterances
for the three built-in offline scenarios. The inventory README lists every
expected filename, location, voice, and corresponding Yorùbá text:
[Yorùbá audio inventory](assets/audio/offline/yo/README.md).

These prerecorded response assets are separate from Whisper speech
recognition. Whisper converts the user's microphone input to text; it does
not generate or synthesize the patient's voice.

## Current limitations

- **Not evaluated with real users.** Ilera has not been tested with health
  workers, and its effect on clinical skills or care has not been measured.
- **Scenario content is not clinically validated.** It needs review by local
  clinicians and Yorùbá speakers.
- **Yorùbá speech recognition is unevaluated.** Whisper `tiny`'s transcription
  quality for Yorùbá, especially in noisy environments, has not yet been
  tested with speakers on target devices. Text input and prerecorded audio do
  not depend on it.
- Offline dialogue is limited to scenarios with a local dialogue definition;
  it is not an open-ended generative patient.
- Whisper speech input requires a native target, microphone permission, and a
  one-time model download.
- Gecko semantic matching is English-only and has separate download and
  native-runtime requirements. Keyword matching is the fallback when semantic
  matching is unavailable, and it is the only method used for Yorùbá.
- Some Yorùbá prerecorded audio files may still need to be recorded and added;
  consult the inventory for the required filenames and scripts.
- Firestore scenarios require a compatible offline dialogue definition before
  they can be used in the offline conversation mode.
- Download sizes, memory use, latency, and battery consumption on target
  devices have not been measured (see the requirements table above).
- Live mode depends on Gemini's language support for Yorùbá, which has not
  been validated with native speakers.
- The application is a training aid, not a clinical decision-support or
  diagnostic system.

## Recommended next steps

1. Have local clinicians and Yorùbá speakers review the scenarios, prompts,
   translations, and audio scripts.
2. Record and validate the missing audio assets listed in the Yorùbá audio
   inventory.
3. Test Whisper's English and Yorùbá transcription quality on representative
   Android and iOS devices, including low-end devices and noisy settings.
4. Measure offline model download size, memory use, latency, and battery
   consumption on target devices, and fill in the requirements table.
5. Keep the offline scenario and keyword fallback usable on devices where
   optional native models are unavailable.
6. Compare keyword matching and Gecko matching on a held-out set of questions
   and report the results, including errors.

## Project documentation

- [Data sources and limitations](data.md)
- [Project goals](ProjectGOAL.md)
- [Roadmap and product decisions](ROADMAP.md)
- [Design notes](Design.md)
- [Flutter dependencies and assets](pubspec.yaml)