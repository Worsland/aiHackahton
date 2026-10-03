/// Compréhension sémantique hors ligne : on transforme chaque question de
/// l'agent en vecteur (embedding) et on la rattache au point clé dont les
/// formulations d'exemple ont le vecteur le plus proche.
///
/// Ce fichier ne dépend d'aucun plugin : il parle à une interface
/// [TextEmbedder]. Le branchement sur `flutter_gemma` tient en une ligne
/// (voir [FunctionEmbedder]), ce qui permet aussi de tester sans modèle.
library;

import 'dart:math' as math;

/// Transforme un texte en vecteur. Implémentation réelle : un modèle
/// d'embeddings tournant sur l'appareil (ex. EmbeddingGemma via flutter_gemma).
abstract class TextEmbedder {
  Future<List<double>> embed(String text);

  Future<List<double>> embedDocument(String text) => embed(text);
}

/// Adaptateur : enveloppe n'importe quelle fonction `texte -> vecteur`.
/// Exemple : `FunctionEmbedder(model.generateEmbedding)`.
class FunctionEmbedder implements TextEmbedder {
  FunctionEmbedder(
    this._fn, {
    Future<List<double>> Function(String text)? documentFn,
  }) : _documentFn = documentFn;

  final Future<List<double>> Function(String text) _fn;
  final Future<List<double>> Function(String text)? _documentFn;

  @override
  Future<List<double>> embed(String text) => _fn(text);

  @override
  Future<List<double>> embedDocument(String text) => (_documentFn ?? _fn)(text);
}

/// Similarité cosinus entre deux vecteurs (0 si l'un est nul).
double cosine(List<double> a, List<double> b) {
  var dot = 0.0, na = 0.0, nb = 0.0;
  final n = math.min(a.length, b.length);
  for (var i = 0; i < n; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  if (na == 0 || nb == 0) return 0;
  return dot / (math.sqrt(na) * math.sqrt(nb));
}

class Scored<T> {
  const Scored(this.item, this.similarity);

  final T item;
  final double similarity;
}

/// Index sémantique : chaque élément est représenté par plusieurs textes
/// (libellé + formulations d'exemple). Sa similarité avec une question est
/// la meilleure similarité parmi ses textes.
class SemanticIndex<T> {
  SemanticIndex({required this.embedder, required this.textsOf});

  final TextEmbedder embedder;
  final Iterable<String> Function(T item) textsOf;

  final List<T> _items = [];
  final List<List<List<double>>> _vectors = [];

  bool get isBuilt => _items.isNotEmpty;

  /// Calcule une fois les vecteurs des textes d'exemple. À appeler à
  /// l'ouverture d'un scénario, pas à chaque question.
  Future<void> build(Iterable<T> items) async {
    _items.clear();
    _vectors.clear();
    for (final item in items) {
      final vs = <List<double>>[];
      for (final t in textsOf(item)) {
        if (t.trim().isEmpty) continue;
        vs.add(await embedder.embedDocument(t));
      }
      _items.add(item);
      _vectors.add(vs);
    }
  }

  /// Éléments classés par similarité décroissante avec [query].
  Future<List<Scored<T>>> rank(String query) async {
    if (query.trim().isEmpty) return [];
    final q = await embedder.embed(query);
    final out = <Scored<T>>[];
    for (var i = 0; i < _items.length; i++) {
      var best = -1.0;
      for (final v in _vectors[i]) {
        final s = cosine(q, v);
        if (s > best) best = s;
      }
      if (best > -1.0) out.add(Scored<T>(_items[i], best));
    }
    out.sort((a, b) => b.similarity.compareTo(a.similarity));
    return out;
  }

  /// Aide à la calibration du seuil. Pour chaque seuil, renvoie la part de
  /// questions correctement traitées : bon élément si la meilleure
  /// similarité atteint le seuil, `null` attendu (hors sujet) sinon.
  ///
  /// Les valeurs de similarité dépendent du modèle : ne copie pas un seuil
  /// trouvé ailleurs, mesure-le sur ton propre jeu de questions.
  Future<Map<double, double>> evaluateThresholds(
    List<(String question, T? expected)> cases,
    List<double> thresholds,
  ) async {
    final ranked = <List<Scored<T>>>[];
    for (final c in cases) {
      ranked.add(await rank(c.$1));
    }
    final out = <double, double>{};
    for (final t in thresholds) {
      var ok = 0;
      for (var i = 0; i < cases.length; i++) {
        final r = ranked[i];
        final T? predicted = r.isNotEmpty && r.first.similarity >= t
            ? r.first.item
            : null;
        if (predicted == cases[i].$2) ok++;
      }
      out[t] = cases.isEmpty ? 0 : ok / cases.length;
    }
    return out;
  }
}
