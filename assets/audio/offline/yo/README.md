# Yorùbá Audio Recordings

Place each patient response in the folder matching the patient's appearance.
The filename must use exactly the identifier shown below:

```text
assets/audio/offline/yo/<appearance>/<identifier>.mp3
```

Example: `assets/audio/offline/yo/woman_mature/duree.mp3`.

The 26 files below cover all responses for the three built-in Yorùbá
scenarios: key-point responses, fallback responses, and responses to repeated
questions. Record the text in the "Spoken text" column exactly as written.

## Child with a Fever — appearance `woman_mature`

| Identifier | File path | Spoken text |
|---|---|---|
| `duree` | `assets/audio/offline/yo/woman_mature/duree.mp3` | Ọjọ́ méjì ni, ibà náà kò tíì lọ. |
| `moustiquaire` | `assets/audio/offline/yo/woman_mature/moustiquaire.mp3` | Ó máa ń sùn lábẹ́ àwọ̀n ẹ̀fọn, ṣùgbọ́n ihò kan wà nínú rẹ̀. |
| `voyage` | `assets/audio/offline/yo/woman_mature/voyage.mp3` | A lọ bẹ ìyá ọkọ mi wò ní ìlú ní ọ̀sẹ̀ tó kọjá. |
| `autres_symptomes` | `assets/audio/offline/yo/woman_mature/autres_symptomes.mp3` | Ó rẹ̀ ẹ́ gan-an, ó sì ti ń sùn ju bó ṣe máa ń sùn lọ. |
| `hydratation` | `assets/audio/offline/yo/woman_mature/hydratation.mp3` | Ó ń mu omi díẹ̀ sí i láàárín ọjọ́, ṣùgbọ́n ó ṣì ń mu. |
| `fallback_0` | `assets/audio/offline/yo/woman_mature/fallback_0.mp3` | Ẹ jọ̀ọ́, mi ò lóye ìbéèrè náà dáadáa. |
| `fallback_1` | `assets/audio/offline/yo/woman_mature/fallback_1.mp3` | Mi ò mọ̀ dájú; ẹ jọ̀ọ́ tún béèrè. |
| `repeat_0` | `assets/audio/offline/yo/woman_mature/repeat_0.mp3` | Mo ti sọ fún yín tẹ́lẹ̀. |
| `repeat_1` | `assets/audio/offline/yo/woman_mature/repeat_1.mp3` | Bẹ́ẹ̀ ni, gẹ́gẹ́ bí mo ṣe sọ tẹ́lẹ̀. |

## Postpartum Bleeding — appearance `woman`

| Identifier | File path | Spoken text |
|---|---|---|
| `delai_accouchement` | `assets/audio/offline/yo/woman/delai_accouchement.mp3` | Mo bí ọmọ ní ọjọ́ márùn-ún sẹ́yìn nílé. |
| `quantite` | `assets/audio/offline/yo/woman/quantite.mp3` | Ẹ̀jẹ̀ náà ti pọ̀ sí i; mo ń yí aṣọ padà lọ́pọ̀ ìgbà. |
| `fievre` | `assets/audio/offline/yo/woman/fievre.mp3` | Mo ti ń gbóná díẹ̀ láti àná. |
| `odeur` | `assets/audio/offline/yo/woman/odeur.mp3` | Bẹ́ẹ̀ ni, ó dà bí ẹni pé ó ń rùn díẹ̀ láti òní. |
| `douleur` | `assets/audio/offline/yo/woman/douleur.mp3` | Inú ìsàlẹ̀ ikùn mi ń dùn bí ìfúnpọ̀. |
| `fallback_0` | `assets/audio/offline/yo/woman/fallback_0.mp3` | Ẹ jọ̀ọ́, ó ṣòro fún mi láti sọ̀rọ̀ nípa rẹ̀. |
| `fallback_1` | `assets/audio/offline/yo/woman/fallback_1.mp3` | Mi ò lóye dáadáa; ẹ jọ̀ọ́ tún béèrè. |
| `repeat_0` | `assets/audio/offline/yo/woman/repeat_0.mp3` | Bẹ́ẹ̀ ni, gẹ́gẹ́ bí mo ti sọ. |
| `repeat_1` | `assets/audio/offline/yo/woman/repeat_1.mp3` | Mo ti dáhùn ìbéèrè yẹn tẹ́lẹ̀. |

## Dehydration — appearance `man`

| Identifier | File path | Spoken text |
|---|---|---|
| `activite` | `assets/audio/offline/yo/man/activite.mp3` | Mo ṣiṣẹ́ ní oko ní gbogbo ọjọ́; ooru pọ̀ gan-an. |
| `boisson` | `assets/audio/offline/yo/man/boisson.mp3` | Mi ò mu omi púpọ̀ nígbà tí mo ń ṣiṣẹ́. |
| `urines` | `assets/audio/offline/yo/man/urines.mp3` | Mo rò pé mi ò tíì tọ̀ láti òwúrọ̀, tàbí díẹ̀ péré. |
| `symptomes` | `assets/audio/offline/yo/man/symptomes.mp3` | Iṣan ẹsẹ̀ mi máa ń fà, orí mi sì máa ń yí nígbà tí mo bá dìde. |
| `fallback_0` | `assets/audio/offline/yo/man/fallback_0.mp3` | Kò burú, dókítà; ó ṣeé ṣe kó jẹ́ àárẹ̀ iṣẹ́. |
| `fallback_1` | `assets/audio/offline/yo/man/fallback_1.mp3` | Mi ò mọ ohun míì láti sọ. |
| `repeat_0` | `assets/audio/offline/yo/man/repeat_0.mp3` | Mo ṣẹ̀ṣẹ̀ sọ fún yín, àbí bẹ́ẹ̀ kọ́? |
| `repeat_1` | `assets/audio/offline/yo/man/repeat_1.mp3` | Bẹ́ẹ̀ ni, gẹ́gẹ́ bí mo ti sọ tẹ́lẹ̀. |

## Recording notes

- Each file must be an MP3 and must use exactly the filename and path shown in
  the table.
- The identifiers `fallback_0`, `fallback_1`, `repeat_0`, and `repeat_1`
  correspond to response positions in the code. Do not reorder these
  responses unless you also update the filenames.
- Playback looks for these files in the patient's appearance folder. A
  missing Yorùbá recording is not replaced with an English voice.
