import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../storage/app_storage.dart';
import '../ui/brand.dart';
import '../widgets/chat_panel.dart';
import 'login_screen.dart';
import 'phases_screen.dart';

class AssessmentIntroScreen extends StatelessWidget {
  const AssessmentIntroScreen({super.key});

  Future<void> _continue(BuildContext context) async {
    // Salva flag de que já viu a introdução
    await AppStorage().setIntroSeen(true);
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const PhasesScreen()));
  }

  Future<void> _logout(BuildContext context) async {
    await AppStorage().clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(
        context,
        title: 'Soberania Digital',
        subtitle: 'Entenda a metodologia do assessment antes de começar',
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ContentColumn(
                      onContinue: () => _continue(context),
                      onLogout: () => _logout(context),
                    ),
                  ),
                  SizedBox(
                    width: 420,
                    child: ChatPanel(
                      welcomeMessage:
                          'Ficou com alguma dúvida em relação ao assessment ou sobre soberania digital? Fique à vontade para me perguntar!',
                    ),
                  ),
                ],
              );
            }
            // Mobile/narrow: conteúdo em coluna única
            return _ContentColumn(
              onContinue: () => _continue(context),
              onLogout: () => _logout(context),
            );
          },
        ),
      ),
    );
  }
}

class _ContentColumn extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onLogout;

  const _ContentColumn({required this.onContinue, required this.onLogout});

  @override
  State<_ContentColumn> createState() => _ContentColumnState();
}

class _ContentColumnState extends State<_ContentColumn> {
  bool _marketingConsent = false;

  static const String _privacyUrl =
      'https://www.softwareone.com/en/privacy-statement';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soberania Digital',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Brand.black,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Soberania Digital é a capacidade de uma organização manter controle, autoridade e visibilidade sobre seus dados, infraestrutura e operações digitais, assegurando conformidade regulatória, segurança, resiliência operacional, transparência e independência tecnológica. Em ambientes de nuvem, a soberania digital possibilita atender a requisitos regulatórios e geopolíticos crescentes sem comprometer agilidade, inovação ou escala, criando uma base sustentável para inovação segura e crescimento contínuo.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black87, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sair'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Brand.black,
                      side: const BorderSide(color: Brand.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                'Framework dos 3 Cs: Nossa Metodologia de Avaliação',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Brand.black,
                    ),
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.rule_folder_outlined,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Compliance\n(Conformidade)',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Brand.black,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adesão a padrões de cibersegurança e legislações (LGPD, normas setoriais). Transformar leis em requisitos mensuráveis.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black87, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Control\n(Controle)',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Brand.black,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Autoridade granular sobre a infraestrutura. Resiliência de dados, soberania de chaves e restrição de acesso.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black87, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.autorenew_outlined,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Continuity\n(Continuidade)',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Brand.black,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Capacidade de sobrevivência e recuperação. Autossuficiência tecnológica e resiliência a eventos geopolíticos.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black87, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Brand.border),
                ),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          height: 1.6,
                        ),
                    children: const [
                      TextSpan(
                        text:
                            'O Assessment de Maturidade em Soberania Digital da SoftwareOne avalia de forma estruturada o nível de controle, conformidade, resiliência e independência digital da organização. A avaliação considera aspectos técnicos, operacionais, organizacionais e regulatórios, fornecendo uma visão clara do ',
                      ),
                      TextSpan(
                        text: 'estado atual',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ', das ',
                      ),
                      TextSpan(
                        text: 'lacunas existentes',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' e das ',
                      ),
                      TextSpan(
                        text: 'prioridades de evolução',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            '. O assessment é baseado em critérios objetivos, mensuráveis e auditáveis, permitindo classificar a maturidade e apoiar a definição de um roadmap pragmático e alinhado às exigências do negócio e da regulação.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dê o seu melhor próximo passo com a SoftwareOne',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Brand.black,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nossa equipe de nuvem AWS tem respostas. Conte-nos sobre o desafio do seu negócio e retornaremos em breve.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black87, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Brand.black,
                            foregroundColor: Brand.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 28,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: _marketingConsent
                              ? widget.onContinue
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Para continuar, é necessário aceitar o termo de uso de dados.',
                                      ),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                },
                          child: const Text(
                            'VAMOS CONVERSAR',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 180,
                      maxHeight: 120,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/dspartner-16e1f188313fa8b17c6e569eabcadd9d.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

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
                          ?.copyWith(color: Colors.black87, height: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text:
                      'By submitting this form the entered data will be handed over to and stored by us for contact purposes. Your data will under no circumstances be disclosed to third parties. You can review additional information about your data and rights in our ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                  children: [
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Brand.black,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(Uri.parse(_privacyUrl),
                              mode: LaunchMode.externalApplication);
                        },
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// (Lista em bullet não é mais usada nesta tela; componente removido.)
