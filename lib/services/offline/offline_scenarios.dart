import 'offline_patient_brain.dart';
import '../lang/app_language.dart';
import '../../widgets/patient_avatar.dart' show PatientLook;
import '../scenario_catalog.dart';

/// Version hors-ligne des scénarios de `PatientScenario.examples`.
///
/// Chaque point clé reprend une information que le `systemPrompt` Gemini
/// équivalent ne révélait qu'à condition d'être interrogé dessus : ici,
/// c'est ce même filtre qui devient la mécanique du jeu plutôt qu'une
/// consigne donnée à un modèle.
///
/// Associe un scénario par titre : garde le même `title` que dans
/// `PatientScenario` pour que `offlineScenarioFor` retrouve le bon arbre.
class OfflineScenarios {
  static const feverChild = OfflineScenario(
    title: 'Fièvre chez un enfant',
    look: PatientLook.womanMature, // it's the mother speaking, not the child
    keyPoints: [
      KeyPoint(
        id: 'duree',
        label: 'Asked how long the fever has lasted',
        keywords: [
          'how long',
          'how many days',
          'since when',
          'when did it start',
        ],
        examples: [
          'When did the fever begin?',
          'How many days has he been feeling hot?',
          'Has he had this fever for long?',
        ],
        reply:
            "It's been about two days now that he's been this hot, it's not really going down.",
      ),
      KeyPoint(
        id: 'moustiquaire',
        label: 'Asked whether he sleeps under a mosquito net',
        keywords: ['mosquito net', 'mosquito', 'bed net'],
        examples: [
          'Does he sleep under a net at night?',
          'How do you protect him from mosquito bites?',
          'Is there a mosquito net over his bed?',
        ],
        reply:
            "He sleeps under a mosquito net, yes... well, not always, it has a hole in it.",
        critical: true,
      ),
      KeyPoint(
        id: 'voyage',
        label: 'Asked about a recent trip or travel',
        keywords: ['travel', 'trip', 'village', 'went away', 'visited'],
        examples: [
          'Have you gone anywhere recently?',
          'Did you visit another village lately?',
          'Where have you traveled in the past few weeks?',
        ],
        reply:
            "We went to see his grandmother in the village a week ago, "
            "in a pretty swampy area.",
        critical: true,
      ),
      KeyPoint(
        id: 'autres_symptomes',
        label: 'Looked for other symptoms (lethargy, convulsions...)',
        keywords: [
          'vomit',
          'diarrh',
          'convuls',
          'seizure',
          'letharg',
          'sleeps a lot',
          'tired',
          'other symptom',
          'limp',
        ],
        examples: [
          'Has he had any other problems besides the fever?',
          'Has he been unusually sleepy or hard to wake?',
          'Has he vomited or had any shaking episodes?',
        ],
        reply:
            "He's very limp, he sleeps almost all the time, and he had chills last night.",
        critical: true,
      ),
      KeyPoint(
        id: 'hydratation',
        label: 'Checked whether he is still eating and drinking',
        keywords: ['drink', 'eat', 'hydrat', 'appetite', 'feeding'],
        examples: [
          'Is he able to drink as usual?',
          'Has he been eating and drinking normally?',
          'Is he refusing fluids or food?',
        ],
        reply:
            "He's drinking a bit less than usual, but he's still drinking, a little.",
      ),
    ],
    fallbackReplies: [
      "I'm not really sure, doctor... do you think it's serious?",
      "Hmm, I didn't really pay attention to that, sorry.",
      "Could you repeat the question? I'm a bit lost.",
    ],
    repeatReplies: [
      "I already told you that, didn't I?",
      "Like I said earlier, yes.",
    ],
    clinicalInfo: ScenarioClinicalInfo(
      displayTitle: 'A feverish child for two days',
      correctDiagnosis: 'Suspected malaria',
      distractors: ['Common viral sore throat', 'Ear infection', 'Teething'],
      alertSigns: [
        AlertSign(
          trigger: 'Torn mosquito net',
          cause:
              'Direct exposure to mosquito bites, entry point for the parasite.',
        ),
        AlertSign(
          trigger: 'Recent trip to a swampy area',
          cause: 'Area at risk for malaria transmission.',
        ),
        AlertSign(
          trigger: 'Lethargy, very limp child',
          cause:
              'A danger sign: can signal a rapid progression toward a '
              'severe form.',
        ),
      ],
      symptoms: [
        'Fever with chills',
        'Headache',
        'Body aches',
        'Digestive issues (vomiting, diarrhea), common in children',
      ],
      management:
          'Refer to a health facility for a rapid test without delay. '
          'Emergency if drowsiness, convulsions, or refusal to drink appear.',
    ),
  );

