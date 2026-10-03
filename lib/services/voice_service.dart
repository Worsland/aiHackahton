import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import 'web_stt/web_offline_stt.dart';

/// Voix native du téléphone : gratuite, fonctionne même en zone
/// à faible connectivité (contrairement à une API TTS/STT cloud).
/// Pour une voix plus réaliste "patient virtuel", tu peux remplacer
/// speak() par un appel à l'API ElevenLabs si tu as du réseau le jour J.
class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttReady = false;

  // Dans speech_to_text 7.x, les erreurs se signalent via le callback
  // `onError` d'`initialize()` (pas de `listen()`) : elles arrivent donc de
  // façon asynchrone, indépendamment de l'appel en cours. On les range ici
  // et `listenOnce` regarde ce champ après sa propre écoute.
  String? _lastErrorCode;

  // Dernier statut reçu du moteur natif ('listening', 'notListening', 'done').
  String? _lastStatus;

  // Complété quand la session d'écoute est réellement terminée (résultat
  // final, statut done/notListening, ou erreur). Remplace l'ancienne boucle
  // `while (_stt.isListening)` qui sortait immédiatement : `listen()` rend
  // la main avant que le moteur natif ne soit réellement démarré, donc
  // `isListening` valait encore `false` et la fonction se terminait aussitôt.
  Completer<void>? _sessionDone;

  /// Reconnaissance locale du navigateur (Chrome/Edge). N'est utilisée que
  /// sur le web ET en mode hors ligne : `speech_to_text` n'expose pas
  /// l'API locale du navigateur, voir `web_stt/`.
  final WebOfflineStt _webOffline = WebOfflineStt();

  Future<OfflineSttStatus> webOfflineSttStatus() => _webOffline.status();

  /// Télécharge le pack de langue anglais (une fois, réseau requis).
  Future<bool> downloadWebOfflineSttPack() => _webOffline.installLanguagePack();

  void _completeSession() {
    final c = _sessionDone;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Initialise le moteur STT avec les callbacks d'erreur et de statut.
  Future<bool> _initStt() {
    return _stt.initialize(
      onError: (error) {
        _lastErrorCode = error.errorMsg;
        debugPrint(
          '🎤 STT onError: ${error.errorMsg} permanent=${error.permanent}',
        );
        _completeSession();
      },
      onStatus: (status) {
        _lastStatus = status;
        debugPrint('🎤 STT status: $status');
        // 'done' / 'notListening' = le moteur a fini d'écouter.
        if (status == 'done' || status == 'notListening') {
          _completeSession();
        }
      },
      // Logs détaillés du plugin natif (device/OS, moteur utilisé, raison
      // exacte d'un arrêt...) dans la console `flutter run` — le seul
      // moyen de voir ce qui se passe vraiment quand aucune erreur propre
      // ne remonte via `onError`.
      debugLogging: true,
    );
  }

  Future<void> init() async {
    await Permission.microphone.request();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await Permission.speech.request();
    }
    _sttReady = await _initStt();
    debugPrint('🎤 STT initialize() -> ready=$_sttReady');

    // Utile pour le débogage hors ligne : vérifie que en_US est bien listé.
    if (_sttReady) {
      try {
        final locales = await _stt.locales();
        final hasEnUs = locales.any(
          (l) => l.localeId.replaceAll('-', '_').toLowerCase() == 'en_us',
        );
        debugPrint(
          '🎤 STT locales: ${locales.length} disponibles, en_US présent=$hasEnUs',
        );
      } catch (e) {
        debugPrint('🎤 STT locales() a échoué : $e');
      }
    }

    await _tts.setLanguage('en-US'); // langue du concours : anglais
    await _tts.setSpeechRate(0.48); // un peu plus lent = plus clair à l'oral
    // speak() ne rend la main qu'à la FIN de la phrase : l'écran s'en sert
    // pour animer la bouche du patient pendant toute la durée de sa réponse.
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();

  /// Écoute et renvoie le texte transcrit une fois que l'utilisateur
  /// a fini de parler (silence détecté).
  ///
  /// [onDevice] force la reconnaissance locale au téléphone (nécessaire en
  /// mode hors ligne). Sans connexion, la plupart des moteurs cloud
  /// échouent silencieusement : mieux vaut demander explicitement le
  /// modèle embarqué plutôt que d'attendre un délai pour rien. Le modèle
  /// local est généralement moins précis, en particulier sur des noms
  /// médicaux ou une langue peu courante.
  Future<String> listenOnce({bool onDevice = false}) async {
    // Web + hors ligne : le navigateur envoie sinon l'audio à un serveur
    // (l'option `onDevice` de speech_to_text n'a pas d'effet sur le web).
    // Peut lever une OfflineSttException au message lisible.
    if (kIsWeb && onDevice) {
      return _webOffline.listenOnce();
    }

    if (!_sttReady) {
      _sttReady = await _initStt();
      if (!_sttReady) return '';
    }

    // Si une écoute précédente traîne encore, on l'arrête proprement.
    if (_stt.isListening) {
      await _stt.stop();
    }

    // Repart de zéro à chaque écoute : sinon une erreur ou un statut d'une
    // tentative précédente pourrait être lu par erreur comme appartenant
    // à celle-ci.
    _lastErrorCode = null;
    _lastStatus = null;
    final session = Completer<void>();
    _sessionDone = session;
    String result = '';
    debugPrint('🎤 STT listenOnce(onDevice: $onDevice) — démarrage');

    await _stt.listen(
      onResult: (res) {
        result = res.recognizedWords;
        debugPrint(
          '🎤 STT onResult: "${res.recognizedWords}" '
          'final=${res.finalResult} confidence=${res.confidence}',
        );
        if (res.finalResult) _completeSession();
      },
      localeId: 'en_US', // reconnaissance vocale en anglais
      listenOptions: stt.SpeechListenOptions(
        onDevice: onDevice,
        // Le mode par défaut d'Android considère souvent qu'il n'y a "pas
        // de parole" après à peine 1-2 secondes de silence, avant même que
        // l'utilisateur ait commencé à parler. Le mode dictée est plus
        // patient sur ce délai initial.
        listenMode: stt.ListenMode.dictation,
      ),
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 5),
    );

    // Attend la vraie fin de session (résultat final, statut done, erreur),
    // avec un garde-fou légèrement supérieur à listenFor.
    await session.future.timeout(
      const Duration(seconds: 25),
      onTimeout: () {
        debugPrint('🎤 STT garde-fou : timeout d\'attente atteint');
      },
    );

    // Laisse une chance à un résultat final ou à une erreur tardive d'arriver
    // (ils peuvent suivre de peu le statut 'done').
    await Future.delayed(const Duration(milliseconds: 400));

    // S'assure que le moteur est bien arrêté avant de rendre la main.
    if (_stt.isListening) {
      await _stt.stop();
    }
    _sessionDone = null;

    debugPrint(
      '🎤 STT listenOnce terminé : result="$result" '
      'isListening=${_stt.isListening} status=$_lastStatus '
      'errorCode=$_lastErrorCode',
    );

    // Rien de reconnu ET une erreur explicite : on prévient plutôt que de
    // rendre une chaîne vide muette, qui ressemblait à un micro capricieux.
    if (result.trim().isEmpty && _lastErrorCode != null) {
      throw OfflineSttException(
        _describeError(_lastErrorCode!, onDevice: onDevice),
      );
    }

    return result;
  }

  String _describeError(String code, {required bool onDevice}) {
    switch (code) {
      case 'error_no_match':
        return "Didn't catch that. Try speaking right after tapping the "
            'microphone, a bit closer and louder.';
      case 'error_speech_timeout':
        return 'No speech detected. Tap the microphone again and start '
            'talking straight away.';
      case 'error_language_unavailable':
      case 'error_language_not_supported':
        return 'The English offline speech pack is not installed on this '
            "phone ($code). Install it in your phone's voice settings "
            '(Google app > Settings > Voice > Offline speech recognition > '
            'English (US)), or use the keyboard instead.';
      case 'error_network':
      case 'error_network_timeout':
      case 'error_server':
        if (onDevice) {
          return 'Offline speech recognition could not start ($code). '
              'Check that the English offline language pack is installed, '
              'or use the keyboard instead.';
        }
        return 'Network problem during speech recognition ($code). '
            'Switch to offline mode or use the keyboard instead.';
      default:
        if (onDevice) {
          return 'Offline speech recognition is not available on this '
              "phone ($code). Check that an offline language pack for "
              "English is installed on the device (in your phone's voice "
              'assistant / Google app settings, under offline speech '
              'recognition), or use the keyboard instead.';
        }
        return 'Speech recognition failed ($code). Use the keyboard instead.';
    }
  }

  void dispose() {
    _completeSession();
    _stt.stop();
    _tts.stop();
  }
}
