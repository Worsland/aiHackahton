import 'web_offline_stt_types.dart';

/// Version pour Android/iOS/desktop : ces plateformes ont déjà leur
/// reconnaissance locale via `speech_to_text` (`onDevice: true`), ce pont
/// navigateur ne sert à rien ici.
class WebOfflineStt {
  bool get isSupported => false;

  Future<OfflineSttStatus> status() async => OfflineSttStatus.unsupported;

  Future<bool> installLanguagePack() async => false;

  Future<String> listenOnce({
    Duration timeout = const Duration(seconds: 20),
  }) async => throw const OfflineSttException(
    'On-device browser speech recognition is only used on the web.',
  );
}
