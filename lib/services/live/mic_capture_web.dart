// mic_capture_web.dart  ── Web only
// Capture le microphone via getUserMedia avec AEC natif du navigateur.
// N'est importé que sur Flutter Web (voir mic_capture_stub.dart pour mobile).

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

typedef AudioChunkCallback = void Function(Uint8List chunk);

class MicCapture {
  web.MediaStream? _stream;
  web.AudioContext? _audioCtx;
  web.ScriptProcessorNode? _processor;
  AudioChunkCallback? _onChunk;

  /// Démarre la capture micro avec AEC, noise suppression et AGC activés.
  /// [onChunk] reçoit des buffers PCM 16-bit LE à 16 kHz.
  Future<void> start(AudioChunkCallback onChunk) async {
    _onChunk = onChunk;

    // getUserMedia avec toutes les contraintes audio pour l'AEC
    final constraints = web.MediaStreamConstraints(
      audio: web.MediaTrackConstraints(
        echoCancellation: true.toJS, // ← AEC natif navigateur
        noiseSuppression: true.toJS, // suppression de bruit
        autoGainControl: true.toJS, // volume auto
        sampleRate: 16000.toJS,
        channelCount: 1.toJS,
      ),
      video: false.toJS,
    );

    _stream = await web.window.navigator.mediaDevices
        .getUserMedia(constraints)
        .toDart;

    // AudioContext à 16 kHz pour correspondre à Gemini Live
    _audioCtx = web.AudioContext(web.AudioContextOptions(sampleRate: 16000));

    final source = _audioCtx!.createMediaStreamSource(_stream!);

    // ScriptProcessorNode : 4096 samples par chunk, 1 canal in/out
    _processor = _audioCtx!.createScriptProcessor(4096, 1, 1);

    _processor!.onaudioprocess = (web.AudioProcessingEvent event) {
      final inputBuffer = event.inputBuffer;
      final channelData = inputBuffer.getChannelData(0); // Float32Array JS
      final floats = (channelData as JSFloat32Array).toDart;

      // Conversion Float32 → Int16 (PCM 16-bit)
      final pcm = Int16List(floats.length);
      for (var i = 0; i < floats.length; i++) {
        final s = (floats[i] * 32767).clamp(-32768, 32767).toInt();
        pcm[i] = s;
      }

      _onChunk?.call(pcm.buffer.asUint8List());
    }.toJS;

    source.connect(_processor!);
    _processor!.connect(_audioCtx!.destination);
  }

  Future<void> stop() async {
    _processor?.disconnect();
    _processor = null;
    _audioCtx?.close();
    _audioCtx = null;
    _stream?.getTracks().toDart.forEach((t) => t.stop());
    _stream = null;
    _onChunk = null;
  }

  bool get isActive => _stream != null;
}
