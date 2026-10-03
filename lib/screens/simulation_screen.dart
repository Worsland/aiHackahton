import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/model_management/cancel_token.dart';
import '../services/gemini_service.dart';
import '../services/firebase/auth_service.dart';
import '../services/live/gemini_live_service.dart';
import '../services/lang/app_language.dart';
import '../services/offline/offline_patient_brain.dart';
import '../services/offline/offline_voice_player.dart';
import '../services/offline/offline_scenarios.dart';
import '../services/offline/embedder_setup.dart';
import '../services/offline/semantic_matcher.dart';
import 'diagnosis_screen.dart';
import 'progress_screen.dart';
import '../services/scenario_catalog.dart';
import '../services/scenario_score_board.dart';
import '../services/voice_service.dart';
import '../services/web_stt/web_offline_stt.dart';
import '../services/patient_scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/patient_avatar.dart';
import 'profile_screen.dart';

/// Largeur maximale du contenu : au-delà, l'interface reste centrée au lieu
/// de s'étirer sur tout l'écran (PC, tablette en paysage).
const double _kContentMaxWidth = 720;

/// À partir de cette largeur, on passe en disposition "grand écran".
const double _kWideBreakpoint = 720;

/// À partir de cette largeur, la page de simulation se scinde en deux
/// colonnes (avatar/voix à gauche, messages/texte à droite) au lieu
/// d'empiler tout verticalement.
const double _kSplitBreakpoint = 980;

/// Largeur fixe de la sidebar de navigation (grand écran) : sert aussi à
/// calculer l'espace réellement disponible pour le contenu à côté d'elle.
const double _kSidebarWidth = 260;

bool _isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= _kWideBreakpoint;

/// Titre neutre affiché à l'agent. Jamais l'identifiant interne du
/// scénario (`PatientScenario.title`), qui peut trahir le diagnostic
/// (ex : "Déshydratation").
String _displayTitle(
  String internalTitle, {
  AppLanguage language = AppLanguage.english,
}) =>
    OfflineScenarios.forTitle(
      internalTitle,
      language: language,
    )?.clinicalInfo.displayTitle ??
    internalTitle;

/// Centre son contenu et limite sa largeur à [_kContentMaxWidth].
class _ContentWidth extends StatelessWidget {
  const _ContentWidth({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
        child: child,
      ),
    );
  }
}

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key, required this.geminiService});
  final GeminiService geminiService;

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

/// Les deux modes de conversation :
///  - [live] : voix naturelle via Gemini Live (nécessite du réseau) ;
///  - [offline] : arbre de dialogue local, aucun réseau requis (mobile).
enum ConversationMode { live, offline }

class _SimulationScreenState extends State<SimulationScreen> {
  final VoiceService _voice = VoiceService();
  late final OfflineVoicePlayer _offlineVoice = OfflineVoicePlayer(
    fallbackVoice: _voice,
  );

  /// Mode "voix naturelle" : conversation en temps réel via Gemini Live.
  late final GeminiLiveService _live = GeminiLiveService(
    apiKey: widget.geminiService.apiKey,
  );

  /// Le mode "naturel" (Gemini Live, ancien bool `_liveMode = true`) reste
  /// utilisable ailleurs dans le fichier via `_mode == ConversationMode.live`.
  ConversationMode _mode = ConversationMode.live;
  AppLanguage _language = AppLanguage.english;

  /// Cerveau hors-ligne pour le scénario en cours (arbre de dialogue local,
  /// aucun réseau). `null` si ce scénario n'a pas encore de version
  /// hors-ligne, auquel cas ce mode est grisé dans l'UI.
  OfflinePatientBrain? _offlineBrain;
  Future<TextEmbedder>? _offlineEmbedderFuture;
  Future<void>? _offlineGemmaInitialization;
  Future<void>? _offlinePreparation;
  OfflinePatientBrain? _preparingBrain;
  bool _offlineAiEnabled = false;
  bool _offlineAiPreparing = false;
  bool _offlineAiUnavailable = false;
  bool _offlineAiSkipped = false;

  final List<_Turn> _transcript = [];

  PatientScenario? _scenario;
  bool _isListening = false;
  bool _isBusy = false;
  bool _isSpeaking = false;

