import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import 'offline_whisper_api.dart';
import '../web_stt/web_offline_stt_types.dart';

class OfflineWhisperStt implements OfflineWhisper {
  static const _model = WhisperModel.tiny;
  static const _speechThresholdDb = -45.0;
  static const _initialSilenceTimeout = Duration(seconds: 8);
  static const _trailingSilenceTimeout = Duration(milliseconds: 1600);
  static const _maxRecordingDuration = Duration(seconds: 20);

  final AudioRecorder _recorder = AudioRecorder();
  final WhisperController _whisper = WhisperController();

  bool _disposed = false;

  @override
  Future<String> listenOnce({
    required String languageCode,
    void Function(OfflineWhisperStatus status)? onStatus,
  }) async {
    if (_disposed) {
      throw StateError('Offline Whisper speech recognition is disposed.');
    }
    if (!await _recorder.hasPermission()) {
      throw const OfflineSttException(
        'Microphone permission is required for offline speech recognition.',
      );
    }

    final modelPath = await _whisper.getPath(_model);
    if (!await File(modelPath).exists()) {
      onStatus?.call(OfflineWhisperStatus.downloadingModel);
      await _whisper.downloadModel(_model);
      if (!await File(modelPath).exists()) {
        throw const OfflineSttException(
          'The offline speech model could not be downloaded.',
        );
      }
    }

    final temporaryDirectory = await getTemporaryDirectory();
    final audioFile = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}'
      'offline-stt-${DateTime.now().microsecondsSinceEpoch}.wav',
    );

    var recordingStarted = false;
    try {
      onStatus?.call(OfflineWhisperStatus.listening);
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: audioFile.path,
      );
      recordingStarted = true;
      await _waitForSpeechToFinish();
      await _recorder.stop();
      recordingStarted = false;
      onStatus?.call(OfflineWhisperStatus.transcribing);
      final result = await _whisper.transcribe(
        model: _model,
        audioPath: audioFile.path,
        lang: languageCode,
        keepModelLoaded: true,
      );
      final transcript = result?.transcription.text.trim();
      if (transcript == null || transcript.isEmpty) {
        throw const OfflineSttException(
          'Whisper could not transcribe this recording. Please try again.',
        );
      }
      return transcript;
    } finally {
      if (recordingStarted && await _recorder.isRecording()) {
        await _recorder.stop();
      }
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    }
  }

  Future<void> _waitForSpeechToFinish() async {
    final startedAt = DateTime.now();
    DateTime? lastSpeechAt;
    final stopped = Completer<void>();
    late final StreamSubscription<Amplitude> subscription;
    subscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 250))
        .listen(
          (amplitude) {
            if (stopped.isCompleted) return;
            final now = DateTime.now();
            if (amplitude.current >= _speechThresholdDb) {
              lastSpeechAt = now;
            }

            final speechAt = lastSpeechAt;
            if (speechAt == null &&
                now.difference(startedAt) >= _initialSilenceTimeout) {
              stopped.completeError(
                const OfflineSttException(
                  'No speech detected. Tap the microphone and start speaking.',
                ),
              );
            } else if (speechAt != null &&
                now.difference(speechAt) >= _trailingSilenceTimeout) {
              stopped.complete();
            } else if (now.difference(startedAt) >= _maxRecordingDuration) {
              stopped.complete();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!stopped.isCompleted) {
              stopped.completeError(error, stackTrace);
            }
          },
        );
    try {
      await stopped.future;
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await _recorder.dispose();
    await _whisper.releaseModel();
  }
}
