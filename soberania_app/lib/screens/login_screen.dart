import 'package:flutter/material.dart';

import '../api/xano_api.dart';
import '../storage/app_storage.dart';
import '../l10n/app_localizations.dart';
import '../ui/brand.dart';
import 'assessment_intro_screen.dart';
import 'phases_screen.dart';
import 'signup_screen.dart';
import 'reset_password_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(initialEmail: email),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = XanoApi();
      final res = await api.login(
        email: _email.text.trim(),
        password: _password.text,
      );

      final authToken = (res['authToken'] ?? '').toString();
      if (authToken.isEmpty) {
        throw StateError('authToken não retornou no /login');
      }

      final storage = AppStorage();
      await storage.setAuthToken(authToken);
      await storage.setUserEmail(_email.text.trim());
      final name = (res['user'] as Map?)?['name']?.toString() ??
          (res['admin_name'] ?? res['name'])?.toString() ??
          _email.text.split('@').first;
      await storage.setUserName(name);

      final assessment = await api.resumeAssessment(authToken: authToken);
      final assessmentId = (assessment['id'] as num).toInt();
      await storage.setAssessmentId(assessmentId);

      final introSeen = await storage.getIntroSeen();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              introSeen ? const PhasesScreen() : const AssessmentIntroScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro no login: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _pillButtonHeight = 38.0;

  /// Volta na pilha ou vai à tela inicial — após logout [LoginScreen] é a única rota e [maybePop] não faz nada.
  void _handleBackOrHome() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/pedrasluzjpg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/pedrasluzjpg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Brand.surface),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.34)),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _handleBackOrHome,
                              style: IconButton.styleFrom(
                                backgroundColor: Brand.white.withValues(alpha: 0.85),
                              ),
                              icon: const Icon(Icons.arrow_back, color: Brand.black),
                            ),
                            const Spacer(),
                            if (!isWide) const LanguageButton(),
                          ],
                        ),
                        const Spacer(),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Brand.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Brand.border),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 22,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SoftwareOneMark(size: 52),
                                        const SizedBox(width: 16),
                                        Container(width: 1, height: 36, color: Brand.border),
                                        const SizedBox(width: 16),
                                        const AwsMark(size: 52),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      l10n.t('login_welcome_title'),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Brand.black,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.t('login_subtitle'),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.black54,
                                          ),
                                    ),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: l10n.t('login_email_label'),
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (v) {
                                        final t = (v ?? '').trim();
                                        if (t.isEmpty) return l10n.t('login_email_required');
                                        if (!t.contains('@')) return l10n.t('login_email_invalid');
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _password,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: l10n.t('login_password_label'),
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Mostrar senha'
                                              : 'Ocultar senha',
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _obscurePassword = !_obscurePassword,
                                            );
                                          },
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (v) {
                                        if ((v ?? '').isEmpty) {
                                          return l10n.t('login_password_required');
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: _pillButtonHeight,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Brand.black,
                                          foregroundColor: Brand.white,
                                          padding: EdgeInsets.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        ),
                                        onPressed: _loading ? null : _submit,
                                        child: _loading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : Text(l10n.t('btn_login')),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: _pillButtonHeight,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Brand.white,
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: Brand.border),
                                        ),
                                        child: Material(
                                          type: MaterialType.transparency,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(999),
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => const SignupScreen(),
                                                ),
                                              );
                                            },
                                            child: Center(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(
                                                  l10n.t('no_account'),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Brand.black,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: _pillButtonHeight,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(999),
                                          gradient: const LinearGradient(
                                            colors: [Colors.black, Colors.white],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(999),
                                          onTap: _loading ? null : _forgotPassword,
                                          child: Center(
                                            child: Text(
                                              l10n.t('login_forgot_password'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                if (isWide)
                  Container(
                    width: 360,
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                    color: Brand.white.withValues(alpha: 0.95),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Align(
                          alignment: Alignment.topRight,
                          child: LanguageButton(),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          l10n.t('right_panel_title'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Brand.black,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.t('right_panel_intro'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Brand.black.withValues(alpha: 0.82),
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.t('right_panel_topics'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Brand.black.withValues(alpha: 0.82),
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!isWide)
            const SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 8, top: 8),
                  child: LanguageButton(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
