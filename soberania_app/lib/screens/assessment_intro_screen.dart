import 'package:flutter/material.dart';

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
        title: 'Introdução',
        subtitle: 'Entenda a metodologia do assessment antes de começar',
        showBack: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Brand.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () => _continue(context),
                child: const Text(
                  'INICIAR O ASSESSMENT',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, size: 18, color: Brand.black),
              label: const Text('Sair', style: TextStyle(color: Brand.black)),
            ),
          ],
        ),
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
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    height: 1.6,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Soberania Digital',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' é a capacidade de uma organização manter controle, autoridade e visibilidade sobre seus dados, infraestrutura e operações digitais, assegurando conformidade regulatória, segurança, resiliência operacional, transparência e independência tecnológica. Em ambientes de nuvem, a ',
                    ),
                    TextSpan(
                      text: 'soberania digital',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' possibilita atender a requisitos regulatórios e geopolíticos crescentes sem comprometer agilidade, inovação ou escala, criando uma base sustentável para inovação segura e crescimento contínuo.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        height: 1.6,
                      ),
                  children: const [
                    TextSpan(
                      text: 'Parceria SoftwareOne e AWS em Soberania Digital\n',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text:
                          'A SoftwareOne é parceira estratégica da AWS para o tema de Soberania Digital, sendo a ',
                    ),
                    TextSpan(
                      text:
                          'única empresa no Brasil e uma das poucas no mundo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' com essa competência reconhecida. Essa parceria une um ',
                    ),
                    TextSpan(
                      text:
                          'profundo conhecimento técnico em ambientes de nuvem',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' com ',
                    ),
                    TextSpan(
                      text:
                          'expertise nas exigências regulatórias locais e globais',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ', permitindo apoiar organizações na construção de estratégias de soberania digital alinhadas às demandas de negócio, aos requisitos legais e aos desafios operacionais de ambientes digitais modernos e distribuídos.',
                    ),
                  ],
                ),
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
                        const Icon(Icons.rule_folder_outlined, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Compliance\n(Conformidade)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Brand.black,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _bulletList(context, [
                          'Adesão a padrões de cibersegurança e legislações (LGPD, normas setoriais).',
                          'Transformar leis em requisitos mensuráveis.',
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Control\n(Controle)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Brand.black,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _bulletList(context, [
                          'Autoridade granular sobre a infraestrutura.',
                          'Resiliência de dados, soberania de chaves e restrição de acesso.',
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.autorenew_outlined, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Continuity\n(Continuidade)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Brand.black,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _bulletList(context, [
                          'Capacidade de sobrevivência e recuperação.',
                          'Autossuficiência tecnológica e resiliência a eventos geopolíticos.',
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Card Sobre a SoftwareOne (mesmo estilo/opacidade do card de baixo)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Brand.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sobre a SoftwareOne',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Brand.black,
                      ),
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          height: 1.6,
                        ),
                        children: const [
                          TextSpan(text: 'A SoftwareOne é uma '),
                          TextSpan(
                            text: 'empresa global de soluções em tecnologia',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ', com '),
                          TextSpan(
                            text: 'sede na Suíça e operação no Brasil',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                '. Atua na modernização digital de organizações, combinando parcerias estratégicas, ',
                          ),
                          TextSpan(
                            text: 'profundo conhecimento técnico',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                ', experiência em nuvem, dados e segurança e ',
                          ),
                          TextSpan(
                            text: 'entendimento prático',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ' dos requisitos regulatórios. É '),
                          TextSpan(
                            text: 'AWS Premier Partner',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ', reconhecida por '),
                          TextSpan(
                            text: 'excelência técnica comprovada',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ', '),
                          TextSpan(
                            text:
                                'histórico consistente de entregas bem-sucedidas e equipes altamente certificadas',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                '. Esse nível de parceria demonstra a capacidade da SoftwareOne de projetar, implementar e operar ambientes em nuvem complexos e críticos, atendendo a padrões rigorosos de qualidade, segurança e governança.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Brand.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black87, height: 1.6),
                          children: const [
                            TextSpan(
                              text:
                                  'O Assessment de Maturidade em Soberania Digital da SoftwareOne avalia de forma estruturada o nível de controle, conformidade, resiliência e independência digital da organização. A avaliação considera aspectos técnicos, operacionais, organizacionais e regulatórios, fornecendo uma visão clara do ',
                            ),
                            TextSpan(
                              text: 'estado atual',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ', das '),
                            TextSpan(
                              text: 'lacunas existentes',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ' e das '),
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
                    const SizedBox(width: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 120,
                        maxHeight: 80,
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
              ),
              const SizedBox(height: 40),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _bulletList(BuildContext context, List<String> items) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.black87, height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: style?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Expanded(child: Text(item, style: style)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