  /// Champ de saisie manuelle, toujours visible dans les modes autres que
  /// Live (remplace l'ancien `showDialog`, puis le bouton à bascule) : voir
  /// `_buildMessageBar`.
  final TextEditingController _typedController = TextEditingController();
  final FocusNode _typedFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _voice.init();
    _live.onTurn = _onLiveTurn;
    _live.onError = _onLiveError;
    _live.addListener(_onLiveChanged);
    ScenarioCatalog.instance.addListener(_onCatalogChanged);
  }

  @override
  void dispose() {
    ScenarioCatalog.instance.removeListener(_onCatalogChanged);
    _live.removeListener(_onLiveChanged);
    _live.dispose();
    _voice.dispose();
    unawaited(_offlineVoice.dispose());
    _typedController.dispose();
    _typedFocus.dispose();
    super.dispose();
  }

  void _onCatalogChanged() {
    if (mounted) setState(() {});
  }

  /// Synchronisation manuelle (icône dans l'en-tête) : donne un retour
  /// explicite plutôt que de compter uniquement sur la synchro silencieuse
  /// lancée au démarrage dans main.dart.
  Future<void> _syncScenarios() async {
    final added = await ScenarioCatalog.instance.syncFromCloud();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added > 0
              ? '$added new scenario${added > 1 ? "s" : ""} added.'
              : 'Scenarios are up to date.',
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mode voix naturelle (Gemini Live)
  // ---------------------------------------------------------------------

  void _onLiveChanged() {
    if (mounted) setState(() {});
  }

  void _onLiveTurn(String text, {required bool isAgent}) {
    if (!mounted) return;
    setState(() => _transcript.add(_Turn(text, isAgent: isAgent)));
  }

  void _onLiveError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _offlineAvailable
              ? '$message You can switch to offline mode (icon at the top).'
              : message,
        ),
      ),
    );
  }

  Future<void> _toggleLive() async {
    if (_live.isActive) {
      await _live.stop();
      return;
    }
    final scenario = _scenario!;
    await _voice.stopSpeaking();
    await _offlineVoice.stop();
    await _live.start(
      systemPrompt: scenario.systemPrompt,
      voiceName: _ScenarioVisuals.of(scenario.title).look.voiceName,
    );
  }

  /// Retour à la liste des scénarios : coupe la voix et la conversation.
  void _backToPicker() {
    _voice.stopSpeaking();
    _offlineVoice.stop();
    _live.stop();
    setState(() {
      _scenario = null;
      _isSpeaking = false;
      _offlineBrain = null;
    });
  }

  void _startScenario(PatientScenario scenario) {
    _voice.stopSpeaking();
    _offlineVoice.stop();
    _live.stop();
    final offlineScenario = OfflineScenarios.forTitle(
      scenario.title,
      language: _language,
    );
    final selectedMode = _language.isYoruba ? ConversationMode.offline : _mode;
    setState(() {
      _scenario = scenario;
      _mode = selectedMode;
      _transcript.clear();
      _isSpeaking = false;
      _offlineAiPreparing = false;
      _offlineAiUnavailable = false;
      _offlineAiSkipped =
          (!_offlineAiEnabled || _language.isYoruba) &&
          _mode == ConversationMode.offline;
      _offlineBrain = offlineScenario == null
          ? null
          : OfflinePatientBrain(offlineScenario);
      if (_mode == ConversationMode.offline && _offlineBrain == null) {
        _mode = ConversationMode.live;
      }
    });
    if (!_language.isYoruba) {
      widget.geminiService.startScenarioChat(scenario.systemPrompt);
    }
    final brain = _offlineBrain;
    if (_mode == ConversationMode.offline &&
        _offlineAiEnabled &&
        !_language.isYoruba &&
        brain != null) {
      unawaited(_prepareOfflineBrain(brain));
    }
  }

  Future<TextEmbedder> _loadOfflineEmbedder({
    void Function(int progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final cached = _offlineEmbedderFuture;
    if (cached != null) return cached;

    final future = _initializeOfflineEmbedder(
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    _offlineEmbedderFuture = future;
    try {
      return await future;
    } catch (_) {
      if (identical(_offlineEmbedderFuture, future)) {
        _offlineEmbedderFuture = null;
      }
      rethrow;
    }
  }

  Future<TextEmbedder> _initializeOfflineEmbedder({
    void Function(int progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final initialization = _offlineGemmaInitialization ??=
        initGemmaEmbeddings();
    try {
      await initialization;
    } catch (_) {
      if (identical(_offlineGemmaInitialization, initialization)) {
        _offlineGemmaInitialization = null;
      }
      rethrow;
    }
    return ensureEmbedder(onProgress: onProgress, cancelToken: cancelToken);
  }

  Future<void> _prepareOfflineBrain(OfflinePatientBrain brain) {
    if (brain.semanticEnabled) return Future.value();
    if (identical(_preparingBrain, brain) && _offlinePreparation != null) {
      return _offlinePreparation!;
    }

    _preparingBrain = brain;
    final preparation = _prepareOfflineBrainOnce(brain);
    _offlinePreparation = preparation;
    return preparation.whenComplete(() {
      if (identical(_offlinePreparation, preparation)) {
        _offlinePreparation = null;
        _preparingBrain = null;
      }
    });
  }

  Future<void> _prepareOfflineBrainOnce(OfflinePatientBrain brain) async {
    if (mounted && identical(_offlineBrain, brain)) {
      setState(() {
        _offlineAiPreparing = true;
        _offlineAiUnavailable = false;
      });
    }

    try {
      final embedder = await _loadOfflineEmbedder();
      await brain.enableSemantic(embedder);
    } catch (error) {
      debugPrint('Offline semantic AI unavailable: $error');
      if (mounted &&
          identical(_offlineBrain, brain) &&
          _mode == ConversationMode.offline) {
        _showSnack(
          'On-device AI unavailable ($error); using basic offline matching.',
        );
      }
    } finally {
      if (mounted && identical(_offlineBrain, brain)) {
        setState(() {
          _offlineAiPreparing = false;
          _offlineAiUnavailable = !brain.semanticEnabled;
        });
      }
    }
  }

  Future<void> _recordAndSend() async {
    if (_isBusy) return;

    // Si le patient parle encore, on le coupe : l'agent reprend la main.
    await _voice.stopSpeaking();
    await _offlineVoice.stop();
    setState(() {
      _isSpeaking = false;
      _isListening = true;
    });

    var heard = '';
    try {
      heard = await _voice.listenOnce(
        onDevice: _mode == ConversationMode.offline,
      );
    } on OfflineSttException catch (e) {
      _showSnack(e.message);
    }
    if (!mounted) return;
    setState(() => _isListening = false);
    await _handleAgentUtterance(heard);
  }

  /// Bascule un champ de texte inline à la place du micro, pour taper la
  /// question au lieu de la dire, sans quitter l'écran de conversation
  /// (remplace l'ancien `showDialog`, qui masquait tout le contexte).
  ///
  /// Sur le web, il n'existe pas de reconnaissance vocale sans réseau (le
  /// navigateur envoie toujours l'audio à un serveur pour le transcrire) :
  /// c'est la seule façon de tester le patient hors ligne depuis un
  /// ordinateur. Sur téléphone, ça reste utile dans un lieu bruyant.
  Future<void> _submitTyped() async {
    final text = _typedController.text;
    _typedController.clear();
    if (text.trim().isEmpty) return;
    await _handleAgentUtterance(text);
    // Reste en mode saisie pour enchaîner plusieurs questions tapées.
    if (mounted) _typedFocus.requestFocus();
  }

  /// Traite ce que l'agent vient de dire (parlé ou tapé) : l'ajoute au
  /// chat, obtient la réponse du patient (locale en mode hors ligne, via
  /// Gemini sinon) et la fait "parler" par l'avatar.
  Future<void> _handleAgentUtterance(String heard) async {
    if (heard.trim().isEmpty || _isBusy) return;

    setState(() {
      _transcript.add(_Turn(heard, isAgent: true));
      _isBusy = true;
    });

    try {
      // Mode hors-ligne : réponse locale immédiate, aucun appel réseau.
      // `offlineReply` garde l'identifiant de la réplique (`audioId`),
      // nécessaire pour retrouver le bon fichier audio pré-enregistré.
      OfflineReply? offlineReply;
      String replyText;
      if (_mode == ConversationMode.offline) {
        final brain = _offlineBrain!;
        if (_offlineAiEnabled && !_language.isYoruba) {
          unawaited(_prepareOfflineBrain(brain));
        }
        offlineReply = await brain
            .replyAsync(heard)
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () {
                _showSnack(
                  'On-device AI is taking too long; using basic offline matching.',
                );
                return brain.reply(heard);
              },
            );
        replyText = offlineReply.text;
        if (offlineReply.needsRephrase && _language.isYoruba) {
          _showSnack(
            'A kò dá wa lójú. Jọ̀ọ́ tún béèrè tàbí béèrè lọ́wọ́ olùkọ́.',
          );
        }
      } else {
        replyText = await widget.geminiService.sendMessage(heard);
      }
      if (!mounted) return;
      // Le patient a fini de "réfléchir" : il parle. speak() ne se termine
      // qu'à la fin de la voix (awaitSpeakCompletion / fin du fichier
      // audio), donc la bouche s'anime pendant toute la durée de la
      // réponse.
      setState(() {
        _transcript.add(_Turn(replyText, isAgent: false));
        _isBusy = false;
        _isSpeaking = true;
      });
      if (offlineReply != null && !_language.isYoruba) {
        await _offlineVoice.speak(_clinicalData!.look, offlineReply);
      } else if (offlineReply == null) {
        await _voice.speak(replyText);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _transcript.add(_Turn('Error: $e', isAgent: false)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _isSpeaking = false;
        });
      }
    }
  }

  bool get _liveOn => _mode == ConversationMode.live && _live.isLive;

  /// Contenu clinique (diagnostic, signaux, points clés) du scénario en
  /// cours. `null` tant que tous les scénarios n'ont pas encore de fiche
  /// clinique — dans ce cas le bouton diagnostic doit rester désactivé.
  OfflineScenario? get _clinicalData => _scenario == null
      ? null
      : OfflineScenarios.forTitle(_scenario!.title, language: _language);

  void _openDiagnosis() {
    final data = _clinicalData;
    if (data == null) return;
    final agentUtterances = _transcript
        .where((t) => t.isAgent)
        .map((t) => t.text)
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiagnosisScreen(
          clinicalInfo: data.clinicalInfo,
          language: _language,
          keyPoints: data.keyPoints,
          agentUtterances: agentUtterances,
          scenarioTitle: _scenario!.title,
          mode: _mode.name,
        ),
      ),
    );
  }

  String get _statusText {
    if (_mode == ConversationMode.offline) {
      if (_language.isYoruba) {
        return 'Ó ń ṣiṣẹ́ láìsí intanẹẹti · A kò fi ìbéèrè ránṣẹ́ síta · '
            'Ìbéèrè pàtàkì tí a ti béèrè: '
            '${_offlineBrain?.askedKeyPoints.length ?? 0}/'
            '${_offlineBrain?.scenario.keyPoints.length ?? 0}. '
            'Àkọsílẹ̀ Yorùbá jẹ́ àkọ́kọ́; a ó tún yẹ̀ ẹ́ wò. '
            'Ìdáhùn jẹ́ ọ̀rọ̀ nìkan; a kò tíì fi ohùn Yorùbá kún un.';
      }
      final aiStatus = _offlineAiPreparing
          ? 'Preparing on-device AI… '
          : _offlineBrain?.semanticEnabled == true
          ? 'On-device AI active. '
          : _offlineAiUnavailable
          ? 'Keyword matching: on-device AI unavailable. '
          : _offlineAiSkipped
          ? 'Keyword matching: AI not selected. '
          : 'Keyword matching: on-device AI not enabled. ';
      return 'Offline mode · no data sent · $aiStatus'
          '${_offlineBrain?.askedKeyPoints.length ?? 0}/'
          '${_offlineBrain?.scenario.keyPoints.length ?? 0} key points covered.';
    }
    if (_mode == ConversationMode.live) {
      switch (_live.state) {
        case LiveState.connecting:
          return 'Connecting to the patient…';
        case LiveState.live:
          if (_live.patientSpeaking) {
            return 'The patient is answering… (tap them to interrupt)';
          }
          if (_live.agentSpeaking) return 'I\'m listening…';
          if (_live.waitingReply) return 'The patient is thinking…';
          return 'Conversation in progress: speak naturally.';
        case LiveState.idle:
        case LiveState.error:
          return _scenario!.description;
      }
    }
    if (_isListening) return 'I\'m listening…';
    if (_isSpeaking) return 'The patient is answering…';
    if (_isBusy) return 'The patient is thinking…';
    return _scenario!.description;
  }

  /// Le dialogue hors ligne par mots-clés est aussi disponible sur le web
  /// après le chargement de l'app ; Gecko reste réservé au mobile.
  bool get _offlineAvailable => _offlineBrain != null;

  IconData get _modeIcon => switch (_mode) {
    ConversationMode.live => Icons.graphic_eq_rounded,
    ConversationMode.offline => Icons.wifi_off_rounded,
  };

  String get _modeTooltip => switch (_mode) {
    ConversationMode.live =>
      'Online: natural voice (Gemini Live). Tap for offline mode',
    ConversationMode.offline => 'Offline: no data sent. Tap for online mode',
  };

  /// Bascule online ↔ offline et propose le téléchargement au premier usage.
  Future<void> _cycleMode() async {
    if (_language.isYoruba) return;
    if (_mode == ConversationMode.offline) {
      setState(() => _mode = ConversationMode.live);
      return;
    }

    final brain = _offlineBrain;
    if (brain == null) return;

    if (kIsWeb) {
      setState(() {
        _mode = ConversationMode.offline;
        _offlineAiSkipped = true;
        _offlineAiUnavailable = false;
      });
      return;
    }

    if (_offlineAiEnabled && _offlineEmbedderFuture != null) {
      setState(() => _mode = ConversationMode.offline);
      unawaited(_prepareOfflineBrain(brain));
      return;
    }

    final initialization = _offlineGemmaInitialization ??=
        initGemmaEmbeddings();
    TextEmbedder? installedEmbedder;
    try {
      await initialization;
      installedEmbedder = await loadInstalledEmbedder();
    } catch (_) {
      if (identical(_offlineGemmaInitialization, initialization)) {
        _offlineGemmaInitialization = null;
      }
    }
    if (!mounted) return;
    if (installedEmbedder != null) {
      _offlineEmbedderFuture = Future.value(installedEmbedder);
      setState(() {
        _mode = ConversationMode.offline;
        _offlineAiEnabled = true;
        _offlineAiUnavailable = false;
        _offlineAiSkipped = false;
      });
      unawaited(_prepareOfflineBrain(brain));
      return;
    }

    final useOfflineAi = await _showOfflineAiSetupDialog(brain);
    if (!mounted || useOfflineAi == null) return;
    setState(() {
      _mode = ConversationMode.offline;
      _offlineAiEnabled = useOfflineAi;
      _offlineAiUnavailable = false;
      _offlineAiSkipped = !useOfflineAi;
    });
    if (useOfflineAi) unawaited(_prepareOfflineBrain(brain));
  }

  Future<bool?> _showOfflineAiSetupDialog(OfflinePatientBrain brain) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var downloading = false;
        var cancelRequested = false;
        var progress = 0;
        String? errorMessage;
        CancelToken? cancelToken;

        return StatefulBuilder(
          builder: (context, setDialogState) => PopScope(
            canPop: !downloading,
            child: AlertDialog(
              title: const Text('Préparer le mode offline'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Télécharger une fois le modèle IA (environ 115 Mo). '
                    'Ensuite, les questions seront traitées sur ce téléphone, '
                    'même sans connexion.',
                  ),
                  if (downloading) ...[
                    const SizedBox(height: 20),
                    LinearProgressIndicator(value: progress / 100),
                    const SizedBox(height: 8),
                    Text('$progress %'),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: downloading
                      ? (cancelRequested
                            ? null
                            : () {
                                cancelRequested = true;
                                cancelToken?.cancel('User cancelled download');
                                setDialogState(() {});
                              })
                      : () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    downloading
                        ? (cancelRequested ? 'Annulation…' : 'Annuler')
                        : 'Continuer sans IA',
                  ),
                ),
                TextButton(
                  onPressed: downloading
                      ? null
                      : () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Plus tard'),
                ),
                FilledButton(
                  onPressed: downloading
                      ? null
                      : () async {
                          cancelToken = CancelToken();
                          setDialogState(() {
                            downloading = true;
                            cancelRequested = false;
                            errorMessage = null;
                            progress = 0;
                          });
                          try {
                            final embedder = await _loadOfflineEmbedder(
                              cancelToken: cancelToken,
                              onProgress: (value) {
                                if (dialogContext.mounted) {
                                  setDialogState(() => progress = value);
                                }
                              },
                            );
                            await brain.enableSemantic(embedder);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } catch (error) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              downloading = false;
                              errorMessage = CancelToken.isCancel(error)
                                  ? 'Téléchargement annulé. Tu peux continuer sans le modèle.'
                                  : 'Impossible de charger le modèle : $error';
                            });
                          }
                        },
                  child: Text(
                    downloading ? 'Téléchargement…' : 'Télécharger / charger',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
  }

  PatientMood get _mood {
    if (_liveOn) {
      if (_live.patientSpeaking) return PatientMood.speaking;
      if (_live.agentSpeaking) return PatientMood.listening;
      if (_live.waitingReply) return PatientMood.thinking;
      return PatientMood.idle;
    }
    if (_isListening) return PatientMood.listening;
    if (_isSpeaking) return PatientMood.speaking;
    if (_isBusy) return PatientMood.thinking;
    return PatientMood.idle;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _scenario == null ? _buildScenarioPicker() : _buildSimulation(),
    );
  }

  // ---------------------------------------------------------------------
  // Écran 1 — choix du scénario
  // ---------------------------------------------------------------------

  Widget _buildScenarioPicker() {
    final wide = _isWide(context);

    // Marges latérales du contenu (bandeau + cartes). Sur grand écran, la
    // sidebar occupe déjà 260px à gauche : il ne faut pas centrer les
    // cartes dans l'espace restant (ça recrée un vide), juste une marge
    // fixe et modeste des deux côtés pour que ça respire. Sur mobile, on
    // garde une marge plus petite.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = wide ? screenWidth - _kSidebarWidth : screenWidth;
    final side = availableWidth > 640 ? 32.0 : 16.0;

    // Scénarios groupés par palier (Easy → Medium → Hard) pour la liste ;
    // voir `_groupedScenarioItems`.
    final availableScenarios = _language.isYoruba
        ? PatientScenario.examples
              .where((s) => s.title == OfflineScenarios.feverChild.title)
              .toList()
        : ScenarioCatalog.instance.scenarios;
    final pickerItems = _groupedScenarioItems(
      availableScenarios,
      language: _language,
    );

    final content = SafeArea(
      // La sidebar gère déjà la navigation sur grand écran : pas besoin
      // que SafeArea réserve aussi une marge à gauche dans ce cas.
      left: !wide,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(side + 8, 28, side + 8, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bandeau purement décoratif : la navigation (menu,
                  // profil, sync...) vit dans la sidebar/le drawer, jamais
                  // ici.
                  const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _language.isYoruba
                        ? 'Ẹ ṣe ìdánilẹ́kọ̀ọ́ ìfọ̀rọ̀wánilẹ́nuwò ìlera'
                        : 'Practice your medical interview',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _language.isYoruba
                        ? 'Yan aláìsàn àfojúṣe kí o sì ṣe ìdánilẹ́kọ̀ọ́ láìsí intanẹẹti.'
                        : 'Choose a virtual patient and run the consultation out loud.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<AppLanguage>(
                      value: _language,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final language in AppLanguage.values)
                          DropdownMenuItem(
                            value: language,
                            child: Text(language.label),
                          ),
                      ],
                      onChanged: (language) {
                        if (language == null) return;
                        setState(() {
                          if (_language.isYoruba &&
                              language == AppLanguage.english) {
                            _mode = ConversationMode.live;
                          }
                          _language = language;
                        });
                      },
                    ),
                  ),
                  if (_language.isYoruba) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Àkọ́kọ́ Yorùbá fún ìdánwò ni. Jọ̀ọ́ ṣàyẹ̀wò ọ̀rọ̀ àti ìmọ̀ ìlera.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(side, 20, side, 32),
            sliver: SliverList.separated(
              itemCount: pickerItems.length,
              separatorBuilder: (context, i) {
                // Pas d'espace supplémentaire juste après un en-tête de
                // palier : son propre padding suffit déjà.
                final currentIsHeader = pickerItems[i] is _DifficultyGroup;
                final nextIsHeader = pickerItems[i + 1] is _DifficultyGroup;
                if (currentIsHeader || nextIsHeader) {
                  return const SizedBox.shrink();
                }
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, i) {
                final item = pickerItems[i];
                if (item is _DifficultyGroup) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(4, i == 0 ? 0 : 22, 4, 10),
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }
                final s = item as PatientScenario;
                return _ScenarioCard(
                  scenario: s,
                  language: _language,
                  onTap: () => _startScenario(s),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (wide) {
      // Grand écran : sidebar permanente à gauche, comme un vrai menu
      // d'application, entièrement séparée du bandeau de description.
      return Scaffold(
        key: const ValueKey('picker'),
        body: SafeArea(
          child: Row(
            children: [
              _NavSidebar(entries: _navEntries(context)),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    // Petit écran : un simple bouton menu ouvre un tiroir de navigation
    // depuis le bord, plutôt que d'empiler des icônes dans le bandeau.
    return Scaffold(
      key: const ValueKey('picker'),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/ilera.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('Ilera'),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _NavDrawer(entries: _navEntries(context)),
      body: content,
    );
  }

  /// Items de navigation partagés par la sidebar (grand écran) et le
  /// tiroir (petit écran) : une seule liste à tenir à jour.
  List<_NavEntry> _navEntries(BuildContext context) {
    return [
      _NavEntry(
        icon: Icons.person_outline_rounded,
        label: 'My profile',
        // Nom, prénom, photo et scores : voir profile_screen.dart. La
        // liaison de compte (email/déconnexion) reste dans AccountScreen,
        // accessible depuis cet écran plutôt que dupliquée ici.
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const ProfileScreen())),
      ),
      _NavEntry(
        icon: Icons.insights_rounded,
        label: 'My progress',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const ProgressScreen())),
      ),
      _NavEntry(
        icon: Icons.sync_rounded,
        label: ScenarioCatalog.instance.isSyncing
            ? 'Syncing…'
            : 'Sync scenarios',
        trailing: ScenarioCatalog.instance.isSyncing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: ScenarioCatalog.instance.isSyncing ? null : _syncScenarios,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // Écran 2 — simulation
  // ---------------------------------------------------------------------

  Widget _buildSimulation() {
    // PopScope : le bouton retour du système (Android) ramène à la liste
    // des scénarios au lieu de quitter l'application.
    return PopScope(
      key: const ValueKey('simulation'),
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToPicker();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: _language.isYoruba
                ? 'Padà sí àwọn àpẹẹrẹ'
                : 'Back to scenarios',
            onPressed: _backToPicker,
          ),
          title: Text(_displayTitle(_scenario!.title, language: _language)),
          actions: [
            if (_offlineBrain != null && !_language.isYoruba)
              IconButton(
                icon: Icon(_modeIcon),
                tooltip: _modeTooltip,
                // Pas de changement de mode en pleine conversation.
                onPressed: _live.isActive ? null : _cycleMode,
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth >= _kSplitBreakpoint
                  ? _buildSplitLayout()
                  : _buildStackedLayout();
            },
          ),
        ),
      ),
    );
  }

  /// Téléphone / tablette portrait : tout est empilé verticalement, avatar
  /// en haut, conversation au milieu, contrôles en bas.
  Widget _buildStackedLayout() {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Column(
                      children: [
                        // Toucher le patient pendant qu'il parle l'interrompt.
                        GestureDetector(
                          onTap: _liveOn ? _live.interrupt : null,
                          child: PatientAvatar(
                            mood: _mood,
                            look: _ScenarioVisuals.of(_scenario!.title).look,
                            size: _isWide(context) ? 190 : 150,
                            // Bouche calée sur l'audio réel en mode Live.
                            mouthLevel: _mode == ConversationMode.live
                                ? _live.mouthLevel
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Text(
                            _statusText,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              if (_transcript.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyTranscript(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ChatBubble(turn: _transcript[i]),
                      childCount: _transcript.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildControls(),
      ],
    );
  }

  /// Écran large (PC, tablette paysage) : deux colonnes. À gauche, l'avatar
  /// et l'interaction vocale ; à droite, le fil de la conversation et la
  /// saisie écrite. Les deux restent synchronisés sur le même transcript.
  Widget _buildSplitLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              children: [
                // Toucher le patient pendant qu'il parle l'interrompt.
                GestureDetector(
                  onTap: _liveOn ? _live.interrupt : null,
                  child: PatientAvatar(
                    mood: _mood,
                    look: _ScenarioVisuals.of(_scenario!.title).look,
                    size: 220,
                    mouthLevel: _mode == ConversationMode.live
                        ? _live.mouthLevel
                        : null,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                // Le geste vocal vit ici, sous l'avatar : c'est le panneau
                // "avec lequel on interagit". Le panneau de droite ne sert
                // qu'à lire et taper, jamais à parler.
                _mode == ConversationMode.live
                    ? _buildLiveCallButton()
                    : _buildOfflineKeyboardIndicator(),
                const Spacer(),
                _buildVerticalSessionActions(),
              ],
            ),
          ),
        ),
        Expanded(child: _buildChatPanel()),
      ],
    );
  }

  Widget _buildVerticalSessionActions() {
    final diagnosisButton = FilledButton.icon(
      icon: const Icon(Icons.psychology_alt_outlined, size: 18),
      label: Text(_language.isYoruba ? 'Ṣe àyẹ̀wò' : 'Diagnosis'),
      onPressed: (_isBusy || _transcript.isEmpty || _clinicalData == null)
          ? null
          : _openDiagnosis,
    );
    return Column(
      children: [SizedBox(width: double.infinity, child: diagnosisButton)],
    );
  }

  /// Colonne de droite en mode "split" : fil de conversation + saisie
  /// écrite. Pas de micro ici (il vit dans le panneau de gauche) : en mode
  /// hors ligne on garde juste un champ de texte + bouton d'envoi.
  Widget _buildChatPanel() {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          Expanded(
            child: _transcript.isEmpty
                ? _buildEmptyTranscript()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    itemCount: _transcript.length,
                    itemBuilder: (context, i) =>
                        _ChatBubble(turn: _transcript[i]),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: _mode == ConversationMode.live
                ? Text(
                    'Voice only during a live call. Switch to offline mode '
                    '(icon at the top) to type instead.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  )
                : _buildWideMessageField(),
          ),
        ],
      ),
    );
  }

  /// Champ de saisie de la colonne de droite (mode "split") : uniquement
  /// texte + envoi, puisque le micro est déjà géré à gauche.
  Widget _buildWideMessageField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _typedController,
            focusNode: _typedFocus,
            enabled: !_isListening && !_isBusy,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submitTyped(),
            decoration: InputDecoration(
              hintText: _isListening ? 'Listening…' : 'Type your question…',
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          icon: const Icon(Icons.send_rounded),
          tooltip: 'Send',
          onPressed: _isBusy ? null : _submitTyped,
        ),
      ],
    );
  }

  Widget _buildEmptyTranscript() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _mode == ConversationMode.offline
                  ? Icons.forum_outlined
                  : Icons.mic_none_rounded,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              switch (_mode) {
                ConversationMode.live =>
                  _language.isYoruba
                      ? 'Fọwọ́ kan gbohungbohun láti bẹ̀rẹ̀, kí o sì kí aláìsàn.'
                      : 'Tap the microphone to start the conversation, then '
                            'speak naturally: say hello to the patient.',
                ConversationMode.offline =>
                  _language.isYoruba
                      ? 'Kọ ìbéèrè rẹ ní Yorùbá. Aláìsàn yóò dáhùn láìsí intanẹẹti.'
                      : 'Offline mode: type your question. The patient answers '
                            'without a connection.',
              },
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// N'a plus de sens qu'en mode Live : c'est le bouton d'appel (démarrer /
  /// couper la conversation en temps réel). En mode hors ligne, le geste
  /// "parler" passe désormais par l'icône micro de la barre de saisie, voir
  /// [_buildMessageBar].
  VoidCallback? get _liveCallOnTap {
    if (_isBusy || _live.state == LiveState.connecting) return null;
    return _toggleLive;
  }

  IconData get _liveCallIcon =>
      _live.isActive ? Icons.stop_rounded : Icons.mic_none_rounded;

  Widget _buildControls() {
    final wide = _isWide(context);

    // Étape finale de l'entretien : QCM puis récapitulatif complet
    // (score, signaux d'alerte, fiche maladie). Désactivé tant qu'aucune
    // question n'a été posée, ou si ce scénario n'a pas encore de fiche
    // clinique.
    final diagnosisButton = FilledButton.icon(
      icon: const Icon(Icons.psychology_alt_outlined, size: 18),
      label: Text(_language.isYoruba ? 'Ṣe àyẹ̀wò' : 'Diagnosis'),
      onPressed: (_isBusy || _transcript.isEmpty || _clinicalData == null)
          ? null
          : _openDiagnosis,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _ContentWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seule l'action de diagnostic reste disponible pendant l'entretien.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (wide)
                  SizedBox(width: 180, child: diagnosisButton)
                else
                  Expanded(child: diagnosisButton),
              ],
            ),
            const SizedBox(height: 14),
            // Ligne 2 : bouton d'appel en mode Live, barre de saisie façon
            // messagerie (toujours visible) dans les autres modes.
            _mode == ConversationMode.live
                ? _buildLiveCallButton()
                : _buildMessageBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCallButton() {
    return _BigCircleButton(
      icon: _liveCallIcon,
      active: _live.isActive,
      showSpinner: _live.state == LiveState.connecting,
      onTap: _liveCallOnTap,
    );
  }

  /// Le mode hors ligne utilise le champ de saisie du panneau de droite.
  Widget _buildOfflineKeyboardIndicator() {
    return const Column(
      children: [
        Icon(Icons.keyboard_alt_outlined, size: 28),
        SizedBox(height: 8),
        Text('Text input only'),
      ],
    );
  }

  /// Barre de saisie façon messagerie (Messenger/WhatsApp) : un champ de
  /// texte toujours visible, et une seule icône à droite qui bascule
  /// avec un bouton d'envoi ; le mode hors ligne n'ouvre pas le micro.
  Widget _buildMessageBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _typedController,
            focusNode: _typedFocus,
            enabled: !_isListening && !_isBusy,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submitTyped(),
            decoration: InputDecoration(
              hintText: _language.isYoruba
                  ? 'Kọ ìbéèrè rẹ níbí…'
                  : 'Type your question…',
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Rebuild uniquement de l'icône à chaque frappe (le controller est
        // son propre ValueListenable) : pas besoin de setState ici.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _typedController,
          builder: (context, value, _) => _MessageBarAction(
            hasText: value.text.trim().isNotEmpty,
            listening: _isListening,
            busy: _isBusy,
            microphoneEnabled: _mode != ConversationMode.offline,
            onSend: _submitTyped,
            onMic: _recordAndSend,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Sous-widgets
// ---------------------------------------------------------------------

/// Marqueur d'en-tête de section dans la liste de scénarios groupée par
/// palier de difficulté (voir `_groupedScenarioItems`). Mélangé aux
/// `PatientScenario` dans une seule liste pour n'avoir qu'un seul
/// `SliverList` à gérer, plutôt qu'une sliver par palier.
class _DifficultyGroup {
  const _DifficultyGroup(this.label);
  final String label;
}

/// 0 = Easy, 1 = Medium, 2 = Hard. Accepte l'ancien vocabulaire français
/// (scénarios déjà synchronisés avant la traduction de l'UI) ; toute
/// valeur inconnue retombe sur Medium plutôt que de disparaître.
int _difficultyRank(String label) {
  switch (label) {
    case 'Easy':
    case 'Facile':
      return 0;
    case 'Hard':
    case 'Difficile':
      return 2;
    default:
      return 1;
  }
}

/// Regroupe les scénarios par palier (Easy, puis Medium, puis Hard),
/// chaque groupe non vide précédé d'un `_DifficultyGroup`. L'ordre relatif
/// des scénarios à l'intérieur d'un même palier est conservé.
List<Object> _groupedScenarioItems(
  List<PatientScenario> scenarios, {
  AppLanguage language = AppLanguage.english,
}) {
  final buckets = <int, List<PatientScenario>>{0: [], 1: [], 2: []};
  for (final s in scenarios) {
    final rank = _difficultyRank(_ScenarioVisuals.of(s.title).difficulty);
    buckets[rank]!.add(s);
  }
  final labels = language.isYoruba
      ? const {0: 'Rọrùn', 1: 'Lẹ́gbẹ̀ẹ́', 2: 'Líle'}
      : const {0: 'Easy', 1: 'Medium', 2: 'Hard'};
  final items = <Object>[];
  for (final rank in [0, 1, 2]) {
    final list = buckets[rank]!;
    if (list.isEmpty) continue;
    items.add(_DifficultyGroup(labels[rank]!));
    items.addAll(list);
  }
  return items;
}

/// `PatientScenario` (service) ne porte volontairement qu'un titre, une
/// description et un system prompt — l'icône, le niveau de difficulté et le
/// personnage animé sont un habillage purement visuel, déduits ici par titre.
/// Un scénario non reconnu retombe sur une valeur par défaut neutre, donc
/// ajouter un scénario côté service ne casse jamais l'écran.
///
/// Personnages disponibles (`PatientLook`) : child, elderly, man, woman,
/// womanMature. C'est ici qu'on choisit lequel incarne chaque scénario.
class _ScenarioVisuals {
  const _ScenarioVisuals(this.icon, this.difficulty, this.look);
  final IconData icon;
  final String difficulty;
  final PatientLook look;

  static const _byTitle = <String, _ScenarioVisuals>{
    // C'est la mère qui parle, pas l'enfant.
    'Fièvre chez un enfant': _ScenarioVisuals(
      Icons.child_care_rounded,
      'Easy',
      PatientLook.womanMature,
    ),
    'Saignement post-partum': _ScenarioVisuals(
      Icons.pregnant_woman_rounded,
      'Hard',
      PatientLook.woman,
    ),
    'Déshydratation': _ScenarioVisuals(
      Icons.water_drop_rounded,
      'Medium',
      PatientLook.man,
    ),
  };

  static const _fallback = _ScenarioVisuals(
    Icons.medical_information_rounded,
    'Medium',
    PatientLook.woman,
  );

  static _ScenarioVisuals of(String title) {
    final builtin = _byTitle[title];
    if (builtin != null) return builtin;
    final synced = ScenarioCatalog.instance.bundleForTitle(title);
    if (synced != null) {
      return _ScenarioVisuals(synced.icon, synced.difficulty, synced.look);
    }
    return _fallback;
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.language,
    required this.onTap,
  });
  final PatientScenario scenario;
  final AppLanguage language;
  final VoidCallback onTap;

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
      case 'Facile': // ancien vocabulaire (scénarios déjà synchronisés)
        return AppColors.success;
      case 'Hard':
      case 'Difficile':
        return const Color(0xFFDC2626);
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visuals = _ScenarioVisuals.of(scenario.title);
    final difficultyColor = _difficultyColor(visuals.difficulty);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Portrait fixe du patient (aucune animation dans la liste).
              PatientAvatar(
                look: visuals.look,
                mood: PatientMood.idle,
                size: 64,
                animate: false,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayTitle(scenario.title, language: language),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      language.isYoruba
                          ? 'Ìyá kan mú ọmọ ọdún mẹ́rin wá; ọmọ náà ti ní ibà fún ọjọ́ méjì.'
                          : scenario.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          label: Text(visuals.difficulty),
                          backgroundColor: difficultyColor.withValues(
                            alpha: 0.1,
                          ),
                          labelStyle: TextStyle(
                            color: difficultyColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        // Se met à jour tout seul quand une nouvelle
                        // session arrive (ScenarioScoreBoard est un
                        // ChangeNotifier), y compris hors ligne : voir
                        // scenario_score_board.dart.
                        ListenableBuilder(
                          listenable: ScenarioScoreBoard.instance,
                          builder: (context, _) {
                            final score = ScenarioScoreBoard.instance.scoreFor(
                              scenario.title,
                            );
                            if (score == null) return const SizedBox.shrink();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 15,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Best ${score.bestPercent}% · '
                                  '${score.attempts} '
                                  '${score.attempts > 1 ? 'tries' : 'try'}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.turn});
  final _Turn turn;

  @override
  Widget build(BuildContext context) {
    final isAgent = turn.isAgent;
    return Align(
      alignment: isAgent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          // 78 % de la largeur du contenu (borné à 720 px sur grand écran).
          maxWidth:
              (MediaQuery.sizeOf(context).width < _kContentMaxWidth
                  ? MediaQuery.sizeOf(context).width
                  : _kContentMaxWidth) *
              0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAgent ? AppColors.agentBubble : AppColors.patientBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAgent ? 16 : 4),
            bottomRight: Radius.circular(isAgent ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAgent ? '🧑‍⚕️ You' : '🤒 Patient',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(turn.text, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

/// Gros bouton rond réutilisé pour l'appel Live et pour le micro dédié du
/// panneau gauche en disposition "split" (mode hors ligne).
class _BigCircleButton extends StatelessWidget {
  const _BigCircleButton({
    required this.icon,
    required this.active,
    required this.onTap,
    this.showSpinner = false,
  });

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.secondary : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: active ? 4 : 0,
            ),
          ],
        ),
        child: showSpinner
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

/// Icône unique de la barre de saisie (façon Messenger) : micro tant que
/// le champ est vide, envoi dès qu'il contient du texte. Évite un bouton
/// séparé et le geste supplémentaire pour l'atteindre.
class _MessageBarAction extends StatelessWidget {
  const _MessageBarAction({
    required this.hasText,
    required this.listening,
    required this.busy,
    required this.microphoneEnabled,
    required this.onSend,
    required this.onMic,
  });

  final bool hasText;
  final bool listening;
  final bool busy;
  final bool microphoneEnabled;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final disabled = listening || busy || (!hasText && !microphoneEnabled);
    final color = listening ? AppColors.secondary : AppColors.primary;

    return GestureDetector(
      onTap: disabled
          ? null
          : (hasText ? onSend : (microphoneEnabled ? onMic : null)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: disabled ? color.withValues(alpha: 0.5) : color,
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  listening
                      ? Icons.graphic_eq_rounded
                      : hasText || !microphoneEnabled
                      ? Icons.send_rounded
                      : Icons.mic_rounded,
                  key: ValueKey(
                    listening
                        ? 'listening'
                        : hasText || !microphoneEnabled
                        ? 'send'
                        : 'mic',
                  ),
                  color: Colors.white,
                  size: 20,
                ),
              ),
      ),
    );
  }
}

/// Un item de navigation, partagé par la sidebar (grand écran) et le
/// tiroir (petit écran) : une icône, un libellé, l'action, et un éventuel
/// widget de fin (ex : un petit spinner pendant une synchronisation).
class _NavEntry {
  const _NavEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
}

/// En-tête commun à la sidebar et au tiroir : avatar + statut du compte.
/// Pas de vrai profil pour l'instant (nom, photo...) : ça arrivera avec
/// l'écran Profil dédié, ce bandeau sera alors mis à jour en conséquence.
class _NavHeader extends StatelessWidget {
  const _NavHeader({required this.dense});

  /// `true` dans le tiroir mobile (plus compact), `false` dans la sidebar.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final linked = user != null && !user.isAnonymous;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, dense ? 20 : 28, 20, 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  linked ? user.email ?? 'My account' : 'Guest session',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  linked ? 'Progress synced' : 'Progress saved on this device',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar permanente affichée à gauche sur grand écran (PC, tablette
/// paysage) : entièrement séparée du bandeau de description de l'app.
class _NavSidebar extends StatelessWidget {
  const _NavSidebar({required this.entries});
  final List<_NavEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kSidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _NavHeader(dense: false),
          const Divider(height: 1),
          const SizedBox(height: 8),
          for (final e in entries) _NavListTile(entry: e),
        ],
      ),
    );
  }
}

/// Tiroir de navigation sur petit écran, ouvert depuis le bouton menu de
/// l'AppBar (glisse depuis le bord, ne touche jamais au bandeau vert).
class _NavDrawer extends StatelessWidget {
  const _NavDrawer({required this.entries});
  final List<_NavEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _NavHeader(dense: true),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (final e in entries) _NavListTile(entry: e),
          ],
        ),
      ),
    );
  }
}

class _NavListTile extends StatelessWidget {
  const _NavListTile({required this.entry});
  final _NavEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(entry.icon, color: AppColors.primary),
      title: Text(entry.label),
      trailing:
          entry.trailing ??
          const Icon(Icons.chevron_right_rounded, color: Colors.black38),
      onTap: entry.onTap == null
          ? null
          : () {
              // Referme le tiroir avant de naviguer, sur mobile ; sans
              // effet sur la sidebar (pas de Drawer au-dessus).
              if (Scaffold.maybeOf(context)?.hasEndDrawer ?? false) {
                Navigator.of(context).maybePop();
              }
              entry.onTap!();
            },
    );
  }
}

class _Turn {
  _Turn(this.text, {required this.isAgent});
  final String text;
  final bool isAgent;
}
