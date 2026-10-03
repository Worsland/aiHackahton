import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

enum PatientMood { idle, listening, thinking, speaking }

/// Les personnages disponibles. Chacun correspond à un jeu de calques SVG
/// généré par `tools/split_patient_svgs.py` dans `assets/patients/`
/// (`<assetName>_body.svg`, `_head.svg`, `_eyes.svg`, ...).
///
/// [mouthY] et [eyeY] sont des coordonnées dans le viewBox 1024x1024 du SVG :
/// ce sont les points autour desquels la bouche s'ouvre et les yeux clignent.
/// Le script les affiche à chaque exécution si tu modifies un dessin.
enum PatientLook {
  child('child', mouthY: 540, eyeY: 418, voiceName: 'Puck'),
  elderly('elderly', mouthY: 562, eyeY: 411, voiceName: 'Fenrir'),
  man('man', mouthY: 554, eyeY: 410, voiceName: 'Charon'),
  woman('woman', mouthY: 552, eyeY: 410, voiceName: 'Aoede', hasHairBack: true),
  womanMature(
    'woman_mature',
    mouthY: 552,
    eyeY: 410,
    voiceName: 'Kore',
    hasHairBack: true,
  );

  const PatientLook(
    this.assetName, {
    required this.mouthY,
    required this.eyeY,
    required this.voiceName,
    this.hasHairBack = false,
  });

  final String assetName;
  final double mouthY;
  final double eyeY;

  /// Voix prédéfinie de Gemini Live utilisée quand ce personnage parle.
  final String voiceName;

  /// Cheveux longs dessinés derrière le corps (calque `hair_back`).
  final bool hasHairBack;

  String layer(String name) => 'assets/patients/${assetName}_$name.svg';
}

/// Avatar animé du patient virtuel, construit à partir de calques SVG
/// empilés (corps, tête, sourcils, yeux, bouche, cheveux).
///
/// Ce qui bouge, indépendamment :
///  - le corps respire en continu (léger étirement du buste) ;
///  - les yeux clignent à intervalles aléatoires ;
///  - la bouche s'ouvre et se ferme quand [mood] vaut `speaking` ;
///  - la tête, les sourcils et le regard prennent une pose différente selon
///    l'état : écoute (penché, sourcils levés), réflexion (regard en l'air).
///
/// Le contrat avec l'écran reste le même que l'ancien placeholder : on ne
/// fournit que [mood] (et [look] pour choisir le personnage).
class PatientAvatar extends StatefulWidget {
  const PatientAvatar({
    super.key,
    required this.mood,
    this.look = PatientLook.woman,
    this.size = 120,
    this.animate = true,
    this.mouthLevel,
  });

  final PatientMood mood;
  final PatientLook look;
  final double size;

  /// Ouverture de la bouche (0 à 1) fournie par l'audio réel (Gemini Live).
  /// Si elle est fournie, elle remplace le mouvement de bouche aléatoire
  /// utilisé en mode léger (synthèse vocale du téléphone).
  final ValueListenable<double>? mouthLevel;

  /// `false` pour un portrait fixe (ex. dans la liste des scénarios) :
  /// aucune animation, aucun timer.
  final bool animate;

  @override
  State<PatientAvatar> createState() => _PatientAvatarState();
}

/// Pose de la tête et du visage pour un état donné. Toutes les valeurs sont
/// interpolées en douceur quand l'état change.
class _Pose {
  const _Pose({
    this.tilt = 0,
    this.browLift = 0,
    this.eyeDx = 0,
    this.eyeDy = 0,
    this.eyeOpen = 1,
  });

  /// Inclinaison de la tête en degrés (positif = penche vers la droite).
  final double tilt;

  /// Hauteur dont les sourcils montent, en unités SVG (viewBox 1024).
  final double browLift;

  /// Décalage du regard, en unités SVG.
  final double eyeDx;
  final double eyeDy;

  /// 1 = yeux normaux, > 1 = écarquillés, < 1 = mi-clos.
  final double eyeOpen;

  static const idle = _Pose();
  static const listening = _Pose(tilt: 3, browLift: 7, eyeOpen: 1.07);
  static const thinking = _Pose(
    tilt: -3.5,
    browLift: 10,
    eyeDx: 7,
    eyeDy: -6,
    eyeOpen: 0.93,
  );
  static const speaking = _Pose(browLift: 2);

  static _Pose forMood(PatientMood mood) => switch (mood) {
    PatientMood.idle => idle,
    PatientMood.listening => listening,
    PatientMood.thinking => thinking,
    PatientMood.speaking => speaking,
  };

