enum OfflineWhisperStatus { downloadingModel, listening, transcribing }

abstract interface class OfflineWhisper {
  Future<String> listenOnce({
    required String languageCode,
    void Function(OfflineWhisperStatus status)? onStatus,
    void Function(double? progress)? onDownloadProgress,
  });

  Future<void> dispose();
}
