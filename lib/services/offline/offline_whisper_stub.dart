import 'offline_whisper_api.dart';

class OfflineWhisperStt implements OfflineWhisper {
  @override
  Future<String> listenOnce({
    required String languageCode,
    void Function(OfflineWhisperStatus status)? onStatus,
    void Function(double? progress)? onDownloadProgress,
  }) {
    throw UnsupportedError(
      'On-device Whisper speech recognition is not available on this platform.',
    );
  }

  @override
  Future<void> dispose() async {}
}
