import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'web_offline_stt_types.dart';

/// Langue de la reconnaissance : anglais (langue du concours).
const _lang = 'en-US';

/// `new SpeechRecognition()` du navigateur (API Web Speech). Seul Chrome /
/// Edge exposent les méthodes statiques `available` / `install` et la
/// propriété `processLocally` (reconnaissance sur l'appareil) : on teste
/// leur présence avant tout usage, voir [WebOfflineStt.isSupported].
@JS('SpeechRecognition')
extension type _SpeechRecognition._(JSObject _) implements JSObject {
  external _SpeechRecognition();

  external static JSPromise<JSAny?> available(_PackOptions options);
  external static JSPromise<JSAny?> install(_PackOptions options);

  external set lang(JSString value);
  external set continuous(JSBoolean value);
  external set interimResults(JSBoolean value);
  external set maxAlternatives(JSNumber value);
  external set processLocally(JSBoolean value);

  external set onresult(JSFunction? handler);
  external set onerror(JSFunction? handler);
  external set onend(JSFunction? handler);

  external void start();
  external void stop();
  external void abort();
}

/// `{ langs: ['en-US'], processLocally: true }`
@JS()
@anonymous
extension type _PackOptions._(JSObject _) implements JSObject {
  external factory _PackOptions({
    required JSArray<JSString> langs,
    required JSBoolean processLocally,
  });
}

_PackOptions _options() =>
    _PackOptions(langs: <JSString>[_lang.toJS].toJS, processLocally: true.toJS);

/// Reconnaissance vocale sur l'appareil, via l'API de Chrome.
///
/// Fonctionne sans réseau UNIQUEMENT si le pack de langue a été téléchargé
/// une fois auparavant (voir [installLanguagePack]). L'API est encore
/// expérimentale : Chrome/Edge de bureau seulement, et le comportement peut
/// varier d'une version à l'autre.
class WebOfflineStt {
  /// Le navigateur expose-t-il l'API locale ? (Ne dit pas si le pack de
  /// langue est installé : voir [status].)
  bool get isSupported {
    final global = globalContext;
    if (!global.has('SpeechRecognition')) return false;
    final ctor = global['SpeechRecognition'];
    if (ctor == null || !ctor.isA<JSObject>()) return false;
    final obj = ctor as JSObject;
    return obj.has('available') && obj.has('install');
  }

  Future<OfflineSttStatus> status() async {
    if (!isSupported) {
      print('[STT] status: API non supportée par ce navigateur');
      return OfflineSttStatus.unsupported;
    }
    try {
      final result = await _SpeechRecognition.available(_options()).toDart;
      final raw = (result as JSString?)?.toDart;
      print('[STT] available() -> $raw');
      switch (raw) {
        case 'available':
          return OfflineSttStatus.ready;
        case 'downloadable':
          return OfflineSttStatus.needsDownload;
        case 'downloading':
          return OfflineSttStatus.downloading;
        default:
          return OfflineSttStatus.unavailable;
      }
    } catch (e) {
      print('[STT] available() a échoué: $e');
      return OfflineSttStatus.unsupported;
    }
  }

  Future<bool> installLanguagePack() async {
    if (!isSupported) {
      print('[STT] install: API non supportée');
      return false;
    }
    try {
      final result = await _SpeechRecognition.install(_options()).toDart;
      final ok = (result as JSBoolean?)?.toDart ?? false;
      print('[STT] install() -> $ok');
      return ok;
    } catch (e) {
      print('[STT] install() a échoué: $e');
      return false;
    }
  }

  /// Écoute une phrase et renvoie le texte reconnu ('' si rien n'a été dit).
  /// Lève une [OfflineSttException] au message lisible si la reconnaissance
  /// locale n'est pas utilisable (navigateur, pack manquant, micro refusé).
  Future<String> listenOnce({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    switch (await status()) {
      case OfflineSttStatus.ready:
        break;
      case OfflineSttStatus.needsDownload:
      case OfflineSttStatus.downloading:
        throw const OfflineSttException(
          'The offline English voice pack is not installed yet. Connect to '
          'the internet once and download it (switch to offline mode to '
          'get the download button).',
        );
      case OfflineSttStatus.unsupported:
        throw const OfflineSttException(
          'Offline speech recognition is not available in this browser '
          '(Chrome or Edge on desktop is needed). Use the keyboard button.',
        );
      case OfflineSttStatus.unavailable:
        throw const OfflineSttException(
          'Offline English speech recognition is not available on this '
          'device. Use the keyboard button.',
        );
    }

    final completer = Completer<String>();
    var transcript = '';

    final recognition = _SpeechRecognition();
    recognition.lang = _lang.toJS;
    recognition.continuous = false.toJS;
    recognition.interimResults = true.toJS;
    recognition.maxAlternatives = 1.toJS;
    // C'est CETTE ligne qui garde l'audio sur l'appareil : sans elle,
    // Chrome enverrait la voix à un serveur et échouerait hors ligne.
    recognition.processLocally = true.toJS;

    recognition.onresult = ((JSObject event) {
      final results = event.getProperty<JSObject>('results'.toJS);
      final count = results.getProperty<JSNumber>('length'.toJS).toDartInt;
      final buffer = StringBuffer();
      for (var i = 0; i < count; i++) {
        final result = results.getProperty<JSObject>(i.toJS);
        final best = result.getProperty<JSObject>(0.toJS);
        buffer.write(best.getProperty<JSString>('transcript'.toJS).toDart);
      }
      transcript = buffer.toString();
    }).toJS;

    recognition.onerror = ((JSObject event) {
      final code = (event['error'] as JSString?)?.toDart ?? 'unknown';
      if (completer.isCompleted) return;
      switch (code) {
        case 'no-speech':
        case 'aborted':
          completer.complete(transcript.trim());
        case 'not-allowed':
        case 'service-not-allowed':
          completer.completeError(
            const OfflineSttException(
              'Microphone access was denied. Allow it in the browser and '
              'try again.',
            ),
          );
        case 'audio-capture':
          completer.completeError(
            const OfflineSttException('No microphone was found.'),
          );
        case 'language-not-supported':
          completer.completeError(
            const OfflineSttException(
              'The offline English voice pack is not installed. Connect '
              'once and download it.',
            ),
          );
        default:
          completer.completeError(
            OfflineSttException('Speech recognition failed ($code).'),
          );
      }
    }).toJS;

    recognition.onend = (() {
      if (!completer.isCompleted) completer.complete(transcript.trim());
    }).toJS;

    final stopTimer = Timer(timeout, () {
      try {
        recognition.stop();
      } catch (_) {}
    });

    try {
      recognition.start();
    } catch (e) {
      stopTimer.cancel();
      throw OfflineSttException('Could not start listening: $e');
    }

    try {
      // Filet de sécurité : si `onend` ne se déclenche jamais, on rend le
      // texte déjà reconnu au lieu de bloquer l'écran.
      return await completer.future.timeout(
        timeout + const Duration(seconds: 3),
        onTimeout: () => transcript.trim(),
      );
    } finally {
      stopTimer.cancel();
    }
  }
}