  static const yorubaFeverChild = OfflineScenario(
    title: 'Fièvre chez un enfant',
    language: AppLanguage.yoruba,
    look: PatientLook.womanMature,
    keyPoints: [
      KeyPoint(
        id: 'duree',
        label: 'Beere iye ọjọ́ tí ibà ti fi wà',
        keywords: [
          'ọjọ́ mélòó',
          'ìgbà wo',
          'ibà ti pẹ́',
          'ìgbà',
          'how many days',
          'how long',
        ],
        examples: ['Ọjọ́ mélòó ni ọmọ náà ti ń ṣe ibà?'],
        reply: 'Ọjọ́ méjì ni, ibà náà kò tíì lọ.',
      ),
      KeyPoint(
        id: 'moustiquaire',
        label: 'Beere bóyá ọmọ náà ń sùn lábẹ́ àwọ̀n ẹ̀fọn',
        keywords: [
          'àwọ̀n ẹ̀fọn',
          'ẹ̀fọn',
          'mosquito net',
          'bed net',
        ],
        examples: ['Ṣé ọmọ náà ń sùn lábẹ́ àwọ̀n ẹ̀fọn?'],
        reply: 'Ó máa ń sùn lábẹ́ àwọ̀n ẹ̀fọn, ṣùgbọ́n ihò kan wà nínú rẹ̀.',
        critical: true,
      ),
      KeyPoint(
        id: 'voyage',
        label: 'Beere nípa ìrìnàjò àìpẹ́ yìí',
        keywords: [
          'ìrìnàjò',
          'lọ sí',
          'ìlú',
          'travel',
          'trip',
          'village',
        ],
        examples: ['Ṣé ẹ ti rìnrìn àjò lọ sí ibòmíì láìpẹ́?'],
        reply: 'A lọ bẹ ìyá ọkọ mi wò ní ìlú ní ọ̀sẹ̀ tó kọjá.',
        critical: true,
      ),
      KeyPoint(
        id: 'autres_symptomes',
        label: 'Ṣàyẹ̀wò àwọn àmì míì bí ìgbọ̀n tàbí ìgbagbogbo',
        keywords: [
          'ìgbọ̀n',
          'ìgbagbogbo',
          'ìrẹ̀wẹ̀sì',
          'sùn',
          'ìkọ́',
          'convulsion',
          'seizure',
          'vomit',
        ],
        examples: ['Ṣé ó ní àmì àìsàn míì tàbí ó ń rẹ̀ ẹ́ gan-an?'],
        reply: 'Ó rẹ̀ ẹ́ gan-an, ó sì ti ń sùn ju bó ṣe máa ń sùn lọ.',
        critical: true,
      ),
      KeyPoint(
        id: 'hydratation',
        label: 'Beere bóyá ó ṣì ń jẹun àti mu omi',
        keywords: [
          'mu omi',
          'mu',
          'jẹun',
          'jeun',
          'omi',
          'drink',
          'water',
          'eat',
          'feeding',
        ],
        examples: ['Ṣé ó ṣì ń mu omi àti jẹun bí ó ti máa ń ṣe?'],
        reply: 'Ó ń mu omi díẹ̀ sí i láàárín ọjọ́, ṣùgbọ́n ó ṣì ń mu.',
      ),
    ],
    fallbackReplies: [
      'Ẹ jọ̀ọ́, mi ò lóye ìbéèrè náà dáadáa.',
      'Mi ò mọ̀ dájú; ẹ jọ̀ọ́ tún béèrè.',
    ],
    repeatReplies: [
      'Mo ti sọ fún yín tẹ́lẹ̀.',
      'Bẹ́ẹ̀ ni, gẹ́gẹ́ bí mo ṣe sọ tẹ́lẹ̀.',
    ],
    clinicalInfo: ScenarioClinicalInfo(
      displayTitle: 'Ọmọ kan tí ó ní ibà fún ọjọ́ méjì',
      correctDiagnosis: 'Ìfura sí àìsàn ibà (malaria)',
      distractors: [
        'Àìsàn ọ̀fun ọlọ́jẹ̀',
        'Àkóràn etí',
        'Ìyọ eyín',
      ],
      alertSigns: [
        AlertSign(
          trigger: 'Àwọ̀n ẹ̀fọn tí ó ní ihò',
          cause: 'Ó lè jẹ́ kí ẹ̀fọn já ọmọ náà.',
        ),
        AlertSign(
          trigger: 'Ìrìnàjò sí agbègbè tí ewu ibà wà',
          cause: 'Ó lè fi hàn pé ọmọ náà ti wà ní agbègbè ewu.',
        ),
        AlertSign(
          trigger: 'Ọmọ náà rẹ̀ gan-an tàbí ó ṣòro láti jí',
          cause: 'Èyí lè jẹ́ àmì ewu tó nílò ìtọju kíákíá.',
        ),
      ],
      symptoms: [
        'Ibà àti ìgbọ̀n',
        'Orí fífọ́',
        'Ara ríru',
        'Ìgbagbogbo tàbí ìgbẹ́ gbuuru',
      ],
      management:
          'Ẹ tọ́ka ọmọ náà sí ilé ìwòsàn fún àyẹ̀wò kíákíá. '
          'Tí ó bá ṣòro láti jí, ní ìgbagbogbo, tàbí kò bá fẹ́ mu omi, '
          'ẹ wá ìrànlọ́wọ́ pajawiri.',
    ),
  );

