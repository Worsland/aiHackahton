import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:record/record.dart';

typedef AudioChunkCallback = void Function(Uint8List chunk);

class MicCapture {
  final AudioRecorder _recorder = AudioRecorder();
  bool _active = false;

  Future<void> start(AudioChunkCallback onChunk) async {
    // ── iOS : AVAudioSession mode voiceChat → AEC hardware Apple ────────────
    await webrtc.Helper.setAppleAudioConfiguration(
      webrtc.AppleAudioConfiguration(
        appleAudioCategory: webrtc.AppleAudioCategory.playAndRecord,
        appleAudioCategoryOptions: {
          webrtc.AppleAudioCategoryOption.allowBluetooth,
          webrtc.AppleAudioCategoryOption.allowBluetoothA2DP,
          webrtc.AppleAudioCategoryOption.defaultToSpeaker,
        },
        appleAudioMode: webrtc.AppleAudioMode.videoChat, // ← AEC iOS
      ),
    );

    // ── Android : MODE_IN_COMMUNICATION → AEC hardware Android ──────────────
    // On utilise le constructeur minimal documenté (2 paramètres seulement)
    await webrtc.Helper.setAndroidAudioConfiguration(
      webrtc.AndroidAudioConfiguration(
        androidAudioMode: webrtc.AndroidAudioMode.inCommunication,
        androidAudioFocusMode: webrtc.AndroidAudioFocusMode.gain,
      ),
    );

    // ── Capture PCM via package:record ───────────────────────────────────────
    if (!await _recorder.hasPermission()) {
      throw Exception('Microphone permission denied');
    }

    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );

    final stream = await _recorder.startStream(config);
    _active = true;
    stream.listen((chunk) {
      if (_active) onChunk(chunk);
    });
  }

  Future<void> stop() async {
    _active = false;
    if (await _recorder.isRecording()) await _recorder.stop();

    // Remettre iOS en mode audio normal après la session
    await webrtc.Helper.setAppleAudioConfiguration(
      webrtc.AppleAudioConfiguration(
        appleAudioCategory: webrtc.AppleAudioCategory.playAndRecord,
        appleAudioCategoryOptions: {
          webrtc.AppleAudioCategoryOption.allowBluetooth,
          webrtc.AppleAudioCategoryOption.allowBluetoothA2DP,
          webrtc.AppleAudioCategoryOption.defaultToSpeaker,
        },
        appleAudioMode: webrtc.AppleAudioMode.default_,
      ),
    );
  }

  bool get isActive => _active;
}
