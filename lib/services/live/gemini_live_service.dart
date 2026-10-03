import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'audio/pcm_player_factory.dart';
import 'audio/pcm_player_service.dart';
import 'mic_capture_stub.dart'
    if (dart.library.js_interop) 'mic_capture_web.dart'
    if (dart.library.io) 'mic_capture_mobile.dart';

enum LiveState { idle, connecting, live, error }

/// Appelé à chaque fois qu'un tour de parole est terminé.
/// [isAgent] = true : c'est l'agent de santé (l'utilisateur) qui a parlé ;
/// false : c'est le patient virtuel (Gemini).
typedef LiveTurnCallback = void Function(String text, {required bool isAgent});

/// Conversation vocale en temps réel avec le patient virtuel, via l'API
/// Gemini Live (WebSocket audio natif).
///
/// Adapté de `GeminiVoiceService` (assistant étudiant), avec :
///  - le prompt du scénario comme rôle du patient ;
///  - la transcription des deux côtés (pour afficher le chat et fournir
///    l'historique au feedback final) ;
///  - un niveau de bouche ([mouthLevel]) calé sur l'audio réellement joué,
///    pour animer l'avatar ;
///  - des états fins ([patientSpeaking], [agentSpeaking], [waitingReply])
///    pour piloter les poses de l'avatar.
///
/// Les changements d'état discrets passent par [notifyListeners] ;
/// [mouthLevel] est un ValueNotifier à part car il change ~25 fois/s.
class GeminiLiveService extends ChangeNotifier {
  GeminiLiveService({required this.apiKey, this.model = defaultModel});

  /// Modèle Live stable en septembre 2026. Le nom change vite : c'est le
  /// premier endroit à vérifier si la connexion est refusée.
  static const defaultModel = 'gemini-3.8-live';

  static const _wsBase =
      'wss://generativelanguage.googleapis.com/ws/'
      'google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';

  static const _playbackRate = 24000; // Hz, sortie de Gemini
  static const _speechThreshold = 0.02; // RMS micro au-dessus = l'agent parle
  static const _agentHoldMs = 600; // maintien après la dernière voix détectée

  static const _voiceRules = '''
VOICE RULES (follow at all times):
- You are the patient, speaking out loud to a health worker. Never step out
  of your role and never say that you are an artificial intelligence.
- Do not speak first: wait for the health worker to greet you or ask you a
  question.
- Answer in one to three short sentences, the way people speak. No lists, no
  stage directions in parentheses.
- Always answer in English.
- Stay realistic and incomplete: only give a piece of information if the
  question being asked calls for it.
''';

  final String apiKey;
  final String model;

  /// Reçoit chaque tour de parole terminé (agent ou patient).
  LiveTurnCallback? onTurn;

  /// Reçoit un message lisible quand la connexion échoue ou se coupe.
  void Function(String message)? onError;

  // ── État exposé à l'UI ─────────────────────────────────────────────────────
  LiveState _state = LiveState.idle;
  bool _patientSpeaking = false;
  bool _agentSpeaking = false;
  bool _waitingReply = false;

  LiveState get state => _state;
  bool get isActive =>
      _state == LiveState.live || _state == LiveState.connecting;
  bool get isLive => _state == LiveState.live;

  /// Le patient est en train de parler (audio en cours de lecture).
  bool get patientSpeaking => _patientSpeaking;

  /// L'agent est en train de parler (détecté sur le niveau du micro).
  bool get agentSpeaking => _agentSpeaking;

  /// L'agent vient de finir sa phrase, le patient n'a pas encore répondu.
  bool get waitingReply => _waitingReply;

  /// Ouverture de la bouche du patient, 0 (fermée) à 1 (grande ouverte).
  final ValueNotifier<double> mouthLevel = ValueNotifier(0);

  // ── Connexion / audio ──────────────────────────────────────────────────────
  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _sub;
  Completer<void>? _setupDone;
  final PcmPlayerService _player = createPcmPlayer();
  final MicCapture _mic = MicCapture();
  final Stopwatch _clock = Stopwatch()..start();
  Timer? _ticker;
  bool _disposed = false;

  // ── Lecture : frise temporelle pour caler la bouche sur l'audio ───────────
  // Gemini génère l'audio plus vite que le temps réel : les chunks arrivent
  // en avance, on estime donc l'instant où chacun sera réellement joué.
  final ListQueue<_EnvelopePoint> _envelope = ListQueue();
  double _playheadEndMs = 0;
  bool _turnComplete = true;
  bool _dropIncoming = false; // après une interruption manuelle

