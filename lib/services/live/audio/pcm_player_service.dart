/// Interface abstraite pour la lecture PCM cross-platform.
/// - Mobile : flutter_pcm_sound
/// - Web    : Web Audio API via package:web
abstract class PcmPlayerService {
  /// Initialise le player avec le taux d'échantillonnage donné.
  Future<void> setup({required int sampleRate});

  /// Envoie des samples PCM 16-bit signés au player.
  Future<void> feed(List<int> pcmSamples);

  /// Libère toutes les ressources.
  Future<void> release();
}
