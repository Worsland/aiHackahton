import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase/auth_service.dart';
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
  const AccountScreen({super.key});

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
    if (value.isEmpty) return 'Enter an email.';
    if (!value.contains('@') || !value.contains('.')) {
      return 'This email doesn\'t look valid.';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.length < 6) return 'At least 6 characters.';
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
                ? 'Account created: your progress is now saved.'
                : 'Signed in. Your progress on this device has been replaced '
                      'by that of this account.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageFor(e));
    } catch (e) {
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return _mode == _FormMode.create
            ? 'This email already has an account. Use "I already have an '
                  'account" to sign in instead.'
            : 'This email already has an account, but something else '
                  'failed. Please try again.';
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-not-found':
        return 'No account with this email. Use "Create my account" '
            'to make one.';
      case 'weak-password':
        return 'This password is too weak.';
      case 'network-request-failed':
        return 'No connection: you can\'t create or join an account '
            'offline. Please try again once you\'re online.';
      default:
        return e.message ?? 'Something went wrong (${e.code}).';
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My account'),
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
            user.email ?? '(account without email)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Your progress is saved to this account and available from '
            'any device.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
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
              ? 'Save my progress'
              : 'Sign in to my account',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          _mode == _FormMode.create
              ? 'Keep your score and history even if you change device '
                    'or reinstall the app.'
              : 'Recover the progress already linked to this email — '
                    'progress made on this device without an account will '
                    'not be merged.',
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
                decoration: const InputDecoration(
                  labelText: 'Email',
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
                  labelText: 'Password',
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
                          ? 'Create my account'
                          : 'Sign in',
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
                ? 'I already have an account'
                : 'Create an account instead',
          ),
        ),
      ],
    );
  }
}
