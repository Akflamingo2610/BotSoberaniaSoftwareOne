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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PhasesScreen()),
    );
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
                  const SizedBox(
                    width: 420,
                    child: ChatPanel(questionContext: null),
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

  const _ContentColumn({
    required this.onContinue,
    required this.onLogout,
  });

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
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Brand.black,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entenda o que este assessment avalia e o que você recebe ao final.',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.black87,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tempo estimado: 5–10 min',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Brand.black,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'O Assessment de Maturidade em Soberania Digital da SoftwareOne avalia de forma estruturada o nível de controle, conformidade, resiliência e independência digital da organização. A avaliação considera aspectos técnicos, operacionais, organizacionais e regulatórios, fornecendo uma visão clara do estado atual, das lacunas existentes e das prioridades de evolução. O assessment é baseado em critérios objetivos, mensuráveis e auditáveis, permitindo classificar a maturidade e apoiar a definição de um roadmap pragmático e alinhado às exigências do negócio e da regulação.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                              height: 1.6,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Brand.black,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A SoftwareOne é uma empresa global de soluções em tecnologia, com sede na Suíça e operação no Brasil, apoiando organizações em sua jornada de modernização e transformação digital. Atuamos como parceiros estratégicos de nossos clientes, combinando profundo conhecimento técnico, experiência em ambientes de nuvem, dados e segurança, e entendimento prático das exigências regulatórias locais e globais. Como AWS Premier Tier Services Partner, a SoftwareOne integra o mais alto nível de parceria da AWS, reconhecido por excelência técnica comprovada, histórico consistente de entregas bem-sucedidas e equipes altamente certificadas. Esse nível de parceria atesta a capacidade da SoftwareOne de projetar, implementar e operar ambientes complexos e críticos na nuvem, seguindo padrões rigorosos de qualidade, segurança e governança.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                              height: 1.6,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Brand.black,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A SoftwareOne é parceira estratégica da AWS para o tema de Soberania Digital, sendo a única empresa no Brasil e uma das poucas no mundo com essa competência reconhecida. Essa parceria une profundo conhecimento técnico em ambientes de nuvem com expertise nas exigências regulatórias locais e globais, permitindo apoiar organizações na construção de estratégias de soberania digital alinhadas às demandas de negócio, aos requisitos legais e aos desafios operacionais de ambientes digitais modernos e distribuídos.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                              height: 1.6,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Brand.black,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Soberania Digital é a capacidade de uma organização manter controle, autoridade e visibilidade sobre seus dados, infraestrutura e operações digitais, assegurando conformidade regulatória, segurança, resiliência operacional, transparência e independência tecnológica. Em ambientes de nuvem, a soberania digital possibilita atender a requisitos regulatórios e geopolíticos crescentes sem comprometer agilidade, inovação ou escala, criando uma base sustentável para inovação segura e crescimento contínuo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                              height: 1.6,
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
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Text(
                    '⚠️ Principais desafios enfrentados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Brand.black,
                        ),
                  ),
                  children: const [
                    _BulletList(items: [
                      'Conformidade simultânea com múltiplas legislações e regulações nacionais e internacionais',
                      'Garantia de residência, movimentação e controle de dados em ambientes distribuídos',
                      'Restrição e governança de acessos operacionais, incluindo operadores internos e terceiros',
                      'Falta de visibilidade contínua e evidências auditáveis de conformidade',
                      'Necessidade de resiliência e continuidade operacional frente a incidentes, falhas sistêmicas ou eventos geopolíticos',
                      'Escassez de competências especializadas para projetar, operar e evoluir ambientes soberanos',
                    ]),
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
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Text(
                    '✅ Principais benefícios',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Brand.black,
                        ),
                  ),
                  children: const [
                    _BulletList(items: [
                      'Redução de riscos regulatórios, operacionais e reputacionais',
                      'Maior transparência e auditabilidade dos ambientes digitais',
                      'Controle efetivo sobre dados, infraestrutura e operações críticas',
                      'Continuidade e resiliência dos negócios, mesmo em cenários extremos',
                      'Aumento da confiança de clientes, parceiros e órgãos reguladores',
                      'Base sólida para inovação segura, incluindo dados sensíveis e cargas de trabalho críticas',
                    ]),
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
                  'Continuar para escolher o pilar',
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
  final List<String> items;

  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
