import 'package:flutter/material.dart';

import '../api/backend_api.dart';
import '../l10n/app_localizations.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import '../screens/admin_screen.dart';
import '../screens/assessment_intro_screen.dart';
import '../screens/phases_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/signup_screen.dart';

/// Formulário de login (e‑mail, senha, Entrar, ação secundária, recuperar senha).
/// Usado na [WelcomeScreen] e na [LoginScreen].
class LoginCardForm extends StatefulWidget {
  const LoginCardForm({
    super.key,
    required this.variant,
    required this.secondaryLabel,
    this.initialAdminMode = false,
  });

  final LoginCardVariant variant;
  final String secondaryLabel;
  final bool initialAdminMode;

  @override
  State<LoginCardForm> createState() => _LoginCardFormState();
}

enum LoginCardVariant { welcome, standalone }

class _LoginCardFormState extends State<LoginCardForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  late bool _isAdminMode;

  @override
  void initState() {
    super.initState();
    _isAdminMode = widget.initialAdminMode;
  }

  static const _pillButtonHeight = 38.0;

  ButtonStyle _pillButtonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
    BorderSide side = BorderSide.none,
  }) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.0,
        );
    return FilledButton.styleFrom(
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: backgroundColor.withValues(alpha: 0.38),
      disabledForegroundColor: foregroundColor.withValues(alpha: 0.38),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(0, _pillButtonHeight),
      maximumSize: Size.fromHeight(_pillButtonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: side,
      ),
      textStyle: textStyle,
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(initialEmail: email),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = BackendApi();
      final res = await api.login(
        email: _email.text.trim(),
        password: _password.text,
      );

      final authToken = (res['authToken'] ?? '').toString();
      if (authToken.isEmpty) {
        throw StateError('authToken não retornou no /login');
      }

      final role = (res['user'] as Map?)?['role']?.toString() ??
          res['role']?.toString() ?? 'user';

      // Aba Admin: valida que a conta tem permissão
      if (_isAdminMode && role != 'admin') {
        throw StateError('Esta conta não tem acesso de administrador.');
      }

      final storage = AppStorage();
      await storage.setAuthToken(authToken);
      await storage.setUserEmail(_email.text.trim());
      final name = (res['user'] as Map?)?['name']?.toString() ??
          (res['admin_name'] ?? res['name'])?.toString() ??
          _email.text.split('@').first;
      await storage.setUserName(name);
      await storage.setUserRole(role);

      if (!mounted) return;

      // Aba Admin → painel admin
      if (_isAdminMode) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
        return;
      }

      // Aba Usuário → fluxo normal de assessment (mesmo para conta admin)
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWelcome = widget.variant == LoginCardVariant.welcome;
    final logoSize = isWelcome ? 56.0 : 52.0;
    final dividerH = isWelcome ? 40.0 : 36.0;
    final isAdmin = _isAdminMode;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SoftwareOneMark(size: logoSize),
              SizedBox(width: isWelcome ? 18 : 16),
              Container(width: 1, height: dividerH, color: Brand.border),
              SizedBox(width: isWelcome ? 18 : 16),
              AwsMark(size: logoSize),
            ],
          ),
          SizedBox(height: isWelcome ? 16 : 12),

          // Título adaptado por modo
          if (isAdmin) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Brand.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Brand.black.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 18, color: Brand.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Acesso restrito — apenas administradores',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Brand.black.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Text(
              l10n.t('login_welcome_title'),
              textAlign: TextAlign.center,
              style: isWelcome
                  ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Brand.black,
                      )
                  : Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Brand.black,
                      ),
            ),
            if (!isWelcome) ...[
              const SizedBox(height: 6),
              Text(
                l10n.t('login_subtitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
              ),
            ],
            const SizedBox(height: 14),
          ],

          // Campo e-mail
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.t('login_email_label'),
              border: const OutlineInputBorder(),
              prefixIcon: isAdmin
                  ? const Icon(Icons.alternate_email, size: 18)
                  : null,
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return l10n.t('login_email_required');
              if (!t.contains('@')) return l10n.t('login_email_invalid');
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Campo senha
          TextFormField(
            controller: _password,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.t('login_password_label'),
              prefixIcon: isAdmin
                  ? const Icon(Icons.lock_outline, size: 18)
                  : null,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
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

          // Botão entrar (cor muda no modo admin)
          SizedBox(
            width: double.infinity,
            height: _pillButtonHeight,
            child: FilledButton(
              style: _pillButtonStyle(
                backgroundColor:
                    isAdmin ? Brand.black : Brand.primaryCtaBlue,
                foregroundColor: Brand.white,
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Brand.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isAdmin) ...[
                          const Icon(Icons.admin_panel_settings,
                              size: 16),
                          const SizedBox(width: 6),
                        ],
                        Text(isAdmin
                            ? 'Entrar como Administrador'
                            : l10n.t('btn_login')),
                      ],
                    ),
            ),
          ),

          // Ações secundárias só no modo usuário
          if (!isAdmin) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: _pillButtonHeight,
              child: FilledButton(
                style: _pillButtonStyle(
                  backgroundColor: Brand.black,
                  foregroundColor: Brand.white,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignupScreen(),
                    ),
                  );
                },
                child:
                    Text(widget.secondaryLabel, textAlign: TextAlign.center),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: _pillButtonHeight,
            child: FilledButton(
              style: _pillButtonStyle(
                backgroundColor: Brand.white,
                foregroundColor: Brand.black,
                side: const BorderSide(color: Brand.border),
              ),
              onPressed: _loading ? null : _forgotPassword,
              child: Text(l10n.t('login_forgot_password')),
            ),
          ),
        ],
      ),
    );
  }
}
