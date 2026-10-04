import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Gemini requests go through the authenticated server; no provider key ships
/// with the application.
class GeminiService {
  GeminiService(this.backendUrl, {http.Client? client})
    : _client = client ?? http.Client();

  final String backendUrl;
  final http.Client _client;
  String _systemPrompt = '';
  final List<Map<String, Object>> _contents = [];

  /// Starts a conversation with the patient instructions for one scenario.
  void startScenarioChat(String systemPrompt) {
    _systemPrompt = systemPrompt;
    _contents.clear();
  }

  Future<String> sendMessage(String message) async {
    if (backendUrl.isEmpty) {
      throw StateError(
        'The Gemini server is not configured. Switch to offline practice.',
      );
    }
    if (_systemPrompt.isEmpty) {
      throw StateError('Start a scenario before sending a message.');
    }

    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken == null) {
      throw StateError('Sign in before starting an online conversation.');
    }

    final contents = [
      ..._contents,
      {
        'role': 'user',
        'parts': [
          {'text': message},
        ],
      },
    ];
    if (contents.length > 40) {
      contents.removeRange(0, contents.length - 40);
      while (contents.first['role'] != 'user') {
        contents.removeAt(0);
      }
    }
    final response = await _client
        .post(
          Uri.parse(backendUrl).resolve('/generate'),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'systemPrompt': _systemPrompt,
            'contents': contents,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      final detail = _errorMessage(response.body);
      throw StateError(
        'Gemini server request failed (${response.statusCode}): $detail',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>? ?? const [];
    if (candidates.isEmpty) {
      throw StateError('Gemini returned no response.');
    }
    final candidate = candidates.first as Map<String, dynamic>;
    final content = candidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? const [];
    final answer = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text'])
        .whereType<String>()
        .join();
    if (answer.isEmpty) {
      throw StateError('Gemini returned an empty response.');
    }

    _contents
      ..clear()
      ..addAll(contents)
      ..add({
        'role': 'model',
        'parts': [
          {'text': answer},
        ],
      });
    return answer;
  }

  String _errorMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error'] is Map<String, dynamic>
          ? (data['error'] as Map<String, dynamic>)['message'] as String? ??
                'Request rejected.'
          : data['message'] as String? ?? 'Request rejected.';
    } on FormatException {
      debugPrint('Gemini backend returned a non-JSON error response.');
      return 'Request rejected.';
    }
  }

  void dispose() => _client.close();
}
