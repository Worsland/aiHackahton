import 'package:firebase_auth/firebase_auth.dart';

/// Connexion anonyme par défaut : l'agent utilise l'app immédiatement, sans
/// email ni mot de passe. Le compte anonyme peut être *lié* plus tard à un
/// email/mot de passe pour récupérer sa progression sur un autre appareil —
/// les données existantes (sessions, scores) sont conservées, pas dupliquées.
///
/// Ce choix est celui qui "marche aussi hors ligne" (cf. discussion projet) :
/// une fois le compte anonyme créé une première fois (ce qui demande un
/// bref instant de réseau), la session Firebase Auth reste valide et
/// utilisable hors-ligne indéfiniment, sans nouvelle connexion nécessaire.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// true si l'utilisateur courant n'a pas encore de compte "réel" (email
  /// lié). Sert à savoir si on doit proposer "Sauvegarder ma progression".
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// Change à chaque connexion/déconnexion/liaison de compte. Utile pour
  /// rafraîchir un écran de profil ou de progression.
  Stream<User?> get userChanges => _auth.authStateChanges();

  /// Garantit qu'un utilisateur (au moins anonyme) est connecté, et le
  /// retourne. À appeler au démarrage de l'app, avant tout accès à
  /// Firestore : `uid` sert de clé pour toutes les données de l'agent.
  ///
  /// Peut échouer si l'app est lancée hors ligne pour la toute première
  /// fois (avant que le moindre compte n'ait jamais été créé sur cet
  /// appareil) : dans ce cas, `currentUser` reste `null` et l'app doit
  /// fonctionner en mode "invité local" jusqu'au retour du réseau — voir
  /// `SessionRepository.save`, qui tolère un `uid` absent.
  Future<User?> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } on FirebaseAuthException {
      return null;
    }
  }

  /// Transforme le compte anonyme courant en compte email/mot de passe,
  /// en conservant toutes les données déjà associées à son `uid` (aucune
  /// donnée à migrer manuellement, Firestore les garde sous le même uid).
  ///
  /// Lève [FirebaseAuthException] si l'email est déjà utilisé ailleurs :
  /// l'appelant doit alors proposer `signInWithEmail` à la place, en
  /// prévenant que la progression faite en anonyme sur *cet* appareil ne
  /// sera pas automatiquement fusionnée avec l'autre compte.
  Future<User> linkToEmail({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw StateError(
        'Aucun compte anonyme actif à lier (ensureSignedIn() a-t-il été '
        'appelé ?).',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    final result = await user.linkWithCredential(credential);
    return result.user!;
  }

  /// Connexion à un compte existant, par exemple sur un nouvel appareil
  /// après une réinstallation.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user!;
  }

  Future<void> signOut() => _auth.signOut();
}
