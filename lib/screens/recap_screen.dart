import 'package:flutter/material.dart';

import '../services/lang/app_language.dart';
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
    this.language = AppLanguage.english,
  });

  final ScenarioClinicalInfo clinicalInfo;
  final KeyPointScan scan;
  final SessionScore score;
  final String selectedDiagnosis;
  final AppLanguage language;

  bool get _diagnosisCorrect => score.diagnosisCorrect;

  @override
  Widget build(BuildContext context) {
    final yoruba = language.isYoruba;
    final scoreColor = score.percent >= 70
        ? AppColors.success
        : score.percent >= 40
        ? AppColors.secondary
        : Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: yoruba ? 'Padà sí ìfọ̀rọ̀wánilẹ́nuwò' : 'Back to the interview',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(yoruba ? 'Àkótán' : 'Summary'),
      ),
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              if (yoruba) ...[
                Card(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Àkóónú Yorùbá yìí ṣì jẹ́ àkọ́kọ́; a kò tíì fọwọ́ sí i fún ìlera.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _ScoreHeader(
                percent: score.percent,
                color: scoreColor,
                language: language,
              ),
              const SizedBox(height: 24),
              _DiagnosisResult(
                correct: _diagnosisCorrect,
                selected: selectedDiagnosis,
                correctDiagnosis: clinicalInfo.correctDiagnosis,
                language: language,
              ),
              const SizedBox(height: 24),
              _Section(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.success,
                title: yoruba
                    ? 'Àwọn ìbéèrè tó yẹ tí a béèrè'
                    : 'Relevant questions asked',
                child: scan.hit.isEmpty
                    ? _EmptyNote(
                        yoruba
                            ? 'A kò béèrè nípa kókó pàtàkì kankan.'
                            : 'No key point was covered during this interview.',
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
                title: yoruba ? 'Àwọn àmì ewu aláìsàn' : 'Patient warning signs',
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
                  title: yoruba
                      ? 'Má gbàgbé ní ìgbà tó ń bọ̀'
                      : 'Don\'t forget next time',
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
                      yoruba ? 'Àwọn àmì àìsàn tó wọ́pọ̀' : 'Typical symptoms',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(clinicalInfo.symptoms.join(' · ')),
                    const SizedBox(height: 14),
                    Text(
                      yoruba ? 'Ìgbésẹ̀ tí a dámọ̀ràn' : 'Recommended action',
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      yoruba ? 'Padà sí àwọn àpẹẹrẹ' : 'Back to scenarios',
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

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({
    required this.percent,
    required this.color,
    required this.language,
  });
  final int percent;
  final Color color;
  final AppLanguage language;

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
          Text(
            language.isYoruba ? 'Àmì ìdánilẹ́kọ̀ọ́' : 'Session score',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
    required this.language,
  });

  final bool correct;
  final String selected;
  final String correctDiagnosis;
  final AppLanguage language;

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
                  language.isYoruba
                      ? (correct ? 'Àyẹ̀wò tó tọ́' : 'Àyẹ̀wò láti tún wò')
                      : (correct ? 'Correct diagnosis' : 'Diagnosis to review'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  language.isYoruba
                      ? 'Ìdáhùn rẹ: $selected'
                      : 'Your answer: $selected',
                ),
                if (!correct)
                  Text(
                    language.isYoruba
                        ? 'Ìdáhùn tó tọ́: $correctDiagnosis'
                        : 'Expected answer: $correctDiagnosis',
                  ),
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