  static const yorubaPostpartumBleeding = OfflineScenario(
    title: 'Saignement post-partum',
    language: AppLanguage.yoruba,
    look: PatientLook.woman,
    keyPoints: [
      KeyPoint(
        id: 'delai_accouchement',
        label: 'Beere ìgbà tí ó ti bí ọmọ',
        keywords: ['bí ọmọ', 'ọjọ́ mélòó', 'ìgbà wo', 'bímọ'],
        examples: ['Ọjọ́ mélòó ni ó ti kọjá tí o ti bí ọmọ?'],
        reply: 'Mo bí ọmọ ní ọjọ́ márùn-ún sẹ́yìn nílé.',
      ),
      KeyPoint(
        id: 'quantite',
        label: 'Ṣàyẹ̀wò bí ẹ̀jẹ̀ náà ṣe pọ̀ tó',
        keywords: ['ẹ̀jẹ̀ pọ̀', 'iye ẹ̀jẹ̀', 'aṣọ mélòó', 'pad', 'ń yí aṣọ'],
        examples: ['Báwo ni ẹ̀jẹ̀ náà ṣe pọ̀ tó?'],
        reply: 'Ẹ̀jẹ̀ náà ti pọ̀ sí i; mo ń yí aṣọ padà lọ́pọ̀ ìgbà.',
        critical: true,
      ),
      KeyPoint(
        id: 'fievre',
        label: 'Beere bóyá ibà tàbí ìgbọ̀n wà',
        keywords: ['ibà', 'gbóná', 'ìgbọ̀n', 'otútù'],
        examples: ['Ṣé ara rẹ̀ ti gbóná tàbí o ti ní ìgbọ̀n?'],
        reply: 'Mo ti ń gbóná díẹ̀ láti àná.',
        critical: true,
      ),
      KeyPoint(
        id: 'odeur',
        label: 'Beere bóyá ìtújáde náà ní òórùn àjèjì',
        keywords: ['òórùn', 'ń rùn', 'rùn búburú', 'ìtújáde'],
        examples: ['Ṣé o ti ṣàkíyèsí òórùn àjèjì nínú ẹ̀jẹ̀ náà?'],
        reply: 'Bẹ́ẹ̀ ni, ó dà bí ẹni pé ó ń rùn díẹ̀ láti òní.',
        critical: true,
      ),
      KeyPoint(
        id: 'douleur',
        label: 'Beere bóyá inú tàbí ikùn ń dùn',
        keywords: ['inú ń dùn', 'ikùn ń dùn', 'ìrora inú', 'ìrora ìsàlẹ̀'],
        examples: ['Ṣé inú rẹ ń dùn tàbí o ní ìrora ní ìsàlẹ̀ ikùn?'],
        reply: 'Inú ìsàlẹ̀ ikùn mi ń dùn bí ìfúnpọ̀.',
      ),
    ],
    fallbackReplies: [
      'Ẹ jọ̀ọ́, ó ṣòro fún mi láti sọ̀rọ̀ nípa rẹ̀.',
      'Mi ò lóye dáadáa; ẹ jọ̀ọ́ tún béèrè.',
    ],
    repeatReplies: [
      'Bẹ́ẹ̀ ni, gẹ́gẹ́ bí mo ti sọ.',
      'Mo ti dáhùn ìbéèrè yẹn tẹ́lẹ̀.',
    ],
    clinicalInfo: ScenarioClinicalInfo(
      displayTitle: 'Ìyá tuntun lẹ́yìn ìbímọ',
      correctDiagnosis: 'Ìfura sí àkóràn inú lẹ́yìn ìbímọ',
      distractors: [
        'Ìmúbọ̀sípò déédé lẹ́yìn ìbímọ',
        'Àrùn ìdọ̀tí inú',
        'Àkóràn ọ̀nà ito',
      ],
      alertSigns: [
        AlertSign(
          trigger: 'Ẹ̀jẹ̀ tàbí ìtújáde tó ní òórùn àjèjì',
          cause: 'Ó lè jẹ́ àmì àkóràn; a nílò àyẹ̀wò.',
        ),
        AlertSign(
          trigger: 'Ibà pẹ̀lú ẹ̀jẹ̀ tó pọ̀',
          cause: 'Ó lè fi hàn pé ìṣòro kan wà lẹ́yìn ìbímọ.',
        ),
        AlertSign(
          trigger: 'Ìrora inú ìsàlẹ̀',
          cause: 'Ó yẹ kí òṣìṣẹ́ ìlera ṣàyẹ̀wò rẹ̀.',
        ),
      ],
      symptoms: ['Ibà', 'Ẹ̀jẹ̀ tó pọ̀', 'Òórùn àjèjì', 'Ìrora inú ìsàlẹ̀'],
      management:
          'Tọ́ka sí ilé ìwòsàn kíákíá fún àyẹ̀wò àti ìtọju. Èyí jẹ́ àlàyé ìdánilẹ́kọ̀ọ́; tẹ̀lé ìlànà ìlera agbègbè.',
    ),
  );

