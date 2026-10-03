import 'package:flutter/material.dart';

import '../services/offline/offline_patient_brain.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width.dart';

/// Dernier écran de la session : ce que le récap doit toujours montrer,
/// dans les trois modes, puisque le contenu clinique (diagnostic, signaux,
/// symptômes, conduite à tenir) est statique par scénario et ne dépend pas
/// du mode utilisé pour la conversation.
class RecapScreen extends StatelessWidget {
  const RecapScreen({
    super.key,
    required this.clinicalInfo,
    required this.scan,
    required this.score,
    required this.selectedDiagnosis,
  });

  final ScenarioClinicalInfo clinicalInfo;
  final KeyPointScan scan;
  final SessionScore score;
  final String selectedDiagnosis;

  bool get _diagnosisCorrect => score.diagnosisCorrect;

  @override
  Widget build(BuildContext context) {
    final scoreColor = score.percent >= 70
        ? AppColors.success
        : score.percent >= 40
        ? AppColors.secondary
        : Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to the interview',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Summary'),
      ),
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _ScoreHeader(percent: score.percent, color: scoreColor),
              const SizedBox(height: 24),
              _DiagnosisResult(
                correct: _diagnosisCorrect,
                selected: selectedDiagnosis,
                correctDiagnosis: clinicalInfo.correctDiagnosis,
              ),
              const SizedBox(height: 24),
              _Section(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.success,
                title: 'Relevant questions asked',
                child: scan.hit.isEmpty
                    ? const _EmptyNote(
                        'No key point was covered during this interview.',
                      )
                    : Column(
                        children: [
                          for (final k in scan.hit)
                            _BulletLine(text: k.label, critical: k.critical),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              _Section(
                icon: Icons.report_gmailerrorred_rounded,
                iconColor: Colors.redAccent,
                title: 'Patient warning signs',
                child: Column(
                  children: [
                    for (final a in clinicalInfo.alertSigns)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ${a.trigger}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 14, top: 2),
                              child: Text(
                                a.cause,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (scan.missed.isNotEmpty) ...[
                const SizedBox(height: 20),
                _Section(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.secondary,
                  title: 'Don\'t forget next time',
                  child: Column(
                    children: [
                      for (final k in scan.missed)
                        _BulletLine(text: k.label, critical: k.critical),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _Section(
                icon: Icons.medical_information_outlined,
                iconColor: AppColors.primary,
                title: clinicalInfo.correctDiagnosis,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Typical symptoms',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(clinicalInfo.symptoms.join(' · ')),
                    const SizedBox(height: 14),
                    Text(
                      'Recommended action',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(clinicalInfo.management),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Back to scenarios'),
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

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.percent, required this.color});
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$percent%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Session score', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DiagnosisResult extends StatelessWidget {
  const _DiagnosisResult({
    required this.correct,
    required this.selected,
    required this.correctDiagnosis,
  });

  final bool correct;
  final String selected;
  final String correctDiagnosis;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'Correct diagnosis' : 'Diagnosis to review',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Your answer: $selected'),
                if (!correct) Text('Expected answer: $correctDiagnosis'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, required this.critical});
  final String text;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
          if (critical)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(
                Icons.priority_high_rounded,
                size: 16,
                color: Colors.redAccent,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
    );
  }
}
