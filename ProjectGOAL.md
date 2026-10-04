# ProjectGOAL — Ilera: training simulator for community health workers

> **Status:** modification plan for the hackathon weekend (**3–4 October 2026**).
> Track: *Small AI for Development* (Hack-Nation × World Bank Youth Summit), **Annex A — Health**.
> This document replaces the previous version of `ProjectGOAL.md`. Items marked **[TO VERIFY]** must not be asserted in the video or README before verification.

---

## 1. Objective

**Application name: Ilera.** *Ìlera* means “health” in Yoruba **[TO CONFIRM with the native reviewer, especially the writing with diacritics]**. The name directly illustrates the brief's question: *what does localizing AI development mean?*

Enable a frontline health worker to **practice conducting a clinical interview** (looking for warning signs, referral) with a virtual patient, **on their phone, offline, in a local language: Yoruba**, and receive reproducible pedagogical feedback.

The tool is **supervised training**. It does not diagnose real patients and does not replace a trainer or local protocols.

### Problem statement (format required by the brief, §08)

> With this tool, **a community health worker** will **practice identifying warning signs (child fever, postpartum haemorrhage, dehydration)** **before their first real consultation / between training sessions** when they would otherwise **not / late / without feedback**; we know this thanks to **[TO COMPLETE: indicator, source, country, year]**.

Candidate sources for evidence (brief §7.2 and Annex A): Service Delivery Indicators (World Bank), WHO Global Health Observatory (health workforce density), DHS / Service Provision Assessments. Choose **one country (Nigeria, if we stay with Yoruba)** and cite the year.

---

## 2. Link with Noor and the Health challenge

The challenge (Annex A) asks to improve *“a significant share of Noor’s access to primary care, or a frontline worker’s ability to serve her”*.

Our link, to be made **explicit** in the README and the video:

- Noor consults in an overloaded clinic, where carers are **not always up to date on the latest recommendations** and do not have time per patient.
- Our tool acts on **the worker’s ability to serve her**: repeated training, offline, without a trainer available, on high-risk situations (child fever, postpartum haemorrhage, dehydration).
- The “development” criterion (20%) asks whether the result matters to the person targeted: we show the path **training → better recognition of warning signs → care received by Noor**, **without claiming to have measured it**.

---

## 3. Decisions made

| Topic | Decision |
|---|---|
| Local language | **Yoruba** (Nigeria, Benin, Togo). Named in the README, the video, and the app. |
| Main demo flow | **Offline** (the core must work without network, rule 06). |
| Gemini Live | **Bonus connected mode** (voice), not the main flow. |
| Claude | **Online text understanding engine** for Yoruba (see §7), plus development help (see §7.5). |
| Free generation of clinical responses | **Disabled by default** (hallucination risk). Responses come from a fixed list reviewed by a native speaker. |
| Scoring | Remains **deterministic** (60% coverage, 40% diagnosis). No LLM grades. |

---

## 4. Changes to make (prioritized)

### P0 — required to comply with the brief

| # | Change | Files involved |
|---|---|---|
| 1 | Add a **language selector** (English / Yorùbá) and pass the language to the dialogue engine and interface. | `lib/screens/simulation_screen.dart`, new `lib/services/lang/app_language.dart` |
| 2 | **Yoruba content for at least 1 scenario**: patient responses, key points, example formulations, interface instructions. | `lib/services/offline/offline_scenarios.dart` (or dedicated JSON files by language) |
| 3 | **Offline Yoruba lexical matching** with diacritic normalization (§6.2). Gecko-110m-en remains used **only for English**. | `lib/services/offline/offline_patient_brain.dart`, new `lib/services/lang/yoruba_normalizer.dart` |
| 4 | **Visible fail-safe**: below the confidence threshold, the patient does not guess; the app displays a message such as “not sure — rephrase or ask a trainer”. A Yoruba message reviewed by a native speaker. | `offline_patient_brain.dart`, `simulation_screen.dart` |
| 5 | **Native review** of Yoruba clinical texts (see §6.3). Without review, display them as **“draft not verified”**. | content + `docs/DATA_SOURCES.md` |
| 6 | **Mini-benchmark** (§9): keywords vs semantic, English vs Yoruba, with errors included. | new `docs/EVALUATION.md`, `test/` |
| 7 | **Data sources and limits file** (§8). | new `docs/DATA_SOURCES.md` |
| 8 | **2–5 minute video** (§12). Without it, there is no shortlist. | outside the repo |

