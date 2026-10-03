import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'pcm_player_service.dart';

/// Implémentation web utilisant l'API Web Audio (package:web).
/// Fichier chargé uniquement sur Flutter Web.
class PcmPlayerWeb implements PcmPlayerService {
  web.AudioContext? _ctx;
  int _sampleRate = 24000;

  /// Horodatage (en secondes) de fin du dernier chunk schedulé.
  /// Permet d'enchaîner les buffers sans silence ni chevauchement.
  double _nextStartTime = 0;

  @override
  Future<void> setup({required int sampleRate}) async {
    _sampleRate = sampleRate;
    _ctx = web.AudioContext();
    _nextStartTime = _ctx!.currentTime;
  }

  @override
  Future<void> feed(List<int> pcmSamples) async {
    if (_ctx == null) return;

    final int frameCount = pcmSamples.length;
    if (frameCount == 0) return;

    // Créer un AudioBuffer mono
    final web.AudioBuffer buffer = _ctx!.createBuffer(
      1,
      frameCount,
      _sampleRate.toDouble(),
    );

    // Convertir Int16 [-32768, 32767] → Float32 [-1.0, 1.0]
    final Float32List float32 = Float32List(frameCount);
    for (int i = 0; i < frameCount; i++) {
      float32[i] = pcmSamples[i] / 32768.0;
    }

    buffer.copyToChannel(float32.toJS, 0);

    // Créer la source et la connecter à la sortie
    final web.AudioBufferSourceNode source = _ctx!.createBufferSource();
    source.buffer = buffer;
    source.connect(_ctx!.destination);

    // Scheduling continu : on empile les buffers les uns après les autres.
    final double now = _ctx!.currentTime;
    // Si on est en retard (ex: premier chunk ou pause), on repart du temps actuel.
    final double startTime = _nextStartTime < now ? now : _nextStartTime;

    source.start(startTime);

    // Calculer quand ce buffer se termine pour le prochain scheduling.
    _nextStartTime = startTime + (frameCount / _sampleRate);
  }

  @override
  Future<void> release() async {
    await _ctx?.close().toDart;
    _ctx = null;
    _nextStartTime = 0;
  }
}

/// Retourne une instance de PcmPlayerWeb (sélectionné automatiquement sur Flutter Web).
PcmPlayerService getPlatformPcmPlayer() => PcmPlayerWeb();
