import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import '../widgets/login_card_form.dart';
import 'assessment_intro_screen.dart';
import 'phases_screen.dart';

/// Primeira tela do app: boas-vindas + Entrar ou Cadastre-se.
/// Se o usuário já estiver logado, vai direto para a introdução ou pilares.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final token = await AppStorage().getAuthToken();
    if (!mounted) return;
    setState(() => _checkingAuth = false);
    if (token != null && token.isNotEmpty) {
      final introSeen = await AppStorage().getIntroSeen();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              introSeen ? const PhasesScreen() : const AssessmentIntroScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    if (_checkingAuth) {
      return const Scaffold(
        backgroundColor: Brand.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Soberania Digital',
                            style: TextStyle(
                              color: Brand.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Brand.white.withValues(alpha: 0.92),
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
                              child: LoginCardForm(
                                variant: LoginCardVariant.welcome,
                                secondaryLabel: l10n.t('btn_signup'),
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
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
                    color: Brand.white.withValues(alpha: 0.95),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.topRight,
                          child: LanguageButton(),
                        ),
                        Expanded(
                          child: Align(
                            alignment: const Alignment(0, -0.22),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('right_panel_title'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Brand.black,
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.t('right_panel_intro'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Brand.black.withValues(
                                            alpha: 0.82,
                                          ),
                                          height: 1.35,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.t('right_panel_topics'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Brand.black.withValues(
                                            alpha: 0.82,
                                          ),
                                          height: 1.35,
                                        ),
                                  ),
                                ],
                              ),
                            ),
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