### P1 — strongly recommended

| # | Change | Files involved |
|---|---|---|
| 9 | **Claude integration** in online mode (§7). | new `lib/services/claude/claude_patient_service.dart` + small backend proxy |
| 10 | **Verify the Gemini Live model** and Yoruba language (§5). | `lib/services/live/gemini_live_service.dart` |
| 11 | **Move the Gemini key out of the client** (ephemeral tokens, §11). | `lib/main.dart`, backend |
| 12 | **Explicit consent** before any audio or text is sent to an online service. | `simulation_screen.dart`, new consent screen |
| 13 | **Pre-recorded Yoruba audio** by a native speaker, for at least one scenario. | `assets/audio/offline/yo/` |
| 14 | **Resumable model download**, with size shown; document a side-load option. | embeddings plugin management |
| 15 | Update the **README**: language, modes, limits, sources. | `README.md` |
| 16 | **Rename the app to “Ilera”** (display name only, see note below). | `README.md`, `lib/main.dart` (title), `android/app/src/main/AndroidManifest.xml` (`android:label`), `ios/Runner/Info.plist` (`CFBundleDisplayName`), `pubspec.yaml` (description) |

> **Renaming note:** do not change **either the package identifier** (`applicationId`, bundle id), **nor the Dart package name**, **nor the Firebase project** (`aihackaton-5120f`) this weekend. That would break `google-services.json` and `firebase_options.dart` for no gain. Only the **display name** changes.

### P2 — if time allows

- Second Yoruba scenario.
- Yoruba offline voice via embedded TTS **only if** quality is validated by a native speaker; otherwise remain on pre-recorded audio.
- Offline Yoruba speech recognition: **do not promise it**. List it in the limits.

---

## 5. Gemini Live and Yoruba

- The Gemini Live API documentation (page “Capabilities”, updated on 18 September 2026) lists **Yoruba (`yo`)** among the 99 supported languages. **[TO VERIFY in the current docs before the video.]**
- **“Supported” does not mean “good”**: the quality of understanding, pronunciation, and tone in Yoruba must be **tested with a native speaker** on our scenarios, then documented (successes **and** failures).
- Native audio models **choose the language automatically** and do not accept an explicit language code. To force Yoruba, specify it in the **system prompt** (“Reply only in Yoruba”).
- The output transcription follows the language of the response; display it in the conversation thread and mark it as automatic.
- **Model**: the README states that the model is defined in `gemini_live_service.dart`. The current documentation recommends `gemini-3.8-live`; `gemini-live-2.5-flash-native-...

[Output truncated in the original source. Continue below for the remaining content.]

---

## 6. Yoruba: implementation plan

### 6.1 Offline engine

- **English**: unchanged (quantized Gecko 110M, keyword fallback).
- **Yoruba**: **lexical** matching by key point: keywords, variants, manually written paraphrases, medical terms often said in English.
- **Computer-only experience**: test a multilingual embeddings model covering Yoruba on the test set. Do not port it to the phone this weekend (size and conversion). Report the result in `docs/EVALUATION.md`.

### 6.2 Diacritic normalization

People often type without marks (ẹ, ọ, ṣ, tonal accents). Apply **on both sides** (input and lexicon): lowercase, Unicode decomposition (NFD), removal of combining marks (U+0300–U+036F, U+0323…), punctuation cleanup.

**Limit to document:** removing tones can merge distinct words; the matcher can therefore produce false matches.

### 6.3 Review and validation

- Draft possible with NLLB-200 or Claude, **labelled “not verified”**.
- Clinical and linguistic review by at least one native speaker (ideally a healthcare professional). Record the number of reviewers and their profile.
- Test formulations must be written **by humans**, not generated, at least in part (§9).

### 6.4 Voice

- Pre-recorded voice by a native speaker (fallback to existing TTS). One scenario is enough for the demo.
- Test Yoruba Android TTS: if it is absent or poor, say so in the limits.

### 6.5 What Yoruba data does not cover (to be written in `DATA_SOURCES.md`)

- Dialects (Ọ̀yọ́, Ìjẹ̀bú, etc.) and spelling variants.
- Yoruba / English / pidgin alternation.
- Few reviewers; formulations written by the team rather than collected from healthcare workers.
- No independent clinical validation.

---

## 7. Claude integration (online mode)

### 7.1 What Claude does, and does not do

| Yes | No |
|---|---|
| Understand a question **written in Yoruba** and choose, from a **closed list**, the key point covered. | Freely generate clinical responses (disabled by default). |
| Return a confidence level and an “human needed” indicator. | Grade the interview or validate a diagnosis. |
| Help with development (§7.5). | Handle voice: the Claude API does not provide audio input/output. For online voice, we keep Gemini Live. |

### 7.2 Principle: “understanding, not generation”

1. The agent types their question in Yoruba.
2. The app sends to Claude: the question, the scenario `id`, and the **list of key points** (id + short description). No user identifiers.
3. Claude responds in **strict JSON**:
   ```json
   { "key_point_ids": ["kp_03"], "confidence": 0.82, "needs_human": false }
   ```
4. The app displays the **prewritten and reviewed reply** corresponding to `kp_03` (pre-recorded audio if available).
5. If `confidence` is below the threshold, or if no key point matches: fail-safe message (“not sure — rephrase or ask a trainer”). **No guessing.**
6. The score is calculated by the existing code from the confirmed `id`s.

Advantage: the displayed text is always **verifiable in advance** (“fixed list of answers” from the brief glossary), which limits hallucinations.

### 7.3 Architecture

```
App Flutter ──► Backend proxy (Claude key on the server) ──► Claude API
      │
      └─ offline / failure / timeout ──► local Yoruba lexical matcher ──► fail-safe
