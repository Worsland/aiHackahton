import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/firebase/auth_service.dart';
import '../services/firebase/session_repository.dart';
import '../services/offline/offline_patient_brain.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width.dart';
import 'recap_screen.dart';

/// Étape finale de l'entretien : l'agent choisit un diagnostic parmi une
/// liste à choix multiples (le bon + des distracteurs plausibles), puis
/// arrive sur le récapitulatif ([RecapScreen]).
///
/// Le diagnostic étant toujours un QCM (jamais une réponse libre), sa
/// justesse se vérifie par une simple égalité de chaîne, dans les trois
/// modes de conversation (hors ligne, léger, Live) : pas besoin de Gemini
/// pour ça, contrairement à ce qu'on pensait au début.
class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({
    super.key,
    required this.clinicalInfo,
    required this.keyPoints,
    required this.agentUtterances,
    required this.scenarioTitle,
    required this.mode,
    this.sessionRepository,
  });

  final ScenarioClinicalInfo clinicalInfo;

  /// Les points clés du scénario (pour calculer le score de couverture
  /// dans le récapitulatif).
  final List<KeyPoint> keyPoints;

  /// Tout ce que l'agent a dit pendant l'entretien, peu importe le mode.
  final List<String> agentUtterances;

  /// Identifiant interne du scénario (pas le titre neutre affiché),
  /// enregistré avec le score pour permettre plus tard un historique par
  /// maladie.
  final String scenarioTitle;

  /// 'live' / 'light' / 'offline'.
  final String mode;

  /// Injectable pour les tests ; sinon une instance par défaut.
  final SessionRepository? sessionRepository;

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  late final List<String> _options = widget.clinicalInfo.shuffledOptions(
    math.Random(),
  );
  String? _selected;

  void _validate() {
    if (_selected == null) return;
    final scan = KeyPointScan.scan(widget.keyPoints, widget.agentUtterances);
    final correct = _selected == widget.clinicalInfo.correctDiagnosis;
    final score = SessionScore(scan: scan, diagnosisCorrect: correct);

    // Best-effort : la sauvegarde ne doit jamais retarder ni bloquer
    // l'affichage du récapitulatif, qui doit rester utilisable même hors
    // ligne ou si Firebase n'est pas configuré.
    unawaited(_saveSession(scan, correct, score));

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => RecapScreen(
          clinicalInfo: widget.clinicalInfo,
          scan: scan,
          score: score,
          selectedDiagnosis: _selected!,
        ),
      ),
    );
  }

  Future<void> _saveSession(
    KeyPointScan scan,
    bool diagnosisCorrect,
    SessionScore score,
  ) async {
    try {
      final uid =
          AuthService.instance.currentUser?.uid ??
          (await AuthService.instance.ensureSignedIn())?.uid;
      final repo = widget.sessionRepository ?? SessionRepository();
      await repo.save(
        uid,
        SessionRecord(
          scenarioTitle: widget.scenarioTitle,
          mode: widget.mode,
          scorePercent: score.percent,
          diagnosisCorrect: diagnosisCorrect,
          keyPointsHit: scan.hit.length,
          keyPointsTotal: scan.total,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Session non sauvegardée : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to the interview',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Make my diagnosis'),
      ),
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 720,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'Based on what the patient told you, what is your diagnosis?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: [
                    for (final option in _options)
                      _OptionCard(
                        label: option,
                        selected: _selected == option,
                        onTap: () => setState(() => _selected = option),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selected == null ? null : _validate,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Confirm my diagnosis'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: selected ? AppColors.primaryLight.withValues(alpha: 0.12) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}
