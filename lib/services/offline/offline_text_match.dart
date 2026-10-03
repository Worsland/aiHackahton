/// Normalisation et appariement de mots-clés pour le patient hors ligne.
///
/// Volontairement indépendant de `KeyPoint` (et de Flutter) : le moteur ne
/// sait comparer que du texte à des listes de mots-clés. C'est aussi
/// l'endroit où brancher plus tard un scoreur par embeddings : il suffira
/// de remplacer [TextMatch.rank] par une version qui renvoie le même type.
library;

import '../lang/yoruba_normalizer.dart';

/// Un élément qui correspond à la phrase, avec son score.
class Ranked<T> {
  const Ranked(this.item, this.score, this.index);

  final T item;

  /// Somme des mots des mots-clés trouvés : « how long » (2) pèse plus
  /// qu'un mot isolé comme « hot » (1), donc les expressions précises
  /// l'emportent sur les mots génériques.
  final int score;

  /// Position d'origine, utilisée pour départager les ex-aequo.
  final int index;
}

class TextMatch {
  TextMatch._();

  static const _from = 'àâäáãåèéêëìíîïòóôöõùúûüýÿñç';
  static const _to = 'aaaaaaeeeeiiiiooooouuuuyync';

  /// Voyelles brèves (tashkeel) et tatweel de l'arabe.
  static final _arabicMarks = RegExp('[\u064B-\u065F\u0670\u0640]');
  static final _alefVariants = RegExp('[\u0623\u0625\u0622]');
  static final _notWord = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
  static final _spaces = RegExp(r'\s+');

  /// Minuscules, sans accents latins, arabe normalisé (alef, ya, ta
  /// marbouta, voyelles brèves), ponctuation remplacée par des espaces.
  /// Contrairement à l'ancienne version, les lettres non latines sont
  /// conservées : l'arabe ou le cyrillique ne deviennent plus une chaîne
  /// vide.
  static String normalize(String s) {
    var out = YorubaNormalizer.normalize(s);
    for (var i = 0; i < _from.length; i++) {
      out = out.replaceAll(_from[i], _to[i]);
    }
    out = out
        .replaceAll(_arabicMarks, '')
        .replaceAll(_alefVariants, '\u0627')
        .replaceAll('\u0649', '\u064A')
        .replaceAll('\u0629', '\u0647');
    return out.replaceAll(_notWord, ' ').replaceAll(_spaces, ' ').trim();
  }

  static List<String> tokenize(String s) =>
      normalize(s).split(' ').where((t) => t.isNotEmpty).toList();

  static final Map<String, List<String>> _kwCache = {};
  static List<String> _kwTokens(String kw) =>
      _kwCache.putIfAbsent(kw, () => tokenize(kw));

  static const _suffixes = ['s', 'es', 'ed', 'ing', 'en'];

  /// Règle d'appariement d'un mot de la phrase avec un mot du mot-clé :
  /// - mot-clé de 4 lettres ou plus : radical (« hydrat » → « hydration »,
  ///   « urin » → « urinating », comme avant) ;
  /// - mot-clé court : mot entier ou forme simple (« hot » ne reconnaît
  ///   plus « hotel », « pad » plus « paddy », « eat » reconnaît encore
  ///   « eating »).
  static bool _tokenMatches(String word, String kw) {
    if (word == kw) return true;
    if (kw.length >= 4) return word.startsWith(kw);
    for (final s in _suffixes) {
      if (word == '$kw$s') return true;
    }
    return false;
  }

  /// Vrai si [keyword] (un ou plusieurs mots) apparaît dans [tokens], les
  /// mots d'une expression devant être consécutifs.
  static bool containsPhrase(List<String> tokens, String keyword) {
    final kw = _kwTokens(keyword);
    if (kw.isEmpty || kw.length > tokens.length) return false;
    for (var i = 0; i <= tokens.length - kw.length; i++) {
      var ok = true;
      for (var j = 0; j < kw.length; j++) {
        if (!_tokenMatches(tokens[i + j], kw[j])) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  /// Classe les [items] qui correspondent à [text], du meilleur au moins
  /// bon. Les éléments sans aucune correspondance sont absents.
  static List<Ranked<T>> rank<T>(
    Iterable<T> items,
    Iterable<String> Function(T) keywordsOf,
    String text,
  ) {
    final tokens = tokenize(text);
    final out = <Ranked<T>>[];
    if (tokens.isEmpty) return out;
    var index = 0;
    for (final item in items) {
      var score = 0;
      for (final kw in keywordsOf(item)) {
        if (containsPhrase(tokens, kw)) score += _kwTokens(kw).length;
      }
      if (score > 0) out.add(Ranked<T>(item, score, index));
      index++;
    }
    out.sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : a.index.compareTo(b.index);
    });
    return out;
  }
}
