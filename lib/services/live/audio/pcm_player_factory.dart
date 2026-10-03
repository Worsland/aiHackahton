import 'pcm_player_service.dart';
// Import conditionnel Dart :
//   - dart.library.html disponible  → Flutter Web   → PcmPlayerWeb
//   - dart.library.io   disponible  → mobile/desktop → PcmPlayerMobile
//
// Chaque fichier expose sa propre classe concrète sous le même nom
// via la fonction getPlatformPcmPlayer().
import 'pcm_player_mobile.dart' if (dart.library.html) 'pcm_player_web.dart';

/// Retourne l'implémentation PCM adaptée à la plateforme courante.
///
/// Usage :
/// ```dart
/// final PcmPlayerService player = createPcmPlayer();
/// await player.setup(sampleRate: 24000);
/// ```
PcmPlayerService createPcmPlayer() => getPlatformPcmPlayer();
