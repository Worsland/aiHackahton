import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'pcm_player_service.dart';

/// Implémentation mobile utilisant flutter_pcm_sound.
/// Fichier chargé uniquement sur Android / iOS.
class PcmPlayerMobile implements PcmPlayerService {
  @override
  Future<void> setup({required int sampleRate}) async {
    await FlutterPcmSound.setup(sampleRate: sampleRate, channelCount: 1);
    // Seuil élevé = 10 s de buffer pour éviter les coupures.
    await FlutterPcmSound.setFeedThreshold(sampleRate * 10);
    FlutterPcmSound.setFeedCallback(_onFeedNeeded);
    await FlutterPcmSound.start();
  }

  @override
  Future<void> feed(List<int> pcmSamples) async {
    await FlutterPcmSound.feed(PcmArrayInt16.fromList(pcmSamples));
  }

  @override
  Future<void> release() async {
    await FlutterPcmSound.release();
  }

  void _onFeedNeeded(int remainingFrames) {
    // Callback informatif — le feed se fait directement à la réception des chunks.
  }
}

/// Retourne une instance de PcmPlayerMobile (sélectionné automatiquement sur mobile/desktop).
PcmPlayerService getPlatformPcmPlayer() => PcmPlayerMobile();