  static const yorubaDehydration = OfflineScenario(
    title: 'Déshydratation',
    language: AppLanguage.yoruba,
    look: PatientLook.man,
    keyPoints: [
      KeyPoint(
        id: 'activite',
        label: 'Beere ohun tí ó ń ṣe kí àwọn àmì náà tó bẹ̀rẹ̀',
        keywords: ['iṣẹ́', 'oko', 'òòrùn', 'ooru', 'gbóná', 'ṣiṣẹ́'],
        examples: ['Kí ni o ń ṣe kí ara rẹ tó bẹ̀rẹ̀ sí í yá?'],
        reply: 'Mo ṣiṣẹ́ ní oko ní gbogbo ọjọ́; ooru pọ̀ gan-an.',
      ),
      KeyPoint(
        id: 'boisson',
        label: 'Beere bóyá ó mu omi tó pọ̀',
        keywords: ['mu omi', 'omi mélòó', 'mu tó', 'omi', 'mu'],
        examples: ['Omi mélòó ni o mu lónìí?'],
        reply: 'Mi ò mu omi púpọ̀ nígbà tí mo ń ṣiṣẹ́.',
        critical: true,
      ),
      KeyPoint(
        id: 'urines',
        label: 'Beere nípa ìgbà tí ó ń tọ̀',
        keywords: ['tọ̀', 'ito', 'ìgbà mélòó', 'ilé ìgbọ̀nsẹ̀'],
        examples: ['Ìgbà wo ni o gbẹ̀yìn tọ̀?'],
        reply: 'Mo rò pé mi ò tíì tọ̀ láti òwúrọ̀, tàbí díẹ̀ péré.',
        critical: true,
      ),
      KeyPoint(
        id: 'symptomes',
        label: 'Ṣàyẹ̀wò bóyá ó ní ìríra orí tàbí ìfúnpọ̀ iṣan',
        keywords: ['ríra orí', 'orí ń yí', 'ìfúnpọ̀', 'iṣan', 'rẹ̀wẹ̀sì', 'dákú'],
        examples: ['Ṣé orí rẹ máa ń yí nígbà tí o bá dìde?'],
        reply: 'Iṣan ẹsẹ̀ mi máa ń fà, orí mi sì máa ń yí nígbà tí mo bá dìde.',
      ),
    ],
    fallbackReplies: [
      'Kò burú, dókítà; ó ṣeé ṣe kó jẹ́ àárẹ̀ iṣẹ́.',
      'Mi ò mọ ohun míì láti sọ.',
    ],
    repeatReplies: [
      'Mo ṣẹ̀ṣẹ̀ sọ fún yín, àbí bẹ́ẹ̀ kọ́?',
      'Bẹ́ẹ̀ ni, gẹ́gẹ́ bí mo ti sọ tẹ́lẹ̀.',
    ],
    clinicalInfo: ScenarioClinicalInfo(
      displayTitle: 'Agbẹ̀ kan tí ó rẹ̀ lẹ́yìn iṣẹ́ ní oko',
      correctDiagnosis: 'Ìfura sí àìtó omi àti àárẹ̀ ooru',
      distractors: [
        'Àárẹ̀ iṣan lasan',
        'Súgà ẹ̀jẹ̀ tó kéré',
        'Ìbẹ̀rẹ̀ àìsàn gágá',
      ],
      alertSigns: [
        AlertSign(
          trigger: 'Kò tọ̀ láti òwúrọ̀',
          cause: 'Ó lè jẹ́ àmì pé omi ara kò tó.',
        ),
        AlertSign(
          trigger: 'Ìfúnpọ̀ iṣan àti orí yíyí',
          cause: 'Ó lè ṣẹlẹ̀ nígbà tí ara bá pàdánù omi.',
        ),
      ],
      symptoms: [
        'Àìlera',
        'Ìfúnpọ̀ iṣan',
        'Orí yíyí',
        'Òùngbẹ púpọ̀',
        'Ito díẹ̀ tàbí tó dúdú',
      ],
      management:
          'Gbe e sí ibòji, fún un ní omi tàbí O.R.S. gẹ́gẹ́ bí ìlànà agbègbè, kí ó sì sinmi. Ìdàrúdàpọ̀ ọpọlọ tàbí àìgbọ̀n yẹ kí a tọ́ka sí ìtọju pajawiri.',
    ),
  );

