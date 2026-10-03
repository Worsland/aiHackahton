import 'package:flutter/material.dart';

import '../services/firebase/auth_service.dart';
import '../services/firebase/session_repository.dart';
import '../services/lang/app_language.dart';
import '../services/offline/offline_scenarios.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width.dart';
import 'account_screen.dart';

/// Petit formatage de date sans dépendance externe (pas besoin du package
/// `intl` juste pour ça) : "Oct 3, 14:05".
String _formatDate(DateTime d, AppLanguage language) {
  final months = language.isYoruba
      ? const [
          'Sẹ́rẹ́',
          'Èrèlé',
          'Ẹrẹ̀nà',
          'Ìgbé',
          'Ẹ̀bibi',
          'Òkúdù',
          'Agẹmọ',
          'Ògún',
          'Owewe',
          'Ọ̀wàrà',
          'Bélú',
          'Ọ̀pẹ̀',
        ]
      : const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
        ];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${months[d.month - 1]} ${d.day}, $hh:$mm';
}

/// Historique des sessions de l'agent, avec quelques statistiques
/// agrégées calculées côté client à partir des dernières sessions
/// (`SessionRepository.watchHistory`) — pas de requête d'agrégation
/// Firestore dédiée, la limite de 50 sessions suffit largement pour un
/// usage d'entraînement individuel.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.sessionRepository, this.language = AppLanguage.english});

  final SessionRepository? sessionRepository;
  final AppLanguage language;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  /// Rouvre l'écran compte, puis rafraîchit cet écran au retour : le
  /// statut anonyme/lié a pu changer (compte créé, connecté, déconnecté),
  /// ce qui doit mettre à jour l'icône et le bandeau.
  Future<void> _openAccount() async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder: (context) => AccountScreen(language: widget.language),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;
    final yoruba = widget.language.isYoruba;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: yoruba ? 'Padà sí àwọn àpẹẹrẹ' : 'Back to scenarios',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(yoruba ? 'Ìlọsíwájú mi' : 'My progress'),
        actions: [
          IconButton(
            icon: Icon(
              AuthService.instance.isAnonymous
                  ? Icons.person_add_alt_1_rounded
                  : Icons.person_rounded,
            ),
            tooltip: AuthService.instance.isAnonymous
                ? (yoruba ? 'Fi ìlọsíwájú mi pamọ́' : 'Save my progress')
                : (yoruba ? 'Àkọọ́lẹ̀ mi' : 'My account'),
            onPressed: _openAccount,
          ),
        ],
      ),
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 720,
          child: uid == null
              ? _NoAccount(language: widget.language)
              : StreamBuilder<List<SessionRecord>>(
                  stream: (widget.sessionRepository ?? SessionRepository())
                      .watchHistory(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _LoadError(language: widget.language);
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final sessions = snapshot.data!;
                    if (sessions.isEmpty) {
                      return _EmptyHistory(language: widget.language);
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        if (AuthService.instance.isAnonymous)
                          _SaveProgressBanner(
                            onTap: _openAccount,
                            language: widget.language,
                          ),
                        _StatsHeader(
                          sessions: sessions,
                          language: widget.language,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          yoruba ? 'Ìtàn ìdánilẹ́kọ̀ọ́' : 'History',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        for (final s in sessions)
                          _SessionTile(session: s, language: widget.language),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _SaveProgressBanner extends StatelessWidget {
  const _SaveProgressBanner({required this.onTap, required this.language});
  final VoidCallback onTap;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    language.isYoruba
                        ? 'Ṣẹ̀dá àkọọ́lẹ̀ kí ìlọsíwájú yìí lè wà lórí ẹ̀rọ míì.'
                        : 'Create an account to keep this progress on another device.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.sessions, required this.language});
  final List<SessionRecord> sessions;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final avg =
        sessions.map((s) => s.scorePercent).reduce((a, b) => a + b) /
        sessions.length;
    final diagnosisRate =
        sessions.where((s) => s.diagnosisCorrect).length / sessions.length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: language.isYoruba ? 'Àpapọ̀ àmì' : 'Average score',
            value: '${avg.round()}%',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: language.isYoruba ? 'Àyẹ̀wò tó tọ́' : 'Correct diagnoses',
            value: '${(diagnosisRate * 100).round()}%',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: language.isYoruba ? 'Ìdánilẹ́kọ̀ọ́' : 'Sessions',
            value: '${sessions.length}',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.language});
  final SessionRecord session;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final color = session.scorePercent >= 70
        ? AppColors.success
        : session.scorePercent >= 40
        ? AppColors.secondary
        : Colors.redAccent;
    final date = session.completedAt;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      color: AppColors.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            '${session.scorePercent}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          OfflineScenarios.forTitle(
                session.scenarioTitle,
                language: language,
              )?.clinicalInfo.displayTitle ??
              session.scenarioTitle,
        ),
        subtitle: Text(
          [
            language.isYoruba
                ? switch (session.mode) {
                    'live' => 'Ohùn lórí ayélujára',
                    'light' => 'Rọrùn',
                    'offline' => 'Láìsí ayélujára',
                    _ => session.mode,
                  }
                : switch (session.mode) {
                    'live' => 'Natural voice',
                    'light' => 'Light',
                    'offline' => 'Offline',
                    _ => session.mode,
                  },
            if (date != null) _formatDate(date, language),
          ].join(' · '),
        ),
        trailing: Icon(
          session.diagnosisCorrect
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
          color: session.diagnosisCorrect
              ? AppColors.success
              : Colors.redAccent,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.language});
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              language.isYoruba
                  ? 'O kò tíì parí ìdánilẹ́kọ̀ọ́ kankan.\nParí ìfọ̀rọ̀wánilẹ́nuwò kan kí o lè rí ìlọsíwájú rẹ.'
                  : 'No completed session yet.\nRun an interview through to the diagnosis to see your progress here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAccount extends StatelessWidget {
  const _NoAccount({required this.language});
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              language.isYoruba
                  ? 'Kò sí ìsopọ̀ báyìí, a kò lè ṣí ìlọsíwájú rẹ. A ó fi ìlọsíwájú pamọ́ nígbà tí ìdánilẹ́kọ̀ọ́ bá parí; yóò hàn nígbà tí ìsopọ̀ bá padà.'
                  : 'Connection unavailable for now: your progress can\'t be loaded. It is still saved as soon as a session ends, and will appear here once you\'re back online.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.language});
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          language.isYoruba
              ? 'A kò lè ṣí ìlọsíwájú rẹ báyìí.'
              : 'Unable to load your progress right now.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
