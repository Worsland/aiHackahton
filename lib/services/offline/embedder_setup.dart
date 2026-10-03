/// Branchement de flutter_gemma (embeddings sur l'appareil) au cerveau
/// hors ligne. À placer dans lib/services/offline/.
///
/// Écrit d'après le README de flutter_gemma 1.9 : les noms d'API évoluent
/// vite, donc si l'analyseur signale une erreur ici, compare avec l'exemple
/// de la version installée (pub.dev/packages/flutter_gemma).
library;

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_embeddings/flutter_gemma_embeddings.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import 'semantic_matcher.dart';

// Gecko 110M quantifié (256 tokens, ~114 Mo), dépôt public sous Apache-2.0.
const _modelUrl =
    'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/'
    'Gecko_256_quant.tflite';
const _tokenizerUrl =
    'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/'
    'sentencepiece.model';

/// À appeler une fois avant [ensureEmbedder]. Envelopper l'appel dans un
/// try/catch pour que l'app démarre même si l'IA n'est pas disponible.
Future<void> initGemmaEmbeddings() => FlutterGemma.initialize(
  embeddingBackends: const [LiteRtEmbeddingBackend()],
  embeddingTokenizers: const [GemmaEmbeddingTokenizers()],
);

/// Renvoie un [TextEmbedder] prêt à l'emploi.
///
/// - Modèle déjà installé : il est restauré, aucun réseau nécessaire.
/// - Premier lancement : il est téléchargé, puis tout fonctionne hors ligne.
Future<TextEmbedder> ensureEmbedder({
  void Function(int progress)? onProgress,
  CancelToken? cancelToken,
}) async {
  if (FlutterGemma.activeEmbedderSpec != null) {
    final model = await FlutterGemma.getActiveEmbedder();
    return FunctionEmbedder(
      model.generateEmbedding,
      documentFn: (text) => model.generateEmbedding(
        text,
        taskType: TaskType.retrievalDocument,
      ),
    );
  }

  var installer = FlutterGemma.installEmbedder()
      .modelFromNetwork(_modelUrl)
      .tokenizerFromNetwork(_tokenizerUrl);
  if (cancelToken != null) {
    installer = installer.withCancelToken(cancelToken);
  }
  installer = installer
      .withModelProgress((progress) {
        onProgress?.call((progress * 0.99).round());
      })
      .withTokenizerProgress((progress) {
        onProgress?.call(99 + (progress * 0.01).round());
      });
  await installer.install();
  final model = await FlutterGemma.getActiveEmbedder();
  return FunctionEmbedder(
    model.generateEmbedding,
    documentFn: (text) => model.generateEmbedding(
      text,
      taskType: TaskType.retrievalDocument,
    ),
  );
}

/// Returns the installed model without downloading it, or null if none exists.
Future<TextEmbedder?> loadInstalledEmbedder() async {
  if (FlutterGemma.activeEmbedderSpec == null) return null;
  final model = await FlutterGemma.getActiveEmbedder();
  return FunctionEmbedder(
    model.generateEmbedding,
    documentFn: (text) => model.generateEmbedding(
      text,
      taskType: TaskType.retrievalDocument,
    ),
  );
}
