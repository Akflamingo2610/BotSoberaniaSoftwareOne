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
        title: 'Entenda o Assessment',
        subtitle: 'Assessment de Maturidade',
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

class _ContentColumn extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onLogout;

  const _ContentColumn({required this.onContinue, required this.onLogout});

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
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antes de começar',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Brand.black,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entenda mais sobre a SoftwareOne e o Assessment de Maturidade em Soberania Digital.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tempo estimado: 5–10 min',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onLogout,
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

              // Card: O que é
              Card(
                elevation: 0,
                color: Brand.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Brand.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 O que é',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Brand.black,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          children: const [
                            TextSpan(text: 'O Assessment de Maturidade em Soberania Digital da SoftwareOne avalia de forma estruturada o nível de controle, conformidade, resiliência e independência digital da organização. A avaliação considera aspectos técnicos, operacionais, organizacionais e regulatórios, fornecendo uma visão clara do '),
                            TextSpan(text: 'estado atual', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ', das '),
                            TextSpan(text: 'lacunas existentes', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ' e das '),
                            TextSpan(text: 'prioridades de evolução', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: '. O assessment é baseado em critérios objetivos, mensuráveis e auditáveis, permitindo classificar a maturidade e apoiar a definição de um roadmap pragmático e alinhado às exigências do negócio e da regulação.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card: Sobre a SoftwareOne
              Card(
                elevation: 0,
                color: Brand.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Brand.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏢 Sobre a SoftwareOne',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Brand.black,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          children: const [
                            TextSpan(text: 'A SoftwareOne é uma '),
                            TextSpan(text: 'empresa global de soluções em tecnologia', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ', com '),
                            TextSpan(text: 'sede na Suíça', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ' e '),
                            TextSpan(text: 'operação no Brasil', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ', apoiando organizações em sua jornada de modernização e transformação digital. Atuamos como parceiros estratégicos de nossos clientes, combinando '),
                            TextSpan(text: 'profundo conhecimento técnico', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ', experiência em ambientes de nuvem, dados e segurança, e '),
                            TextSpan(text: 'entendimento prático', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ' das '),
                            TextSpan(text: 'exigências regulatórias locais e globais', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: '. Como '),
                            TextSpan(text: 'AWS Premier Partner', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ', a SoftwareOne integra o mais alto nível de parceria da AWS, reconhecido por '),
                            TextSpan(text: 'excelência técnica comprovada', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ', '),
                            TextSpan(text: 'histórico consistente de entregas bem-sucedidas e equipes altamente certificadas', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: '. Esse nível de parceria atesta a capacidade da SoftwareOne de projetar, implementar e operar ambientes complexos e críticos na nuvem, seguindo padrões rigorosos de qualidade, segurança e governança.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card: Parceria SoftwareOne e AWS
              Card(
                elevation: 0,
                color: Brand.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Brand.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🤝 Parceria SoftwareOne e AWS em Soberania Digital',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Brand.black,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          children: const [
                            TextSpan(text: 'A SoftwareOne é parceira estratégica da AWS para o tema de Soberania Digital, sendo '),
                            TextSpan(text: 'a única empresa no Brasil', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ' e '),
                            TextSpan(text: 'uma das poucas no mundo', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ' com essa competência reconhecida. Essa parceria une '),
                            TextSpan(text: 'profundo conhecimento técnico em ambientes de nuvem', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ' com '),
                            TextSpan(text: 'expertise nas exigências regulatórias locais e globais', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ', permitindo apoiar organizações na construção de estratégias de soberania digital alinhadas às demandas de negócio, aos requisitos legais e aos desafios operacionais de ambientes digitais modernos e distribuídos.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card: Soberania Digital
              Card(
                elevation: 0,
                color: Brand.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Brand.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚙️ Soberania Digital',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Brand.black,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          children: const [
                            TextSpan(text: 'Soberania Digital é a capacidade de uma organização manter '),
                            TextSpan(text: 'controle, autoridade e visibilidade', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ' sobre seus dados, infraestrutura e operações digitais, assegurando conformidade regulatória, segurança, resiliência operacional, transparência e independência tecnológica. Em ambientes de nuvem, a soberania digital possibilita atender a requisitos regulatórios e geopolíticos crescentes '),
                            TextSpan(text: 'sem comprometer agilidade, inovação ou escala', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ', criando uma base sustentável para inovação segura e crescimento contínuo.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Desafios (accordion simples)
              Card(
                elevation: 0,
                color: Brand.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Brand.border),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Text(
                    '⚠️ Principais desafios enfrentados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Brand.black,
                    ),
                  ),
                  children: [
                    _BulletList(
                      items: [
                        TextSpan(children: [
                          const TextSpan(text: 'Conformidade simultânea com '),
                          TextSpan(text: 'múltiplas legislações e regulações', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' nacionais e internacionais'),
                        ]),
                        TextSpan(children: [
                          const TextSpan(text: 'Garantia de '),
                          TextSpan(text: 'residência, movimentação e controle de dados', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' em ambientes distribuídos'),
                        ]),
                        TextSpan(children: [
                          TextSpan(text: 'Restrição e governança de acessos operacionais', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ', incluindo operadores internos e terceiros'),
                        ]),
                        TextSpan(children: [
                          const TextSpan(text: 'Falta de '),
                          TextSpan(text: 'visibilidade contínua e evidências auditáveis', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' de conformidade'),
                        ]),
                        TextSpan(children: [
                          const TextSpan(text: 'Necessidade de '),
                          TextSpan(text: 'resiliência e continuidade operacional', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' frente a incidentes, falhas sistêmicas ou eventos geopolíticos'),
                        ]),
                        TextSpan(children: [
                          const TextSpan(text: 'Escassez de '),
                          TextSpan(text: 'competências especializadas', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' para projetar, operar e evoluir ambientes soberanos'),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Benefícios (accordion simples)
              Card(
                elevation: 0,
                color: Brand.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Brand.border),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Text(
                    '✅ Principais benefícios',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Brand.black,
                    ),
                  ),
                  children: [
                    _BulletList(
                      items: [
                        TextSpan(children: [
                          TextSpan(text: 'Redução de riscos regulatórios, operacionais e reputacionais', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                        TextSpan(children: [
                          TextSpan(text: 'Maior transparência e auditabilidade', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' dos ambientes digitais'),
                        ]),
                        TextSpan(children: [
                          TextSpan(text: 'Controle efetivo', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' sobre dados, infraestrutura e operações críticas'),
                        ]),
                        TextSpan(children: [
                          TextSpan(text: 'Continuidade e resiliência dos negócios', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ', mesmo em cenários extremos'),
                        ]),
                        TextSpan(children: [
                          TextSpan(text: 'Aumento da confiança', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' de clientes, parceiros e órgãos reguladores'),
                        ]),
                        TextSpan(children: [
                          const TextSpan(text: 'Base sólida para '),
                          TextSpan(text: 'inovação segura', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ', incluindo dados sensíveis e cargas de trabalho críticas'),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // CTA Button
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.black,
                  foregroundColor: Brand.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onContinue,
                child: const Text(
                  'Iniciar Assessment',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<InlineSpan> items;

  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.black87,
      height: 1.5,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: baseStyle),
              Expanded(
                child: RichText(
                  text: TextSpan(style: baseStyle, children: [item]),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
