import 'package:flutter/material.dart';

import '../ui/brand.dart';

/// Painel lateral esquerdo com critérios de alinhamento (retrátil)
class CriteriaPanel extends StatelessWidget {
  final VoidCallback onClose;

  const CriteriaPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: Brand.white,
        border: Border(right: BorderSide(color: Brand.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Brand.black.withOpacity(0.03),
              border: Border(bottom: BorderSide(color: Brand.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.rule, color: Brand.black, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Critérios de Alinhamento',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Brand.black,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  tooltip: 'Fechar',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _CriteriaCard(
                  level: 'Nível 5 — 100% ALINHADO',
                  subtitle: 'Cobertura em toda a organização',
                  points: 5,
                  items: [
                    'Controles implementados em 100% da organização',
                    'Automação completa e orquestração integrada',
                    'Monitoramento contínuo e proativo em todas as áreas',
                    'Testes regulares com validação comprovada',
                    'Documentação automatizada e atualizada em tempo real',
                    'Cultura organizacional alinhada à soberania digital',
                    'Independência total de fornecedores críticos',
                  ],
                ),
                SizedBox(height: 12),
                _CriteriaCard(
                  level: 'Nível 4 — 75% ALINHADO',
                  subtitle: 'Cobertura parcial — Avançado',
                  points: 4,
                  items: [
                    'Controles implementados em ~75% da organização',
                    'Automação parcial significativa (60–90%)',
                    'Monitoramento sistemático nas áreas críticas',
                    'Testes anuais documentados e bem-sucedidos',
                    'Documentação corporativa mantida e versionada',
                    'Processos estabelecidos e repetíveis',
                    'Dependências externas mapeadas e gerenciadas',
                  ],
                ),
                SizedBox(height: 12),
                _CriteriaCard(
                  level: 'Nível 3 — 50% ALINHADO',
                  subtitle: 'Cobertura parcial — Intermediário',
                  points: 3,
                  items: [
                    'Controles implementados em ~50% da organização',
                    'Automação moderada (30–60%) com processos manuais',
                    'Monitoramento periódico em áreas selecionadas',
                    'Testes ocasionais ou realizados há mais de 1 ano',
                    'Documentação existe, porém com defasagem',
                    'Processos definidos, mas não totalmente seguidos',
                    'Dependências externas identificadas, mas não mitigadas',
                  ],
                ),
                SizedBox(height: 12),
                _CriteriaCard(
                  level: 'Nível 2 — 25% ALINHADO',
                  subtitle: 'Cobertura parcial — Inicial',
                  points: 2,
                  items: [
                    'Controles implementados em apenas ~25% da organização',
                    'Automação mínima (<30%) com abordagem manual',
                    'Monitoramento ad-hoc e reativo',
                    'Testes não realizados ou apenas planejados',
                    'Documentação fragmentada ou desatualizada',
                    'Processos informais sem padronização',
                    'Alta dependência de fornecedores sem gestão',
                  ],
                ),
                SizedBox(height: 12),
                _CriteriaCard(
                  level: 'Nível 1 — 0% ALINHADO',
                  subtitle: 'Sem cobertura',
                  points: 1,
                  items: [
                    'Nenhum controle implementado na organização',
                    'Ausência de automação e processos',
                    'Sem monitoramento ou visibilidade',
                    'Nunca foram realizados testes ou validações',
                    'Documentação inexistente',
                    'Organização não reconhece a necessidade',
                    'Exposição crítica a riscos regulatórios e operacionais',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CriteriaCard extends StatelessWidget {
  final String level;
  final String subtitle;
  final int points;
  final List<String> items;

  const _CriteriaCard({
    required this.level,
    required this.subtitle,
    required this.points,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Brand.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Brand.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$points pts',
                    style: const TextStyle(
                      color: Brand.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    level,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Brand.black,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✔ ', style: TextStyle(fontSize: 12, color: Colors.green)),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black87,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