  // ── Détection de la voix de l'agent ────────────────────────────────────────
  double _agentSpeakingUntilMs = 0;
  bool _agentSpoke = false;
  double _waitingSinceMs = 0;

  // ── Transcriptions ─────────────────────────────────────────────────────────
  final StringBuffer _inBuf = StringBuffer();
  final StringBuffer _outBuf = StringBuffer();

  // ===========================================================================
  // Cycle de vie
  // ===========================================================================

  /// Ouvre la session et démarre le micro. Retourne `true` si le patient est
  /// prêt à écouter, `false` sinon (le détail est passé à [onError]).
  Future<bool> start({
    required String systemPrompt,
    String voiceName = 'Aoede',
  }) async {
    if (isActive) return true;
    await _teardownInFlight; // un arrêt précédent peut encore se terminer
    _setState(LiveState.connecting);
    _resetConversationState();

    final setupDone = Completer<void>();
    _setupDone = setupDone;

    try {
      await _player.setup(sampleRate: _playbackRate);

      final channel = WebSocketChannel.connect(Uri.parse('$_wsBase?key=$apiKey'));
      _ws = channel;
      await channel.ready;

      _sub = channel.stream.listen(
        _onMessage,
        onError: (Object e) => _fail('Connection lost ($e)'),
        onDone: _onClosed,
      );

      channel.sink.add(jsonEncode(_setupMessage(systemPrompt, voiceName)));
      await setupDone.future.timeout(const Duration(seconds: 10));

      await _mic.start(_onMicChunk);
      _ticker = Timer.periodic(const Duration(milliseconds: 40), (_) => _tick());
      _setState(LiveState.live);
      return true;
    } on TimeoutException {
      _fail('The patient is not responding (timed out). Check your connection.');
    } catch (e) {
      _fail('Could not start the conversation: $e');
    }
    return false;
  }

  /// Termine proprement la conversation.
  Future<void> stop() async {
    if (_state == LiveState.idle) return;
    _flushAgentTranscript();
    _flushPatientTranscript();
    await _teardown();
    _setState(LiveState.idle);
  }

