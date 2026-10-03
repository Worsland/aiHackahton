import 'package:flutter/material.dart';

import '../services/firebase/auth_service.dart';
import '../services/firebase/session_repository.dart';
import '../services/offline/offline_scenarios.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width.dart';
import 'account_screen.dart';

/// Petit formatage de date sans dépendance externe (pas besoin du package
/// `intl` juste pour ça) : "Oct 3, 14:05".
String _formatDate(DateTime d) {
  const months = [
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
  const ProgressScreen({super.key, this.sessionRepository});

  final SessionRepository? sessionRepository;

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
    ).push(MaterialPageRoute(builder: (context) => const AccountScreen()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to scenarios',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My progress'),
        actions: [
          IconButton(
            icon: Icon(
              AuthService.instance.isAnonymous
                  ? Icons.person_add_alt_1_rounded
                  : Icons.person_rounded,
            ),
            tooltip: AuthService.instance.isAnonymous
                ? 'Save my progress'
                : 'My account',
            onPressed: _openAccount,
          ),
        ],
      ),
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 720,
          child: uid == null
              ? const _NoAccount()
              : StreamBuilder<List<SessionRecord>>(
                  stream: (widget.sessionRepository ?? SessionRepository())
                      .watchHistory(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const _LoadError();
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final sessions = snapshot.data!;
                    if (sessions.isEmpty) {
                      return const _EmptyHistory();
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        if (AuthService.instance.isAnonymous)
                          _SaveProgressBanner(onTap: _openAccount),
                        _StatsHeader(sessions: sessions),
                        const SizedBox(height: 24),
                        Text(
                          'History',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        for (final s in sessions) _SessionTile(session: s),
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
  const _SaveProgressBanner({required this.onTap});
  final VoidCallback onTap;

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
                    'Create an account to keep this progress on another '
                    'device.',
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
  const _StatsHeader({required this.sessions});
  final List<SessionRecord> sessions;

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
            label: 'Average score',
            value: '${avg.round()}%',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Correct diagnoses',
            value: '${(diagnosisRate * 100).round()}%',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Sessions',
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
  const _SessionTile({required this.session});
  final SessionRecord session;

  static const _modeLabels = {
    'live': 'Natural voice',
    'light': 'Light',
    'offline': 'Offline',
  };

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
              )?.clinicalInfo.displayTitle ??
              session.scenarioTitle,
        ),
        subtitle: Text(
          [
            _modeLabels[session.mode] ?? session.mode,
            if (date != null) _formatDate(date),
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
  const _EmptyHistory();

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
              'No completed session yet.\nRun an interview through to the '
              'diagnosis to see your progress here.',
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
  const _NoAccount();

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
              'Connection unavailable for now: your progress can\'t be '
              'loaded. It is still saved as soon as a session ends, and '
              'will appear here once you\'re back online.',
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
  const _LoadError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Unable to load your progress right now.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