  static const postpartumBleeding = OfflineScenario(
    title: 'Saignement post-partum',
    look: PatientLook.woman,
    keyPoints: [
      KeyPoint(
        id: 'delai_accouchement',
        label: 'Asked how long ago she gave birth',
        keywords: ['gave birth', 'birth', 'deliver', 'born'],
        examples: [
          'When was your baby born?',
          'How many days ago did you deliver?',
          'How long has it been since you gave birth?',
        ],
        reply:
            "I gave birth 5 days ago, at home with the neighborhood midwife.",
      ),
      KeyPoint(
        id: 'quantite',
        label: 'Assessed how heavy the bleeding is',
        keywords: [
          'how much',
          'amount',
          'heavy',
          'soaking',
          'change cloth',
          'pad',
        ],
        examples: [
          'How much blood are you losing?',
          'How often do you need to change your cloth or pad?',
          'Is the bleeding heavier than before?',
        ],
        reply:
            "It's started again, heavier than the previous days, I have to change my cloth very often.",
        critical: true,
      ),
      KeyPoint(
        id: 'fievre',
        label: 'Checked for an associated fever',
        keywords: ['fever', 'hot', 'temperature', 'chills'],
        examples: [
          'Have you felt feverish or unusually hot?',
          'Have you had chills since the bleeding began?',
          'Did you check your temperature?',
        ],
        reply:
            "Yes, I've felt a bit hot since yesterday, I thought it was just tiredness.",
        critical: true,
      ),
      KeyPoint(
        id: 'odeur',
        label: 'Asked whether the discharge has an unusual smell',
        keywords: ['smell', 'foul', 'odor', 'odour'],
        examples: [
          'Does the blood or discharge smell different?',
          'Have you noticed a bad smell?',
          'Is there an unusual odor?',
        ],
        reply:
            "Now that you mention it... yes, it's smelled a bit bad since this morning.",
        critical: true,
      ),
      KeyPoint(
        id: 'douleur',
        label: 'Asked whether she has belly pain',
        keywords: ['pain', 'contraction', 'hurts', 'ache', 'cramp'],
        examples: [
          'Does your lower abdomen hurt?',
          'Have you had cramps or pain in your belly?',
          'Do you feel any pain around your pelvis?',
        ],
        reply:
            "I have pain in my lower belly, like cramps that keep coming back.",
      ),
    ],
    fallbackReplies: [
      "I'm a little embarrassed to talk about it, but I'm listening.",
      "Sorry, could you rephrase that?",
    ],
    repeatReplies: [
      "Like I told you, yes.",
      "It's still the same as what I just said.",
    ],
    clinicalInfo: ScenarioClinicalInfo(
      displayTitle: 'A worried young mother, 5 days after giving birth',
      correctDiagnosis: 'Suspected endometritis (postpartum uterine infection)',
      distractors: [
        'Normal postpartum recovery',
        'Hemorrhoids',
        'Urinary tract infection',
      ],
      alertSigns: [
        AlertSign(
          trigger: 'Unusual smell of the discharge',
          cause: 'Suggests an infection rather than isolated bleeding.',
        ),
        AlertSign(
          trigger: 'Fever alongside the bleeding',
          cause: 'Distinguishes an infection from simple postpartum bleeding.',
        ),
        AlertSign(
          trigger: 'Pelvic pain',
          cause: 'Sign of an inflamed uterus, poorly involuted.',
        ),
      ],
      symptoms: [
        'Fever',
        'Tender, enlarged uterus',
        'Heavy, foul-smelling discharge',
        'Pelvic pain',
        'Marked fatigue',
      ],
      management:
          'Urgent referral to a health facility for antibiotic treatment. '
          'Heavy bleeding combined with fever is a signal that should never '
          'be dismissed.',
    ),
  );

