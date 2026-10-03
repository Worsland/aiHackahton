import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firebase/auth_service.dart';
import '../services/firebase/user_profile_service.dart';
import '../services/lang/app_language.dart';
import '../services/offline/offline_scenarios.dart';
import '../services/patient_scenario.dart';
import '../services/scenario_catalog.dart';
import '../services/scenario_score_board.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width.dart';
import 'account_screen.dart';

/// Titre neutre affiché à l'utilisateur (jamais l'identifiant interne du
/// scénario, qui peut trahir le diagnostic) — même règle que dans
/// `simulation_screen.dart`, dupliquée ici pour ne pas exposer un symbole
/// privé d'un autre fichier.
String _displayTitle(String internalTitle) =>
    OfflineScenarios.forTitle(internalTitle)?.clinicalInfo.displayTitle ??
    internalTitle;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.language = AppLanguage.english});

  final AppLanguage language;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = UserProfileService();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String? _uid;
  String? _photoBase64;
  bool _seeded = false;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _uid = AuthService.instance.currentUser?.uid;
    _firstNameController.addListener(_markDirty);
    _lastNameController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final yoruba = widget.language.isYoruba;
    final picker = ImagePicker();
    final XFile? file;
    try {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        // Suffisant pour un avatar, et ça garde le document Firestore
        // largement sous sa limite de 1 Mo une fois encodé en base64.
        maxWidth: 320,
        maxHeight: 320,
        imageQuality: 70,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            yoruba ? 'A kò lè ṣí àwòrán: $e' : 'Could not open the gallery: $e',
          ),
        ),
      );
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    setState(() => _photoBase64 = encoded);

    // La photo se sauvegarde tout de suite, contrairement au prénom/nom qui
    // attendent "Save changes" : choisir une photo est une action complète
    // en elle-même, l'utilisateur ne doit pas la perdre en quittant l'écran
    // juste après sans avoir pensé à valider (c'est ce qui se passait
    // avant : l'aperçu changeait localement, mais rien n'était encore
    // écrit dans Firestore).
    final uid = _uid;
    if (uid == null) return;
    final ok = await _service.save(
      uid,
      UserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        photoBase64: encoded,
      ),
    );
    if (!mounted) return;
    if (ok) {
      // Le prénom/nom actuels partent dans le même document que la photo
      // (voir plus haut) : ils sont donc sauvegardés aussi, plus besoin du
      // bouton "Save changes" pour eux tant qu'ils ne changent pas encore.
      setState(() => _dirty = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language.isYoruba
                ? 'A kò lè fi àwòrán pamọ́. Jọ̀ọ́ tún gbìyànjú.'
                : 'Could not save the photo. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _saving = true);
    final ok = await _service.save(
      uid,
      UserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        photoBase64: _photoBase64,
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.language.isYoruba
              ? (ok
                    ? 'A ti fi profaili pamọ́.'
                    : 'A kò lè fi pamọ́. Tún gbìyànjú.')
              : (ok ? 'Profile saved.' : 'Could not save. Please try again.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.language.isYoruba ? 'Profaili mi' : 'My profile'),
      ),
      body: SafeArea(
        child: _uid == null
            ? _NoAccount(language: widget.language)
            : StreamBuilder<UserProfile>(
                stream: _service.watch(_uid!),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  // On ne recopie les champs dans les controllers qu'une
                  // seule fois : sinon, chaque écho Firestore après notre
                  // propre sauvegarde écraserait ce que l'utilisateur est
                  // en train de taper.
                  if (profile != null && !_seeded) {
                    _firstNameController.text = profile.firstName;
                    _lastNameController.text = profile.lastName;
                    _photoBase64 = profile.photoBase64;
                    _seeded = true;
                  }
                  return ContentWidth(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      children: [
                        _buildIdentityCard(context),
                        const SizedBox(height: 28),
                        _buildScoresSection(context),
                        const SizedBox(height: 28),
                        _buildAccountLink(context),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context) {
    final yoruba = widget.language.isYoruba;
    return Column(
      children: [
        GestureDetector(
          onTap: _pickPhoto,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: _photoBase64 == null
                    ? null
                    : MemoryImage(base64Decode(_photoBase64!)),
                child: _photoBase64 != null
                    ? null
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: yoruba ? 'Orúkọ àkọ́kọ́' : 'First name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: yoruba ? 'Orúkọ ìdílé' : 'Last name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: (_dirty && !_saving) ? _save : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(yoruba ? 'Fi àwọn àyípadà pamọ́' : 'Save changes'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoresSection(BuildContext context) {
    return ListenableBuilder(
      listenable: ScenarioScoreBoard.instance,
      builder: (context, _) {
        final scores = ScenarioScoreBoard.instance.scores;
        final scenarios = ScenarioCatalog.instance.scenarios;
        // Garde l'ordre de la page principale plutôt que celui,
        // arbitraire, de la map de scores.
        final played = <PatientScenario>[
          for (final s in scenarios)
            if (scores.containsKey(s.title)) s,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.language.isYoruba ? 'Àmì rẹ' : 'Your scores',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            if (played.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  widget.language.isYoruba
                      ? 'O kò tíì parí àpẹẹrẹ kankan. Àmì tó dára jù fún ọkọọkan yóò hàn níbí.'
                      : 'No scenario completed yet. Your best score on each one will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else ...[
              _buildScoreSummary(context, scores, played),
              const SizedBox(height: 8),
              for (final s in played)
                _ScoreRow(
                  scenario: s,
                  score: scores[s.title]!,
                  language: widget.language,
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildScoreSummary(
    BuildContext context,
    Map<String, ScenarioBestScore> scores,
    List<PatientScenario> played,
  ) {
    final totalAttempts = played.fold<int>(
      0,
      (sum, s) => sum + scores[s.title]!.attempts,
    );
    final averageBest =
        played.fold<int>(0, (sum, s) => sum + scores[s.title]!.bestPercent) /
        played.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _SummaryStat(
            label: widget.language.isYoruba
                ? 'Àwọn àpẹẹrẹ tí a ṣe'
                : 'Scenarios played',
            value: '${played.length}',
          ),
          _SummaryStat(
            label: widget.language.isYoruba
                ? 'Àpapọ̀ ìgbìyànjú'
                : 'Total attempts',
            value: '$totalAttempts',
          ),
          _SummaryStat(
            label: widget.language.isYoruba
                ? 'Àpapọ̀ àmì tó ga jù'
                : 'Average best',
            value: '${averageBest.round()}%',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountLink(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final linked = user != null && !user.isAnonymous;
    return OutlinedButton.icon(
      icon: Icon(
        linked ? Icons.verified_user_outlined : Icons.cloud_sync_outlined,
      ),
      label: Text(
        linked
            ? (widget.language.isYoruba
                  ? 'Ṣàkóso ìwọlé mi (${user.email})'
                  : 'Manage my sign-in (${user.email})')
            : (widget.language.isYoruba
                  ? 'Fi ìlọsíwájú pamọ́ sínú àkọọ́lẹ̀'
                  : 'Save my progress to an account'),
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AccountScreen(language: widget.language),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 2),
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

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.scenario,
    required this.score,
    required this.language,
  });
  final PatientScenario scenario;
  final ScenarioBestScore score;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              OfflineScenarios.forTitle(
                    scenario.title,
                    language: language,
                  )?.clinicalInfo.displayTitle ??
                  _displayTitle(scenario.title),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${score.bestPercent}%',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Text(
            language.isYoruba
                ? '· Ìgbìyànjú ${score.attempts}'
                : '· ${score.attempts} ${score.attempts > 1 ? 'tries' : 'try'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
        padding: const EdgeInsets.all(24),
        child: Text(
          language.isYoruba
              ? 'Kò tíì sí àkọọ́lẹ̀. Ṣí ohun èlò náà pẹ̀lú ìsopọ̀ lẹ́ẹ̀kan kí a lè dá ìgbà ìwọlé sílẹ̀, lẹ́yìn náà padà síbí.'
              : 'No account yet. Open the app once with a connection so it can create your session, then come back here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
