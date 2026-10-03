/// État de la reconnaissance vocale SUR L'APPAREIL dans le navigateur.
enum OfflineSttStatus {
  /// Ce navigateur n'expose pas l'API (Firefox, Safari, Brave...) : seul
  /// Chrome/Edge de bureau la fournit.
  unsupported,

  /// Le pack de langue est installé : la reconnaissance marche sans réseau.
  ready,

  /// Le navigateur sait le faire, mais le pack de langue doit d'abord être
  /// téléchargé (une seule fois, réseau nécessaire).
  needsDownload,

  /// Le pack est en cours de téléchargement.
  downloading,

  /// L'anglais n'est pas proposé en local sur cet appareil.
  unavailable,
}

/// Erreur lisible par l'agent (le message est affiché tel quel).
class OfflineSttException implements Exception {
  const OfflineSttException(this.message);
  final String message;

  @override
  String toString() => message;
}
