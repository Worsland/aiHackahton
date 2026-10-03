# Yoruba recordings

The app looks for recordings in a language-specific folder so it never plays
an English patient clip during a Yorùbá session:

```text
assets/audio/offline/yo/<patient-look>/<reply-id>.mp3
```

Patient looks used by the built-in scenarios are `woman_mature`, `woman`, and
`man`. Each clip's filename must match the `OfflineReply.audioId` used by the
scenario (`duree.mp3`, `fallback_0.mp3`, `repeat_0.mp3`, and so on).

No Yorùbá recordings are included yet. Until recordings are supplied and
reviewed, the patient answer remains visible as text; the app deliberately
does not play the corresponding English recording or substitute an English
system voice.
