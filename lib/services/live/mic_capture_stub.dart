// mic_capture_stub.dart  ── Fallback si flutter_webrtc non disponible
import 'dart:typed_data';

typedef AudioChunkCallback = void Function(Uint8List chunk);

class MicCapture {
  Future<void> start(AudioChunkCallback onChunk) async {}
  Future<void> stop() async {}
  bool get isActive => false;
}