  /// Coupe la parole du patient (l'agent le trouve trop bavard).
  /// On n'envoie rien au serveur : on arrête la lecture locale et on ignore
  /// la fin de la réponse en cours. Dès que l'agent reparle, Gemini prend le
  /// relais normalement.
  void interrupt() {
    if (_state != LiveState.live || !_patientSpeaking) return;
    // Si le serveur a déjà terminé son tour, il n'y a plus rien à ignorer :
    // ne pas lever ce drapeau, sinon on avalerait la réponse suivante.
    if (!_turnComplete) _dropIncoming = true;
    _clearPlayback();
    _flushPatientTranscript();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_teardown());
    mouthLevel.dispose();
    super.dispose();
  }

  Future<void>? _teardownInFlight;

  Future<void> _teardown() {
    // Partie synchrone : on coupe tout de suite l'horloge et les états.
    _ticker?.cancel();
    _ticker = null;
    _resetConversationState();
    final sub = _sub;
    final ws = _ws;
    _sub = null;
    _ws = null;
    // Partie asynchrone : libération du micro, du lecteur et du socket.
    return _teardownInFlight = () async {
      try {
        await sub?.cancel();
        await _mic.stop();
        await _player.release();
        await ws?.sink.close();
      } catch (e) {
        debugPrint('⚠️ teardown: $e');
      }
    }();
  }

  void _resetConversationState() {
    _envelope.clear();
    _playheadEndMs = 0;
    _turnComplete = true;
    _dropIncoming = false;
    _agentSpeakingUntilMs = 0;
    _agentSpoke = false;
    _patientSpeaking = false;
    _agentSpeaking = false;
    _waitingReply = false;
    _inBuf.clear();
    _outBuf.clear();
    _setMouth(0);
  }

  void _fail(String message) {
    debugPrint('❌ Live: $message');
    if (_state == LiveState.error || _state == LiveState.idle) return;
    final done = _setupDone;
    if (done != null && !done.isCompleted) done.completeError(message);
    unawaited(_teardown());
    _setState(LiveState.error);
    onError?.call(message);
  }

  void _onClosed() {
    if (_state == LiveState.idle || _state == LiveState.error) return;
    final code = _ws?.closeCode;
    final reason = _ws?.closeReason;
    debugPrint('❌ Live: WebSocket fermé (code=$code, raison=$reason)');
    _fail(
      'The patient hung up'
      '${reason != null && reason.isNotEmpty ? ': $reason' : ''}.',
    );
  }

  // ===========================================================================
  // Messages sortants
  // ===========================================================================

  Map<String, dynamic> _setupMessage(String systemPrompt, String voiceName) {
    return {
      'setup': {
        'model': 'models/$model',
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {'voiceName': voiceName},
            },
          },
        },
        'systemInstruction': {
          'parts': [
            {'text': '$systemPrompt\n\n$_voiceRules'},
          ],
        },
        // Transcription des deux côtés : indispensable pour le chat à l'écran
        // et pour l'historique envoyé au feedback final.
        'inputAudioTranscription': <String, dynamic>{},
        'outputAudioTranscription': <String, dynamic>{},
      },
    };
  }

  void _onMicChunk(Uint8List data) {
    final ws = _ws;
    if (_state != LiveState.live || ws == null) return;

    // Mobile : demi-duplex. Le micro reste muet pendant que le patient parle,
    // pour éviter qu'il s'entende lui-même (écho). Sur le web, l'AEC du
    // navigateur gère ça et on envoie toujours.
    if (!kIsWeb && _patientSpeaking) return;

    if (!_patientSpeaking) {
      final now = _clock.elapsedMilliseconds.toDouble();
      if (_rmsBytes(data) > _speechThreshold) {
        _agentSpeakingUntilMs = now + _agentHoldMs;
        _agentSpoke = true;
        _dropIncoming = false; // l'agent reparle : on n'ignore plus rien
        if (!_agentSpeaking) {
          _agentSpeaking = true;
          _waitingReply = false;
          _notify();
        }
      }
    }

    ws.sink.add(
      jsonEncode({
        'realtimeInput': {
          'audio': {
            'data': base64Encode(data),
            'mimeType': 'audio/pcm;rate=16000',
          },
        },
      }),
    );
  }

  // ===========================================================================
  // Messages entrants
  // ===========================================================================

  void _onMessage(dynamic raw) {
    if (_disposed) return;
    final String text;
    if (raw is String) {
      text = raw;
    } else if (raw is List<int>) {
      text = utf8.decode(raw);
    } else {
      return;
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    if (json.containsKey('setupComplete')) {
      final done = _setupDone;
      if (done != null && !done.isCompleted) done.complete();
      return;
    }
    if (json.containsKey('goAway')) {
      debugPrint('⚠️ Live: goAway ${json['goAway']}');
    }

    final content = json['serverContent'];
    if (content is! Map) return;

    // Transcription de l'agent (fragments, sans ordre garanti avec le reste).
    final inT = content['inputTranscription'];
    if (inT is Map && inT['text'] is String) _inBuf.write(inT['text']);

    // Audio du patient.
    final modelTurn = content['modelTurn'];
    if (modelTurn is Map && modelTurn['parts'] is List) {
      for (final part in modelTurn['parts'] as List) {
        if (part is! Map) continue;
        final inline = part['inlineData'];
        if (inline is Map && inline['data'] is String) {
          _onPatientAudio(inline['data'] as String);
        }
      }
    }

    // Transcription du patient.
    final outT = content['outputTranscription'];
    if (outT is Map && outT['text'] is String) {
      _flushAgentTranscript();
      if (!_dropIncoming) _outBuf.write(outT['text']);
    }

    if (content['interrupted'] == true) _onServerInterrupted();
    if (content['turnComplete'] == true) _onTurnComplete();
  }

  void _onPatientAudio(String base64Audio) {
    // Le patient commence à répondre : la question de l'agent est terminée.
    _flushAgentTranscript();
    if (_dropIncoming) return;

    if (_turnComplete) {
      _turnComplete = false;
      _waitingReply = false;
    }

    final bytes = base64Decode(base64Audio);
    final samples = bytes.buffer.asInt16List(
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 2,
    );
    if (samples.isEmpty) return;

    // Quand ce chunk sera-t-il réellement joué ? Juste après le précédent.
    final nowMs = _clock.elapsedMilliseconds.toDouble();
    final startMs = math.max(nowMs, _playheadEndMs);
    const window = _playbackRate ~/ 20; // fenêtres de 50 ms
    for (var i = 0; i < samples.length; i += window) {
      final end = math.min(i + window, samples.length);
      var sum = 0.0;
      for (var j = i; j < end; j++) {
        final s = samples[j] / 32768.0;
        sum += s * s;
      }
      final rms = math.sqrt(sum / (end - i));
      // Courbe douce : les syllabes ouvrent la bouche, les pauses la ferment.
      final level = math.pow((rms / 0.18).clamp(0.0, 1.0), 0.7).toDouble();
      _envelope.add(_EnvelopePoint(startMs + i * 1000 / _playbackRate, level));
    }
    _playheadEndMs = startMs + samples.length * 1000 / _playbackRate;

    if (!_patientSpeaking) {
      _patientSpeaking = true;
      _agentSpeaking = false;
      _notify();
    }

    _player.feed(samples).catchError((Object e) {
      debugPrint('❌ Audio feed error: $e');
    });
  }

  void _onTurnComplete() {
    _turnComplete = true;
    _dropIncoming = false;
    _flushPatientTranscript();
  }

  void _onServerInterrupted() {
    _clearPlayback();
    _turnComplete = true;
    _dropIncoming = false;
    _flushPatientTranscript();
    _notify();
  }

  /// Arrête immédiatement la lecture du patient et vide le buffer audio.
  void _clearPlayback() {
    _envelope.clear();
    _playheadEndMs = _clock.elapsedMilliseconds.toDouble();
    _patientSpeaking = false;
    _setMouth(0);
    // Le lecteur PCM n'a pas de "flush" : release + setup vide son buffer
    // (même méthode que dans l'assistant étudiant).
    unawaited(() async {
      try {
        await _player.release();
        if (_state == LiveState.live) {
          await _player.setup(sampleRate: _playbackRate);
        }
      } catch (e) {
        debugPrint('❌ clearPlayback: $e');
      }
    }());
  }

  // ===========================================================================
  // Horloge : bouche, fin de parole, détection de silence
  // ===========================================================================

  void _tick() {
    if (_disposed) return;
    final now = _clock.elapsedMilliseconds.toDouble();

    // Bouche : on consomme la frise au rythme réel de la lecture.
    double? level;
    while (_envelope.isNotEmpty && _envelope.first.timeMs <= now) {
      level = _envelope.removeFirst().level;
    }
    if (level != null) {
      _setMouth(level);
    } else if (_envelope.isEmpty && now > _playheadEndMs) {
      _setMouth(0);
    }

    // Fin de parole du patient : le serveur a fini ET l'audio est épuisé
    // (ou plus aucun chunk depuis 4 s, par sécurité).
    if (_patientSpeaking &&
        now > _playheadEndMs + 250 &&
        (_turnComplete || now > _playheadEndMs + 4000)) {
      _patientSpeaking = false;
      _notify();
    }

    // Fin de parole de l'agent : le patient "réfléchit" avant de répondre.
    if (_agentSpeaking && now > _agentSpeakingUntilMs) {
      _agentSpeaking = false;
      if (_agentSpoke && !_patientSpeaking) {
        _waitingReply = true;
        _waitingSinceMs = now;
      }
      _agentSpoke = false;
      _notify();
    }

    // Sécurité : pas de "réflexion" infinie si le patient ne répond pas.
    if (_waitingReply && now > _waitingSinceMs + 10000) {
      _waitingReply = false;
      _notify();
    }
  }

  // ===========================================================================
  // Transcriptions
  // ===========================================================================

  void _flushAgentTranscript() {
    final text = _inBuf.toString().trim();
    _inBuf.clear();
    if (text.isNotEmpty) onTurn?.call(text, isAgent: true);
  }

  void _flushPatientTranscript() {
    final text = _outBuf.toString().trim();
    _outBuf.clear();
    if (text.isNotEmpty) onTurn?.call(text, isAgent: false);
  }

  // ===========================================================================
  // Utilitaires
  // ===========================================================================

  void _setState(LiveState s) {
    _state = s;
    _notify();
  }

  void _setMouth(double v) {
    if (_disposed) return;
    if (mouthLevel.value != v) mouthLevel.value = v;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static double _rmsBytes(Uint8List b) {
    final n = b.lengthInBytes ~/ 2;
    if (n == 0) return 0;
    final data = ByteData.sublistView(b);
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      final s = data.getInt16(i * 2, Endian.little) / 32768.0;
      sum += s * s;
    }
    return math.sqrt(sum / n);
  }
}

class _EnvelopePoint {
  _EnvelopePoint(this.timeMs, this.level);
  final double timeMs;
  final double level;
}
