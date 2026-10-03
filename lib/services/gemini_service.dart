import 'package:google_generative_ai/google_generative_ai.dart';

/// Service Gemini flexible : permet de créer une conversation avec
/// un "persona" différent à chaque scénario (ex: patient virtuel X, Y, Z).
class GeminiService {
  GeminiService(this.apiKey, {this.modelName = 'gemini-2.0-flash'});

  final String apiKey;
  final String modelName;
  ChatSession? _chat;

  /// Démarre une conversation avec une instruction système donnée
  /// (ex: la description du patient à simuler).
  void startScenarioChat(String systemPrompt) {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
    );
    _chat = model.startChat();
  }

  Future<String> sendMessage(String message) async {
    if (_chat == null) {
      throw StateError('Appelle startScenarioChat() avant sendMessage().');
    }
    final response = await _chat!.sendMessage(Content.text(message));
    return response.text ?? '';
  }

  /// Appel isolé, sans historique — utile pour demander un feedback final
  /// sur la performance de l'agent de santé (hors du rôle du patient).
  Future<String> generateOnce(String prompt) async {
    final model = GenerativeModel(model: modelName, apiKey: apiKey);
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }
}
