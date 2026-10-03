import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../lang/app_language.dart';
import '../../widgets/patient_avatar.dart' show PatientLook;
import '../voice_service.dart';
import 'offline_patient_brain.dart';

/// Joue la voix du patient en mode hors-ligne.
///
/// Les répliques hors-ligne forment un ensemble fermé et connu à l'avance
/// (voir `OfflineReply.audioId`) : pas besoin d'un moteur TTS embarqué,
/// chaque réplique peut être un fichier audio enregistré une seule fois à
/// l'avance (voix cloud ou humaine, peu importe, l'app ne fait que le
/// jouer). Voir `tool/generate_audio_manifest.md` pour la liste exacte des
/// fichiers attendus et le texte de chacun.
///
/// Tant qu'un fichier n'existe pas encore (enregistrement en cours), la
/// lecture bascule automatiquement sur `flutter_tts` — robotique, mais
/// jamais silencieux. Chaque réplique enregistrée et ajoutée aux assets
/// améliore donc l'app immédiatement, sans changement de code.
class OfflineVoicePlayer {
  OfflineVoicePlayer({required VoiceService fallbackVoice})
    : _fallbackVoice = fallbackVoice;

  final VoiceService _fallbackVoice;
  final AudioPlayer _player = AudioPlayer();

  bool _disposed = false;

  static String assetPathFor(
    PatientLook look,
    OfflineReply reply,
    AppLanguage language,
  ) => language.isYoruba
      ? 'audio/offline/yo/${look.assetName}/${reply.audioId}.mp3'
      : 'audio/offline/${look.assetName}/${reply.audioId}.mp3';

  /// Joue la réplique [reply] avec la voix de [look]. Se termine une fois
  /// la lecture (ou la synthèse de repli) achevée, comme
  /// `VoiceService.speak` — l'appelant peut donc s'en servir pour piloter
  /// l'état "le patient parle" de l'avatar de la même façon dans les trois
  /// modes de conversation.
  Future<void> speak(
    PatientLook look,
    OfflineReply reply, {
    AppLanguage language = AppLanguage.english,
  }) async {
    final assetPath = assetPathFor(look, reply, language);

    // Filet de sécurité, quoi qu'il arrive ensuite : jamais les deux voix
    // en même temps. Sans ça, une synthèse TTS restée "en vol" d'un tour
    // précédent (par ex. si `onPlayerComplete` ne s'est jamais déclenché
    // sur le web, voir plus bas) peut se superposer à la lecture suivante.
    await _fallbackVoice.stopSpeaking();

    var usedFallback = false;
    try {
      // `onPlayerComplete` (un flux à un seul événement, `.first`) s'est
      // montré peu fiable sur le web dans certaines versions
      // d'audioplayers : l'événement peut ne jamais arriver, ce qui
      // bloquait ce code pendant 20 s sans jamais détecter l'échec.
      // `onPlayerStateChanged` est plus robuste : il reflète l'état réel
      // du lecteur, y compris un échec de décodage.
      final completer = Completer<void>();
      late final StreamSubscription<PlayerState> sub;
      sub = _player.onPlayerStateChanged.listen((state) {
        if (!completer.isCompleted &&
            (state == PlayerState.completed || state == PlayerState.stopped)) {
          completer.complete();
        }
      });
      try {
        await _player.play(AssetSource(assetPath));
        await completer.future.timeout(const Duration(seconds: 15));
      } finally {
        await sub.cancel();
      }
    } catch (e) {
      // Fichier absent (pas encore enregistré) ou erreur de lecture :
      // secours sur la voix native du téléphone, sans faire attendre
      // l'agent ni casser la conversation.
      debugPrint(
        '⚠️ Audio hors-ligne indisponible ($assetPath), repli TTS: $e',
      );
      usedFallback = true;
    }

    // Le repli se fait ici, hors du bloc try/catch : s'il se produisait à
    // l'intérieur et que `_fallbackVoice.speak` échouait à son tour
    // (improbable, mais possible), l'exception remonterait comme si le
    // fichier audio était en cause, ce qui compliquerait le diagnostic.
    if (usedFallback) {
      if (language.isYoruba) {
        debugPrint(
          'Yorùbá recording is not available yet ($assetPath); keeping the '
          'patient reply in text rather than playing English speech.',
        );
        return;
      }
      await _fallbackVoice.speak(reply.text);
    }
  }

  /// Coupe la lecture en cours (ex : l'agent interrompt le patient).
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Rien à faire de plus : `stop` ne doit jamais lever d'exception
      // visible pour l'appelant.
    }
    await _fallbackVoice.stopSpeaking();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _player.dispose();
  }
}
