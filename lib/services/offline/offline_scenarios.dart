import 'offline_patient_brain.dart';
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
  static OfflineScenario? forTitle(String title) {
    for (final s in all) {
      if (s.title == title) return s;
    }
    return ScenarioCatalog.instance.bundleForTitle(title)?.toOfflineScenario();
  }
}
