import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase/auth_service.dart';
import '../services/lang/app_language.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width.dart';

/// Un seul écran pour les deux cas :
///  - le compte courant est anonyme → proposer de le lier à un email
///    (garde toute la progression déjà faite sur cet appareil) ;
///  - un compte email existe déjà → afficher son statut, avec option de
///    se déconnecter.
///
/// Le formulaire "J'ai déjà un compte" (connexion, pas liaison) est
/// volontairement séparé : se connecter à un compte existant depuis un
/// appareil qui a un profil anonyme actif *remplace* ce profil anonyme,
/// sans fusionner sa progression — l'utilisateur doit le savoir avant de
/// valider, pas le découvrir après coup.
class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    this.language = AppLanguage.english,
  });

  final AppLanguage language;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

enum _FormMode { create, signIn }

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  _FormMode _mode = _FormMode.create;
  bool _busy = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) {
      return widget.language.isYoruba
          ? 'Tẹ àdírẹ́sì ímeèlì sí i.'
          : 'Enter an email.';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return widget.language.isYoruba
          ? 'Àdírẹ́sì ímeèlì yìí kò dà bí èyí tó tọ́.'
          : 'This email doesn\'t look valid.';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.length < 6) {
      return widget.language.isYoruba
          ? 'Ó kéré tán, lẹ́tà mẹ́fà ni ọ̀rọ̀ aṣínà gbọ́dọ̀ ní.'
          : 'At least 6 characters.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_mode == _FormMode.create) {
        await AuthService.instance.linkToEmail(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await AuthService.instance.signInWithEmail(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == _FormMode.create
                ? (widget.language.isYoruba
                      ? 'A ti dá àkọọ́lẹ̀ sílẹ̀; a ti fi ìlọsíwájú rẹ pamọ́.'
                      : 'Account created: your progress is now saved.')
                : (widget.language.isYoruba
                      ? 'O ti wọlé. A ti rọ́pò ìlọsíwájú ẹ̀rọ yìí pẹ̀lú ti àkọọ́lẹ̀ yìí.'
                      : 'Signed in. Your progress on this device has been replaced by that of this account.'),
          ),
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageFor(e));
    } catch (e) {
      setState(
        () => _error = widget.language.isYoruba
            ? 'Àṣìṣe kan ṣẹlẹ̀: $e'
            : 'Something went wrong: $e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        if (widget.language.isYoruba) {
          return _mode == _FormMode.create
              ? 'Àkọọ́lẹ̀ kan ti so mọ́ ímeèlì yìí. Wọlé dípò kí o tún ṣẹ̀dá àkọọ́lẹ̀.'
              : 'Àkọọ́lẹ̀ kan ti so mọ́ ímeèlì yìí, ṣùgbọ́n àṣìṣe míì ṣẹlẹ̀. Tún gbìyànjú.';
        }
        return _mode == _FormMode.create
            ? 'This email already has an account. Use "I already have an '
                  'account" to sign in instead.'
            : 'This email already has an account, but something else '
                  'failed. Please try again.';
      case 'invalid-credential':
      case 'wrong-password':
        return widget.language.isYoruba
            ? 'Ọ̀rọ̀ aṣínà kò tọ́.'
            : 'Incorrect password.';
      case 'user-not-found':
        if (widget.language.isYoruba) {
          return 'Kò sí àkọọ́lẹ̀ tó ní ímeèlì yìí. Ṣẹ̀dá àkọọ́lẹ̀ tuntun.';
        }
        return 'No account with this email. Use "Create my account" '
            'to make one.';
      case 'weak-password':
        return widget.language.isYoruba
            ? 'Ọ̀rọ̀ aṣínà yìí rọ̀ jù.'
            : 'This password is too weak.';
      case 'network-request-failed':
        if (widget.language.isYoruba) {
          return 'Kò sí ìsopọ̀; o kò lè ṣẹ̀dá àkọọ́lẹ̀ tàbí wọlé láìsí ayélujára. Tún gbìyànjú nígbà tí ìsopọ̀ bá wà.';
        }
        return 'No connection: you can\'t create or join an account '
            'offline. Please try again once you\'re online.';
      default:
        if (widget.language.isYoruba) {
          return 'Àṣìṣe kan ṣẹlẹ̀ (${e.code}). Tún gbìyànjú.';
        }
        return e.message ??
            'Something went wrong (${e.code}).';
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    // Redonne tout de suite un compte anonyme "frais" : l'app doit
    // toujours avoir un uid utilisable, y compris juste après déconnexion.
    await AuthService.instance.ensureSignedIn();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final linked = user != null && !user.isAnonymous;
    final yoruba = widget.language.isYoruba;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(yoruba ? 'Àkọọ́lẹ̀ mi' : 'My account'),
      ),
      body: SafeArea(
        child: ContentWidth(
          child: linked ? _buildLinked(context, user) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildLinked(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            user.email ??
                (widget.language.isYoruba
                    ? '(àkọọ́lẹ̀ láìsí ímeèlì)'
                    : '(account without email)'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            widget.language.isYoruba
                ? 'A ti fi ìlọsíwájú rẹ pamọ́ sínú àkọọ́lẹ̀ yìí; o lè rí i lórí ẹ̀rọ èyíkéyìí.'
                : 'Your progress is saved to this account and available from any device.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: Text(widget.language.isYoruba ? 'Jáde' : 'Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.cloud_sync_rounded,
          size: 40,
          color: AppColors.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 12),
        Text(
          _mode == _FormMode.create
              ? (widget.language.isYoruba
                    ? 'Fi ìlọsíwájú pamọ́'
                    : 'Save my progress')
              : (widget.language.isYoruba
                    ? 'Wọlé sí àkọọ́lẹ̀ mi'
                    : 'Sign in to my account'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          _mode == _FormMode.create
              ? (widget.language.isYoruba
                    ? 'Pa àmì àti ìtàn rẹ mọ́ bí o bá yí ẹ̀rọ padà tàbí tún fi ohun èlò náà sí i.'
                    : 'Keep your score and history even if you change device or reinstall the app.')
              : (widget.language.isYoruba
                    ? 'Gba ìlọsíwájú tó so mọ́ ímeèlì yìí padà. A kò ní so ìlọsíwájú ẹ̀rọ yìí pọ̀ mọ́ ọn.'
                    : 'Recover the progress already linked to this email — progress made on this device without an account will not be merged.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: widget.language.isYoruba ? 'Ímeèlì' : 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: widget.language.isYoruba
                      ? 'Ọ̀rọ̀ aṣínà'
                      : 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: _validatePassword,
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _mode == _FormMode.create
                          ? (widget.language.isYoruba
                                ? 'Ṣẹ̀dá àkọọ́lẹ̀ mi'
                                : 'Create my account')
                          : (widget.language.isYoruba ? 'Wọlé' : 'Sign in'),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _mode = _mode == _FormMode.create
                      ? _FormMode.signIn
                      : _FormMode.create;
                  _error = null;
                }),
          child: Text(
            _mode == _FormMode.create
                ? (widget.language.isYoruba
                      ? 'Mo ti ní àkọọ́lẹ̀ tẹ́lẹ̀'
                      : 'I already have an account')
                : (widget.language.isYoruba
                      ? 'Ṣẹ̀dá àkọọ́lẹ̀ dípò bẹ́ẹ̀'
                      : 'Create an account instead'),
          ),
        ),
      ],
    );
  }
}
