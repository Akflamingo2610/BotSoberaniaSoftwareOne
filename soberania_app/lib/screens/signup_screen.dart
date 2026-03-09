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
        SnackBar(content: Text('Erro ao cadastrar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: AppBar(
        backgroundColor: Brand.white,
        surfaceTintColor: Brand.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Brand.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).t('signup_title'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Brand.black,
              ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 0,
                  color: Brand.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Brand.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppLocalizations.of(context).t('signup_heading'),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Brand.black,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppLocalizations.of(context).t('signup_subtitle'),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .t('signup_name_label'),
                              hintText: AppLocalizations.of(context)
                                  .t('signup_name_hint'),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) {
                                return AppLocalizations.of(context)
                                    .t('signup_name_required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lastName,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .t('signup_lastname_label'),
                              hintText: AppLocalizations.of(context)
                                  .t('signup_lastname_hint'),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) {
                                return AppLocalizations.of(context)
                                    .t('signup_lastname_required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .t('signup_email_label'),
                              hintText: AppLocalizations.of(context)
                                  .t('signup_email_hint'),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) {
                                return AppLocalizations.of(context)
                                    .t('signup_email_required');
                              }
                              if (!t.contains('@') || !t.contains('.')) {
                                return AppLocalizations.of(context)
                                    .t('signup_email_invalid');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .t('signup_phone_label'),
                              hintText: AppLocalizations.of(context)
                                  .t('signup_phone_hint'),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final digits =
                                  (v ?? '').replaceAll(RegExp(r'[^\d]'), '');
                              if (digits.isEmpty) {
                                return AppLocalizations.of(context)
                                    .t('signup_phone_required');
                              }
                              if (digits.length < 10 || digits.length > 11) {
                                return AppLocalizations.of(context)
                                    .t('signup_phone_invalid');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _companyName,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .t('signup_company_label'),
                              hintText: AppLocalizations.of(context)
                                  .t('signup_company_hint'),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) {
                                return AppLocalizations.of(context)
                                    .t('signup_company_required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _role,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .t('signup_role_label'),
                              hintText: AppLocalizations.of(context)
                                  .t('signup_role_hint'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .t('signup_password_label'),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Brand.black,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (v) {
                              final t = v ?? '';
                              if (t.isEmpty) {
                                return AppLocalizations.of(context)
                                    .t('signup_password_required');
                              }
                              if (t.length < 6) {
                                return AppLocalizations.of(context)
                                    .t('signup_password_too_short');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Brand.black,
                              foregroundColor: Brand.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)
                                        .t('btn_register'),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _marketingConsent,
                                onChanged: (v) {
                                  setState(() {
                                    _marketingConsent = v ?? false;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'A SoftwareOne pode usar meus dados para me manter informado sobre futuros eventos, bem como sobre produtos, serviços e ofertas.',
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
                                  );
                                },
                                child: Text(AppLocalizations.of(context).t('btn_login')),
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
    final uri = Uri.parse(privacyUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link: $privacyUrl')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abrir: $privacyUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'By submitting this form the entered data will be handed over to and stored by us for contact purposes. Your data will under no circumstances be disclosed to third parties. You can review additional information about your data and rights in our ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _openPrivacy(context),
            child: const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Brand.black,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Text('.'),
      ],
    );
  }
}
