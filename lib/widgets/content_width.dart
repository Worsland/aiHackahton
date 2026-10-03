import 'package:flutter/material.dart';

/// Centre son contenu et limite sa largeur sur grand écran, pour éviter
/// qu'un formulaire ou une liste s'étire sur toute la largeur d'un
/// moniteur.
///
/// Utilisé par tous les écrans secondaires (compte, profil, progrès,
/// diagnostic, récapitulatif...) : la page de sélection des scénarios a
/// déjà son propre traitement dédié (sidebar + marges calculées à part) et
/// n'a pas besoin de ce widget.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 640});

  final Widget child;

  /// 640 convient à un formulaire (compte, profil). Les écrans plus
  /// proches d'une liste (progrès, diagnostic, récap) passent plutôt 720,
  /// la même largeur que les cartes de la page principale.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
