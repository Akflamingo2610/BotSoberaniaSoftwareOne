import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/xano_api.dart';
import '../storage/app_storage.dart';
import '../l10n/app_localizations.dart';
import '../ui/brand.dart';
import 'assessment_intro_screen.dart';
import 'login_screen.dart';

/// Tela de cadastro (primeira vez) conectada ao endpoint signup_company do Xano.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _companyName = TextEditingController();
  final _role = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _marketingConsent = false;

  static const String _privacyUrl =
      'https://www.softwareone.com/en/privacy-statement';

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _companyName.dispose();
    _role.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = XanoApi();
      final res = await api.signupCompany(
        name: _name.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.replaceAll(RegExp(r'[^\d]'), ''),
        companyName: _companyName.text.trim(),
        role: _role.text.trim().isEmpty ? null : _role.text.trim(),
        password: _password.text,
      );

      final authToken = (res['authToken'] ?? '').toString();
      if (authToken.isEmpty) {
        throw StateError('authToken não retornou no cadastro');
      }

      final storage = AppStorage();
      await storage.setAuthToken(authToken);
      await storage.setUserEmail(_email.text.trim());
      await storage.setUserName(_name.text.trim());

      final assessment = await api.resumeAssessment(authToken: authToken);
      final assessmentId = (assessment['id'] as num).toInt();
      await storage.setAssessmentId(assessmentId);

      // Conta nova sempre vai para a introdução do Assessment
      await storage.setIntroSeen(false);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AssessmentIntroScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).t('signup_register_error')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Mesmo padrão do [LoginScreen]: volta na pilha ou abre o login se não houver rota anterior.
  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Cor escura alinhada ao fundo de folhas — evita faixa clara (tema / web) atrás do Stack.
    const bgFallback = Color(0xFF0B120B);

    return Scaffold(
      backgroundColor: bgFallback,
      extendBody: true,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/signup_bg_custom.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: bgFallback),
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.34)),
            ),
            SafeArea(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            // Ligeiramente acima do centro (como na referência), sem seta no card.
                            child: Align(
                              alignment: const Alignment(0, -0.26),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: Card(
                                  elevation: 0,
                                  color: Brand.white.withValues(alpha: 0.94),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(color: Brand.border),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _marketingConsent,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (v) {
                                      setState(() {
                                        _marketingConsent = v ?? false;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context).t(
                                    'signup_marketing_consent',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          _PrivacyPolicyText(privacyUrl: _privacyUrl),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .t('signup_already_have'),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black54),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        inputDecorationTheme: Theme.of(context)
                                            .inputDecorationTheme
                                            .copyWith(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                            ),
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              l10n.t('signup_heading'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: Brand.black,
                                                    fontSize: 22,
                                                    height: 1.2,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              l10n.t('signup_subtitle'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.black54,
                                                    height: 1.35,
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            TextFormField(
                                              controller: _name,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              decoration: InputDecoration(
                                                labelText: l10n.t(
                                                  'signup_name_label',
                                                ),
                                                hintText: l10n.t(
                                                  'signup_name_hint',
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                              validator: (v) {
                                                final t = (v ?? '').trim();
                                                if (t.isEmpty) {
                                                  return l10n.t(
                                                    'signup_name_required',
                                                  );
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _lastName,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              decoration: InputDecoration(
                                                labelText: l10n.t(
                                                  'signup_lastname_label',
                                                ),
                                                hintText: l10n.t(
                                                  'signup_lastname_hint',
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                              validator: (v) {
                                                final t = (v ?? '').trim();
                                                if (t.isEmpty) {
                                                  return l10n.t(
                                                    'signup_lastname_required',
                                                  );
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _email,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              decoration: InputDecoration(
                                                labelText: l10n.t(
                                                  'signup_email_label',
                                                ),
                                                hintText: l10n.t(
                                                  'signup_email_hint',
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                              validator: (v) {
                                                final t = (v ?? '').trim();
                                                if (t.isEmpty) {
                                                  return l10n.t(
                                                    'signup_email_required',
                                                  );
                                                }
                                                if (!t.contains('@') ||
                                                    !t.contains('.')) {
                                                  return l10n.t(
                                                    'signup_email_invalid',
                                                  );
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _phone,
                                              keyboardType: TextInputType.phone,
                                              decoration: InputDecoration(
                                                labelText: l10n.t(
                                                  'signup_phone_label',
                                                ),
                                                hintText: l10n.t(
                                                  'signup_phone_hint',
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                              validator: (v) {
                                                final digits = (v ?? '')
                                                    .replaceAll(
                                                      RegExp(r'[^\d]'),
                                                      '',
                                                    );
                                                if (digits.isEmpty) {
                                                  return l10n.t(
                                                    'signup_phone_required',
                                                  );
                                                }
                                                if (digits.length < 10 ||
                                                    digits.length > 11) {
                                                  return l10n.t(
                                                    'signup_phone_invalid',
                                                  );
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _companyName,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              decoration: InputDecoration(
                                                labelText: l10n.t(
                                                  'signup_company_label',
                                                ),
                                                hintText: l10n.t(
                                                  'signup_company_hint',
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                              validator: (v) {
                                                final t = (v ?? '').trim();
                                                if (t.isEmpty) {
                                                  return l10n.t(
                                                    'signup_company_required',
                                                  );
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _role,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              decoration: InputDecoration(
                                                labelText: l10n.t(
                                                  'signup_role_label',
                                                ),
                                                hintText: l10n.t(
                                                  'signup_role_hint',
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _password,
                                              obscureText: _obscurePassword,
                                              decoration: InputDecoration(
                                                labelText: l10n.t(
                                                  'signup_password_label',
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                                suffixIcon: IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  icon: Icon(
                                                    _obscurePassword
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                    color: Brand.black,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    setState(
                                                      () => _obscurePassword =
                                                          !_obscurePassword,
                                                    );
                                                  },
                                                ),
                                              ),
                                              validator: (v) {
                                                final t = v ?? '';
                                                if (t.isEmpty) {
                                                  return l10n.t(
                                                    'signup_password_required',
                                                  );
                                                }
                                                if (t.length < 6) {
                                                  return l10n.t(
                                                    'signup_password_too_short',
                                                  );
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 12),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Brand.black,
                                                foregroundColor: Brand.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 11,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: _loading
                                                  ? null
                                                  : _submit,
                                              child: _loading
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : Text(
                                                      l10n.t('btn_register'),
                                                    ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Divider(height: 1),
                                            const SizedBox(height: 4),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Checkbox(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  value: _marketingConsent,
                                                  onChanged: (v) {
                                                    setState(() {
                                                      _marketingConsent =
                                                          v ?? false;
                                                    });
                                                  },
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    l10n.t(
                                                      'signup_marketing_consent',
                                                    ),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Colors.black87,
                                                          height: 1.35,
                                                          fontSize: 12,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            const Divider(height: 1),
                                            const SizedBox(height: 4),
                                            _PrivacyPolicyText(
                                              privacyUrl: _privacyUrl,
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  l10n.t('signup_already_have'),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.black54,
                                                      ),
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(
                                                      context,
                                                    ).pushReplacement(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const LoginScreen(),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    l10n.t('btn_login'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: IconButton(
                        onPressed: _handleBack,
                        style: IconButton.styleFrom(
                          backgroundColor: Brand.white.withValues(alpha: 0.85),
                        ),
                        icon: const Icon(Icons.arrow_back, color: Brand.black),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Material(
                        color: Brand.white.withValues(alpha: 0.85),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: const LanguageButton(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Texto com link "Privacy Policy" que abre em nova aba.
/// Usa [MouseRegion] + [GestureDetector] para o link funcionar na web
/// (TapGestureRecognizer em TextSpan costuma falhar no Flutter web).
class _PrivacyPolicyText extends StatelessWidget {
  final String privacyUrl;

  const _PrivacyPolicyText({required this.privacyUrl});

  Future<void> _openPrivacy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse(privacyUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.t('signup_privacy_url_clipboard')} $privacyUrl'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.t('signup_privacy_url_open')} $privacyUrl'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.t('signup_privacy_prefix'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                fontSize: 11,
                height: 1.35,
              ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _openPrivacy(context),
            child: Text(
              l10n.t('signup_privacy_link'),
              style: const TextStyle(
                color: Brand.black,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ),
        const Text('.'),
      ],
    );
  }
}
