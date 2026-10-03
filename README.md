# AI Healthcare Simulation App

A Flutter application for practicing clinical interviews with simulated
patients. It is intended for training and practice; it is not a diagnostic
tool and does not replace clinical supervision or local medical protocols.

## Features

- Built-in fever, postpartum bleeding, and dehydration scenarios.
- Online conversations with a patient powered by Gemini Live.
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
| `SharedPreferences` | Local cache of synchronized scenarios and score summaries. |

The complete interview transcript is not saved in a session record. In Live
mode, microphone audio is sent to Gemini for the conversation. Offline Whisper
transcription is performed on-device; its temporary recording is deleted
after transcription. Profile and score data can still synchronize with
Firebase when connectivity is available.

Anonymous authentication lets a user start without creating a password.
After connecting, the anonymous account can be linked to an email account.
Signing in to a different account switches the active account; anonymous
progress is not automatically merged into an existing account.

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

### Configure Gemini

The current development setup reads `geminiApiKey` from `lib/main.dart`.
Replace the placeholder with a key from
[Google AI Studio](https://aistudio.google.com/apikey) to test Gemini
features.

The `.env` file is not loaded by the current application code, even though it
is listed as an asset. Do not put production secrets in an asset or in a
distributed client: bundled values can be extracted. A production deployment
should proxy Gemini requests through a backend and restrict the key.

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

- Offline dialogue is limited to scenarios with a local dialogue definition;
  it is not an open-ended generative patient.
- Whisper speech input requires a native target, microphone permission, and a
  one-time model download. The multilingual `tiny` model's recognition
  quality, especially for Yorùbá and noisy environments, should be evaluated
  with speakers on target devices.
- Gecko semantic matching has separate download and native-runtime
  requirements. Keyword matching is the fallback when semantic matching is
  unavailable.
- Some Yorùbá prerecorded audio files may still need to be recorded and added;
  consult the inventory for the required filenames and scripts.
- Firestore scenarios require a compatible offline dialogue definition before
  they can be used in the offline conversation mode.
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
   consumption on target devices.
5. Keep the offline scenario and keyword fallback usable on devices where
   optional native models are unavailable.

## Project documentation

- [Project goals](ProjectGOAL.md)
- [Roadmap and product decisions](ROADMAP.md)
- [Design notes](Design.md)
- [Flutter dependencies and assets](pubspec.yaml)