```

- **The Claude key never goes into the application** (unlike the current Gemini key). The proxy enforces: rate limiting per installation, maximum question size, logging disabled by default.
- Possible proxy: Cloud Run, Cloudflare Worker, or serverless function **[choose what is already accessible]**.
- New service: `lib/services/claude/claude_patient_service.dart`, with a short timeout and **automatic fallback** to the local matcher.
- **Model**: start with `claude-sonnet-5-5` (expected better quality on a low-resource language); test `claude-haiku-4-5-20251001` for cost and latency. **[Confirm model names and pricing in the console before integrating.]**
- “Claude credits” must be **API credits (Claude Platform)**; the chat app subscription does not provide an API key. **[TO VERIFY on the account.]**

### 7.4 Prompt constraints (summary)

- Role: classifier for questions in a training simulator, not a clinician.
- Input: question in Yoruba (with or without diacritics, possibly mixed with English).
- Output: JSON only, ids drawn **exclusively** from the provided list.
- If the question is ambiguous, off-topic, or dangerous: `key_point_ids: []`, `needs_human: true`.
- Never add medical content.

### 7.5 Help with development using Claude (outside the user flow)

To use this weekend to save time, **always labelled and reviewed**:

- Generate **paraphrase candidates** for the Yoruba lexicon (to be reviewed).
- Do a **back-translation** Yoruba → French/English to detect mistranslations before native review.
- Produce a **synthetic test set** (labelled as such), distinct from the set written by humans.
- Compare Gemini Live and Claude outputs on the same questions.

> **Do not state** that Claude understands Yoruba better than Gemini without measuring it (§9).

### 7.6 Free-generation mode (experimental, disabled by default)

If enabled: patient responses generated **only from the scenario sheet**; if a fact is not in the sheet, the patient says they do not know; banner “generated response, not verified”; not used in the main demo.

---

## 8. Data and sources

To create: `docs/DATA_SOURCES.md`, with **name, source, license, size, usage, what the data does not cover**.

### 8.1 Data that shows the problem (brief §7.2, type 1)

| Need | Candidate source |
|---|---|
| Absenteeism and health worker equipment | Service Delivery Indicators (World Bank) |
| Health workforce density | WHO Global Health Observatory |
| Care-seeking behaviour, availability on arrival | DHS / Service Provision Assessments |
| Phone / smartphone ownership | GSMA Mobile Gender Gap Report |

Cite **country, year, source**. Indicate whether a figure comes from modelling.

### 8.2 Data used to build (type 2)

| Use | Candidate source | Note |
|---|---|---|
| Clinical content of scenarios | Corresponding WHO protocols (to cite precisely) | **[TO VERIFY]** version and chapter |
| English embeddings | Gecko-110m-en (Apache-2.0, ~114–115 MB) | already documented |
| Yoruba language (voice / text) | Common Voice (yo), FLEURS (yo_ng), FLORES-200 / NLLB-200 (yor_Latn), MMS, Masakhane resources | **[TO VERIFY]** availability, license, and size of each resource |
| Test set | Formulations written by humans (team + native reviewers) | size and author profile to be noted |
| Synthetic set | Generated by an LLM | **label as “synthetic”** |

---

## 9. Evaluation (for the “proof that it works” and “AI value” criteria)

### Protocol

- **Test set**: 60 to 100 formulations per scenario, with the correct label (key point) or “no relevant response”. At least some written by a native speaker. **Calibration set and test set separate.**
- **Models compared**:
  1. Keywords (English)
  2. Gecko semantic (English)
  3. Normalized Yoruba lexical matching
  4. Claude online (Yoruba)
  5. *(optional)* multilingual embeddings on computer
- **Metrics**: correct top-1 response, false matches, correct abstention rate (“not sure”), latency, model size.

### Table to publish in `docs/EVALUATION.md` and in the video

| Model | Language | Top-1 | False matches | Correct abstentions | Latency | Size |
|---|---|---|---|---|---|---|
| … | … | … | … | … | … | … |

Include **the errors** and what we conclude from them. Honesty is valued by the brief.

### Ready-made answer for “and in a less well-supported language?”

Adding a language = a scenario translated and reviewed, a lexicon, a few recordings, and 50–100 test formulations. The main cost is **human review**, not retraining.

---

## 10. Safeguards and responsible AI (pass/fail criterion)

- **Human in the loop**: the tool trains; a person decides. It never acts in place of the user.
- **Closed list of responses** by default; any generated content is flagged.
- **Fail-safe**: “not sure — rephrase or ask a trainer” rather than a guessed answer.
- **Content not clinically validated**: permanent banner in the app and in the README.
- **Bias**: tests only with formulations from the team; write this down. No generalization to other dialects or languages.
- **No proof of improvements in care**: never present the score as such.
- **Privacy**: offline processing by default; explicit consent before any online sending; specify where data resides, who can read it, and what happens if the phone is lost or shared (requirement from Annex A).

---

## 11. Security

- **Gemini key**: remove the constant from the client. The Gemini docs state that, for a client → server connection, one should use **ephemeral tokens**. Emit them from the same backend as the Claude proxy.
- **Claude key**: server-side only.
- **Firestore**: verify that the rules limit access to `users/{uid}` and its sessions.
- Do not put any secret in the `.env` asset (already declared in `pubspec.yaml`).
- Do not save any transcription or audio without consent.

---

## 12. Deliverables (brief §08)

- [ ] **Prototype**: code or link, with instructions to run it.
- [ ] **2–5 minute video** containing:
  - [ ] **Problem statement** in one sentence (format of §1) with the cited proof.
  - [ ] **Role of AI** and why an SMS, spreadsheet, or search would not do the same job; safeguards.
  - [ ] **End-to-end demo**: scenario choice → Yoruba offline interview → diagnosis → recap.
  - [ ] **Place of the tool in the user’s day** and technical stack.
  - [ ] **“Your vision of AI localization”**.
- [ ] README, `DATA_SOURCES.md`, `EVALUATION.md` up to date.
- [ ] Consistent **Ilera** name everywhere: home screen, README, video title, repository, submission form.

### Why AI and not a simple tool

A multiple-choice questionnaire does not allow one to **ask their own questions in their own words**. AI is used to match a free-form question (with mistakes, without diacritics, mixed with English) to a key point. The benchmark (§9) must **show what semantic or Claude adds in practice compared with keywords**; if it adds nothing in Yoruba, say so and explain why.

---

## 13. Suggested timeline

| Time | To do |
|---|---|
| **Saturday 3 Oct.** | Language selector, one Yoruba scenario, lexical matching + normalization, visible fail-safe, search for a native reviewer, test Gemini Live in Yoruba. |
| **Saturday evening** | Proxy + Claude service, consent, first benchmark numbers. |
| **Sunday 4 Oct. (morning)** | Native review, Yoruba audio, final evaluation table, `DATA_SOURCES.md`. |
| **Sunday 4 Oct. (afternoon)** | Video recording, README, submission **before the end of the weekend**. |

---

## 14. Out of scope this weekend

- Offline Yoruba speech recognition.
- Multilingual embeddings model on phone.
- Scenario administration interface.
- Independent clinical validation and impact study on care.
- Other languages.
