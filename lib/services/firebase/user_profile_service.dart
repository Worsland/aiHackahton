import 'package:cloud_firestore/cloud_firestore.dart';

/// Infos de profil d'un utilisateur : prénom, nom, et une petite photo
/// encodée en base64 (voir le commentaire de [UserProfileService] pour
/// pourquoi pas un fichier hébergé).
class UserProfile {
  const UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.photoBase64,
  });

  final String firstName;
  final String lastName;

  /// `null` tant qu'aucune photo n'a été choisie.
  final String? photoBase64;

  /// Nom à afficher un peu partout dans l'app (sidebar, en-têtes...).
  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? 'Guest' : full;
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? photoBase64,
  }) => UserProfile(
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    photoBase64: photoBase64 ?? this.photoBase64,
  );

  Map<String, dynamic> toMap() => {
    'firstName': firstName,
    'lastName': lastName,
    if (photoBase64 != null) 'photoBase64': photoBase64,
  };

  factory UserProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserProfile();
    return UserProfile(
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      photoBase64: map['photoBase64'] as String?,
    );
  }
}

/// Lit/écrit le document racine `users/{uid}` (prénom, nom, photo).
///
/// Volontairement séparé de [SessionRepository], qui gère la sous-collection
/// `users/{uid}/sessions` : les deux documents/collections cohabitent sans
/// collision. La photo est stockée en base64 directement dans le document
/// (redimensionnée à 320px et compressée côté client avant l'envoi, donc
/// quelques dizaines de Ko, très loin de la limite de 1 Mo par document
/// Firestore) plutôt que dans Firebase Storage : ça évite d'ajouter et de
/// configurer un second service juste pour un avatar, au prix de photos
/// plus petites qu'un vrai CDN d'images — largement suffisant ici.
///
/// Même garantie hors-ligne que le reste de l'app : `snapshots()` sert le
/// cache local sans réseau, et `set(..., merge: true)` écrit d'abord en
/// local avant de synchroniser dès que la connexion revient.
class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<UserProfile> watch(String uid) {
    return _doc(
      uid,
    ).snapshots().map((snap) => UserProfile.fromMap(snap.data()));
  }

  Future<UserProfile> fetchOnce(String uid) async {
    final snap = await _doc(uid).get();
    return UserProfile.fromMap(snap.data());
  }

  Future<bool> save(String uid, UserProfile profile) async {
    try {
      await _doc(uid).set(profile.toMap(), SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }
}
