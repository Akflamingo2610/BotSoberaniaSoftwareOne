import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import '../widgets/login_card_form.dart';

/// Primeira tela do app: boas-vindas + Entrar ou Cadastre-se.
/// Sempre exibe o formulário de login; qualquer sessão antiga é descartada
/// para que o usuário sempre faça login explicitamente.
///
/// [initialAdminMode] — quando `true` (ex.: após sair do painel admin), o chip
/// "Área Admin" já vem ativo para facilitar novo login de administrador.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.initialAdminMode = false});

  /// Se `true`, abre já no fluxo de administrador (chip ativo + formulário admin).
  final bool initialAdminMode;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late bool _adminMode;

  @override
  void initState() {
    super.initState();
    _adminMode = widget.initialAdminMode;
    AppStorage().clearAll();
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Soberania Digital',
                                style: TextStyle(
                                  color: Brand.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 14),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _adminMode = !_adminMode),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _adminMode
                                        ? Brand.white
                                        : Colors.white
                                            .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _adminMode
                                          ? Brand.white
                                          : Colors.white
                                              .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons
                                            .admin_panel_settings_outlined,
                                        size: 13,
                                        color: _adminMode
                                            ? Brand.black
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _adminMode
                                            ? 'Administrador'
                                            : 'Área Admin',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _adminMode
                                              ? Brand.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                                key: ValueKey('admin_$_adminMode'),
                                variant: LoginCardVariant.welcome,
                                secondaryLabel: l10n.t('btn_signup'),
                                initialAdminMode: _adminMode,
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