  static _Pose lerp(_Pose a, _Pose b, double t) => _Pose(
    tilt: lerpDouble(a.tilt, b.tilt, t)!,
    browLift: lerpDouble(a.browLift, b.browLift, t)!,
    eyeDx: lerpDouble(a.eyeDx, b.eyeDx, t)!,
    eyeDy: lerpDouble(a.eyeDy, b.eyeDy, t)!,
    eyeOpen: lerpDouble(a.eyeOpen, b.eyeOpen, t)!,
  );
}

class _PatientAvatarState extends State<PatientAvatar>
    with TickerProviderStateMixin {
  static const _border = 3.0;

  /// Le buste est agrandi de 30 % dans le médaillon rond pour cadrer le
  /// visage ; le bas du torse (y = 900/1024) dépasse sous le cercle.
  static const _rigScale = 1.3;
  static const _torsoBottom = 900 / 1024;

  final math.Random _rng = math.Random();

  /// Respiration : 0 → 1 → 0 en boucle.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  /// Clignement : 0 = yeux ouverts, 1 = fermés.
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
  );

  /// Ouverture de la bouche : 0 = fermée, 1 = grande ouverte.
  late final AnimationController _mouth = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  /// Transition entre deux poses lors d'un changement d'état.
  late final AnimationController _poseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );

  late _Pose _poseFrom = _Pose.forMood(widget.mood);
  late _Pose _poseTo = _poseFrom;

  Timer? _blinkTimer;
  Timer? _talkTimer;

  /// Les calques SVG se chargent de façon asynchrone : on fait un fondu
  /// d'entrée pour ne pas voir le visage se construire pièce par pièce.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _breath.repeat(reverse: true);
      _scheduleBlink();
    }
    widget.mouthLevel?.addListener(_onExternalMouth);
    _syncTalking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _shown = true);
      });
    });
  }

  @override
  void didUpdateWidget(PatientAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _breath.repeat(reverse: true);
        _scheduleBlink();
      } else {
        _breath.stop();
        _blinkTimer?.cancel();
      }
    }

    if (oldWidget.mouthLevel != widget.mouthLevel) {
      oldWidget.mouthLevel?.removeListener(_onExternalMouth);
      widget.mouthLevel?.addListener(_onExternalMouth);
    }

    if (oldWidget.mood != widget.mood) {
      _poseFrom = _currentPose;
      _poseTo = _Pose.forMood(widget.mood);
      _poseCtrl.forward(from: 0);
    }
    _syncTalking();
  }

  @override
  void dispose() {
    widget.mouthLevel?.removeListener(_onExternalMouth);
    _blinkTimer?.cancel();
    _talkTimer?.cancel();
    _breath.dispose();
    _blink.dispose();
    _mouth.dispose();
    _poseCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Animations pilotées par timers
  // -------------------------------------------------------------------

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    final wait = Duration(milliseconds: 2200 + _rng.nextInt(3200));
    _blinkTimer = Timer(wait, () async {
      if (!mounted) return;
      await _blink.forward();
      if (!mounted) return;
      await _blink.reverse();
      // Une fois sur cinq : double clignement, plus naturel.
      if (mounted && _rng.nextInt(5) == 0) {
        await _blink.forward();
        if (!mounted) return;
        await _blink.reverse();
      }
      if (mounted) _scheduleBlink();
    });
  }

  /// Niveau de bouche venant de l'audio réel : on le suit avec un léger lissage.
  void _onExternalMouth() {
    _mouth.animateTo(
      widget.mouthLevel!.value,
      duration: const Duration(milliseconds: 60),
    );
  }

  /// Lance ou arrête le mouvement de bouche selon l'état courant.
  /// Tant que le patient parle, on choisit toutes les ~120 ms une nouvelle
  /// ouverture au hasard (avec des micro-pauses) : ça imite les syllabes
  /// sans avoir besoin d'analyser l'audio de la synthèse vocale.
  void _syncTalking() {
    // Si un niveau audio réel est fourni, pas besoin de simuler la bouche.
    final speaking =
        widget.animate &&
        widget.mouthLevel == null &&
        widget.mood == PatientMood.speaking;
    if (speaking && _talkTimer == null) {
      _talkTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        final target = _rng.nextInt(6) == 0
            ? 0.0
            : 0.35 + _rng.nextDouble() * 0.65;
        _mouth.animateTo(
          target,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      });
    } else if (!speaking && _talkTimer != null) {
      _talkTimer!.cancel();
      _talkTimer = null;
      _mouth.animateTo(0, duration: const Duration(milliseconds: 150));
    }
  }

  // -------------------------------------------------------------------
  // Rendu
  // -------------------------------------------------------------------

  _Pose get _currentPose => _Pose.lerp(
    _poseFrom,
    _poseTo,
    Curves.easeOutCubic.transform(_poseCtrl.value),
  );

  Color get _ringColor {
    switch (widget.mood) {
      case PatientMood.listening:
        return AppColors.primary;
      case PatientMood.thinking:
        return AppColors.secondary;
      case PatientMood.speaking:
        return AppColors.success;
      case PatientMood.idle:
        return AppColors.primary.withValues(alpha: 0.35);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final portrait = size * 0.82;
    final active = widget.mood != PatientMood.idle;

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breath, _blink, _mouth, _poseCtrl]),
          builder: (context, _) {
            final breath = Curves.easeInOut.transform(_breath.value);
            final halo = active ? 0.94 + breath * 0.1 : 1.0;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Halo qui pulse quand le patient est "actif".
                Transform.scale(
                  scale: halo,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _ringColor.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Médaillon rond contenant le personnage.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: portrait,
                  height: portrait,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.alphaBlend(
                      AppColors.primaryLight.withValues(alpha: 0.16),
                      Colors.white,
                    ),
                    border: Border.all(color: _ringColor, width: _border),
                    boxShadow: [
                      BoxShadow(
                        color: _ringColor.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AnimatedOpacity(
                      opacity: _shown ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: _buildRig(portrait - 2 * _border, breath),
                    ),
                  ),
                ),
                if (widget.animate) _buildBadge(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Empile les calques et applique les transformations de chacun.
  Widget _buildRig(double inner, double breath) {
    final look = widget.look;
    final pose = _currentPose;
    final talk = _mouth.value;
    final blink = _blink.value;

    final s = inner * _rigScale; // côté du carré SVG à l'écran
    final u = s / 1024; // pixels par unité SVG
    final left = -(s - inner) / 2;
    final top = inner * 1.02 - s * _torsoBottom;

    Widget layer(String name) =>
        SvgPicture.asset(look.layer(name), width: s, height: s);

    // La tête pivote autour de la base du cou. Elle monte avec la
    // respiration et descend très légèrement quand la bouche s'ouvre.
    Widget headMove(Widget child) => Transform.translate(
      offset: Offset(0, (-breath * 3.0 + talk * 2.0) * u),
      child: Transform.rotate(
        angle: pose.tilt * math.pi / 180,
        alignment: const FractionalOffset(0.5, 0.62),
        child: child,
      ),
    );

    // Le buste s'étire depuis le bas (qui reste fixe sous le cercle).
    final body = Transform.scale(
      scaleX: 1 + breath * 0.004,
      scaleY: 1 + breath * 0.012,
      alignment: const FractionalOffset(0.5, _torsoBottom),
      child: layer('body'),
    );

    final brows = Transform.translate(
      offset: Offset(0, -pose.browLift * u),
      child: layer('brows'),
    );

    // Clignement = écrasement vertical des yeux autour de leur centre.
    // Il ne reste que le trait des cils, comme des paupières fermées.
    final eyes = Transform.translate(
      offset: Offset(pose.eyeDx * u, pose.eyeDy * u),
      child: Transform.scale(
        scaleY: pose.eyeOpen * (1 - 0.93 * blink),
        alignment: FractionalOffset(0.5, look.eyeY / 1024),
        child: layer('eyes'),
      ),
    );

    // Bouche : on bascule sur le calque "ouvert" dès que l'ouverture
    // dépasse un seuil, et on l'étire vers le bas depuis la ligne des lèvres.
    final mouth = talk > 0.06
        ? Transform.scale(
            scaleY: 0.25 + 0.75 * talk,
            alignment: FractionalOffset(0.5, look.mouthY / 1024),
            child: layer('mouth_open'),
          )
        : layer('mouth');

    return SizedBox.square(
      dimension: inner,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: left,
            top: top,
            width: s,
            height: s,
            child: Stack(
              children: [
                if (look.hasHairBack) headMove(layer('hair_back')),
                body,
                headMove(
                  Stack(
                    children: [
                      layer('head'),
                      brows,
                      eyes,
                      mouth,
                      layer('hair'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Petite pastille d'état (micro / réflexion / voix) : l'état ne repose
  /// ainsi pas uniquement sur la couleur de l'anneau.
  Widget _buildBadge() {
    IconData? icon;
    Color color = AppColors.primary;
    switch (widget.mood) {
      case PatientMood.listening:
        icon = Icons.mic_rounded;
        color = AppColors.primary;
      case PatientMood.thinking:
        icon = Icons.more_horiz_rounded;
        color = AppColors.secondary;
      case PatientMood.speaking:
        icon = Icons.graphic_eq_rounded;
        color = AppColors.success;
      case PatientMood.idle:
        icon = null;
    }

    final d = widget.size * 0.28;
    return Positioned(
      right: widget.size * 0.04,
      bottom: widget.size * 0.04,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: icon == null
            ? const SizedBox.shrink(key: ValueKey('badge-none'))
            : Container(
                key: ValueKey(widget.mood),
                width: d,
                height: d,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(icon, color: Colors.white, size: d * 0.58),
              ),
      ),
    );
  }
}