  static const dehydration = OfflineScenario(
    title: 'Déshydratation',
    look: PatientLook.man,
    keyPoints: [
      KeyPoint(
        id: 'activite',
        label: 'Asked what he was doing before the symptoms started',
        keywords: ['field', 'work', 'heat', 'sun', 'all day'],
        examples: [
          'What were you doing when you started feeling unwell?',
          'Were you working outside in the sun?',
          'How was your day before these symptoms began?',
        ],
        reply: "I spent the day in the field, it was very hot today.",
      ),
      KeyPoint(
        id: 'boisson',
        label: 'Asked whether he drank enough',
        keywords: ['drank', 'drink', 'water', 'hydrat', 'fluids'],
        examples: [
          'How much water did you drink today?',
          'Were you able to drink while you were working?',
          'Have you had enough fluids since this morning?',
        ],
        reply:
            "Well, I didn't drink much while I was working, I didn't have time.",
        critical: true,
      ),
      KeyPoint(
        id: 'urines',
        label: 'Asked about how often he urinates',
        keywords: ['urin', 'pee', 'toilet'],
        examples: [
          'When did you last pass urine?',
          'Have you been urinating as often as usual?',
          'How many times have you gone to the toilet today?',
        ],
        reply:
            "I haven't urinated since this morning I think, or just a little.",
        critical: true,
      ),
      KeyPoint(
        id: 'symptomes',
        label: 'Looked for dizziness or cramps',
        keywords: [
          'dizz',
          'cramp',
          'weak',
          'head spin',
          'lightheaded',
          'faint',
        ],
        examples: [
          'Do you feel dizzy when you stand up?',
          'Have you had any muscle cramps or weakness?',
          'Have you felt faint or lightheaded?',
        ],
        reply:
            "I get cramps in my legs and my head spins a bit when I stand up.",
      ),
    ],
    fallbackReplies: [
      "It's nothing, doctor, it's just work fatigue.",
      "I don't really know what else to tell you.",
    ],
    repeatReplies: ["I just told you that, didn't I?", "Same as before."],
    clinicalInfo: ScenarioClinicalInfo(
      displayTitle: 'A farmer exhausted after a day in the field',
      correctDiagnosis: 'Dehydration / heat exhaustion',
      distractors: [
        'Simple muscle fatigue',
        'Hypoglycemia',
        'Onset of the flu',
      ],
      alertSigns: [
        AlertSign(
          trigger: 'No urination since the morning',
          cause: 'Direct sign of dehydration.',
        ),
        AlertSign(
          trigger: 'Cramps and dizziness',
          cause:
              'Electrolyte imbalance from fluid loss through sweat without '
              'replacement.',
        ),
      ],
      symptoms: [
        'Weakness',
        'Muscle cramps',
        'Dizziness',
        'Dark, infrequent urine',
        'Intense thirst',
      ],
      management:
          'Move to shade, rehydrate immediately (water, ideally an oral '
          'rehydration solution), rest. Separate warning sign: confusion or '
          'no sweating despite the heat — suspected heat stroke, medical '
          'emergency, immediate referral.',
    ),
  );

  static const all = [feverChild, postpartumBleeding, dehydration];

  /// Retrouve l'arbre hors-ligne correspondant à un titre de
  /// `PatientScenario`. Cherche d'abord dans le socle embarqué (les 3
  /// scénarios ci-dessus), puis dans les scénarios synchronisés depuis
  /// Firestore. `null` si aucun des deux n'a de version hors-ligne pour ce
  /// titre (dans ce cas, le mode hors-ligne et le bouton diagnostic
  /// doivent rester grisés dans l'UI).
  static OfflineScenario? forTitle(
    String title, {
    AppLanguage language = AppLanguage.english,
  }) {
    if (language.isYoruba && title == feverChild.title) {
      return yorubaFeverChild;
    }
    if (language.isYoruba && title == postpartumBleeding.title) {
      return yorubaPostpartumBleeding;
    }
    if (language.isYoruba && title == dehydration.title) {
      return yorubaDehydration;
    }
    for (final s in all) {
      if (s.title == title) return s;
    }
    return ScenarioCatalog.instance.bundleForTitle(title)?.toOfflineScenario();
  }
}
