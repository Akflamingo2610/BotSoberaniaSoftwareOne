import 'package:flutter/material.dart';

import '../ui/brand.dart';

/// Painel lateral esquerdo com critérios de alinhamento (retrátil)
class CriteriaPanel extends StatelessWidget {
  final VoidCallback onClose;

  const CriteriaPanel({super.key, required this.onClose});

  String _lang(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase();

  String _title(BuildContext context) {
    switch (_lang(context)) {
      case 'en':
        return 'Alignment Criteria';
      case 'es':
        return 'Criterios de Alineamiento';
      default:
        return 'Critérios de Alinhamento';
    }
  }

  String _closeTooltip(BuildContext context) {
    switch (_lang(context)) {
      case 'en':
        return 'Close';
      case 'es':
        return 'Cerrar';
      default:
        return 'Fechar';
    }
  }

  List<_CriteriaData> _criteria(BuildContext context) {
    switch (_lang(context)) {
      case 'en':
        return const [
          _CriteriaData(
            level: 'Level 5 - Fully aligned',
            subtitle: 'Coverage across the entire organization',
            points: 5,
            items: [
              'Controls implemented in 100% of the organization',
              'Full automation and integrated orchestration',
              'Continuous and proactive monitoring across all areas',
              'Regular tests with proven validation',
              'Automated documentation updated in real time',
              'Organizational culture aligned with digital sovereignty',
              'Total independence from critical vendors',
            ],
          ),
          _CriteriaData(
            level: 'Level 4 - Well aligned',
            subtitle: 'Partial coverage - Advanced',
            points: 4,
            items: [
              'Controls implemented in about 75% of the organization',
              'Significant partial automation (60-90%)',
              'Systematic monitoring in critical areas',
              'Annual documented and successful tests',
              'Corporate documentation maintained and versioned',
              'Established and repeatable processes',
              'External dependencies mapped and managed',
            ],
          ),
          _CriteriaData(
            level: 'Level 3 - Partially aligned',
            subtitle: 'Partial coverage - Intermediate',
            points: 3,
            items: [
              'Controls implemented in about 50% of the organization',
              'Moderate automation (30-60%) with manual processes',
              'Periodic monitoring in selected areas',
              'Occasional tests or tests older than 1 year',
              'Documentation exists, but is outdated',
              'Processes are defined, but not fully followed',
              'External dependencies identified, but not mitigated',
            ],
          ),
          _CriteriaData(
            level: 'Level 2 - Slightly aligned',
            subtitle: 'Partial coverage - Initial',
            points: 2,
            items: [
              'Controls implemented in only about 25% of the organization',
              'Minimal automation (<30%) with manual approach',
              'Ad hoc and reactive monitoring',
              'Tests not performed or only planned',
              'Fragmented or outdated documentation',
              'Informal processes without standardization',
              'High unmanaged vendor dependence',
            ],
          ),
          _CriteriaData(
            level: 'Level 1 - Not aligned',
            subtitle: 'No coverage',
            points: 1,
            items: [
              'No controls implemented in the organization',
              'No automation or processes',
              'No monitoring or visibility',
              'No tests or validations have ever been performed',
              'No documentation',
              'The organization does not recognize the need',
              'Critical exposure to regulatory and operational risks',
            ],
          ),
        ];
      case 'es':
        return const [
          _CriteriaData(
            level: 'Nivel 5 - Totalmente alineado',
            subtitle: 'Cobertura en toda la organización',
            points: 5,
            items: [
              'Controles implementados en el 100% de la organización',
              'Automatización completa y orquestación integrada',
              'Monitoreo continuo y proactivo en todas las áreas',
              'Pruebas regulares con validación comprobada',
              'Documentación automatizada y actualizada en tiempo real',
              'Cultura organizacional alineada con la soberanía digital',
              'Independencia total de proveedores críticos',
            ],
          ),
          _CriteriaData(
            level: 'Nivel 4 - Bien alineado',
            subtitle: 'Cobertura parcial - Avanzado',
            points: 4,
            items: [
              'Controles implementados en aproximadamente el 75% de la organización',
              'Automatización parcial significativa (60-90%)',
              'Monitoreo sistemático en áreas críticas',
              'Pruebas anuales documentadas y exitosas',
              'Documentación corporativa mantenida y versionada',
              'Procesos establecidos y repetibles',
              'Dependencias externas mapeadas y gestionadas',
            ],
          ),
          _CriteriaData(
            level: 'Nivel 3 - Parcialmente alineado',
            subtitle: 'Cobertura parcial - Intermedio',
            points: 3,
            items: [
              'Controles implementados en aproximadamente el 50% de la organización',
              'Automatización moderada (30-60%) con procesos manuales',
              'Monitoreo periódico en áreas seleccionadas',
              'Pruebas ocasionales o realizadas hace más de 1 año',
              'La documentación existe, pero está desactualizada',
              'Procesos definidos, pero no totalmente seguidos',
              'Dependencias externas identificadas, pero no mitigadas',
            ],
          ),
          _CriteriaData(
            level: 'Nivel 2 - Poco alineado',
            subtitle: 'Cobertura parcial - Inicial',
            points: 2,
            items: [
              'Controles implementados en solo aproximadamente el 25% de la organización',
              'Automatización mínima (<30%) con enfoque manual',
              'Monitoreo ad hoc y reactivo',
              'Pruebas no realizadas o solo planificadas',
              'Documentación fragmentada o desactualizada',
              'Procesos informales sin estandarización',
              'Alta dependencia de proveedores sin gestión',
            ],
          ),
          _CriteriaData(
            level: 'Nivel 1 - No alineado',
            subtitle: 'Sin cobertura',
            points: 1,
            items: [
              'Ningún control implementado en la organización',
              'Ausencia de automatización y procesos',
              'Sin monitoreo ni visibilidad',
              'Nunca se realizaron pruebas ni validaciones',
              'Documentación inexistente',
              'La organización no reconoce la necesidad',
              'Exposición crítica a riesgos regulatorios y operativos',
            ],
          ),
        ];
      default:
        return const [
          _CriteriaData(
            level: 'Nível 5 - Totalmente alinhado',
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
          _CriteriaData(
            level: 'Nível 4 - Bem alinhado',
            subtitle: 'Cobertura parcial - Avançado',
            points: 4,
            items: [
              'Controles implementados em ~75% da organização',
              'Automação parcial significativa (60-90%)',
              'Monitoramento sistemático nas áreas críticas',
              'Testes anuais documentados e bem-sucedidos',
              'Documentação corporativa mantida e versionada',
              'Processos estabelecidos e repetíveis',
              'Dependências externas mapeadas e gerenciadas',
            ],
          ),
          _CriteriaData(
            level: 'Nível 3 - Parcialmente alinhado',
            subtitle: 'Cobertura parcial - Intermediário',
            points: 3,
            items: [
              'Controles implementados em ~50% da organização',
              'Automação moderada (30-60%) com processos manuais',
              'Monitoramento periódico em áreas selecionadas',
              'Testes ocasionais ou realizados há mais de 1 ano',
              'Documentação existe, porém com defasagem',
              'Processos definidos, mas não totalmente seguidos',
              'Dependências externas identificadas, mas não mitigadas',
            ],
          ),
          _CriteriaData(
            level: 'Nível 2 - Pouco alinhado',
            subtitle: 'Cobertura parcial - Inicial',
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
          _CriteriaData(
            level: 'Nível 1 - Não alinhado',
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
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final criteria = _criteria(context);
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
                    _title(context),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Brand.black,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  tooltip: _closeTooltip(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (var i = 0; i < criteria.length; i++) ...[
                  _CriteriaCard(
                    level: criteria[i].level,
                    subtitle: criteria[i].subtitle,
                    points: criteria[i].points,
                    items: criteria[i].items,
                  ),
                  if (i < criteria.length - 1) const SizedBox(height: 12),
                ],
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

  String _pointsSuffix(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode.toLowerCase()) {
      case 'en':
        return 'pts';
      case 'es':
        return 'pts';
      default:
        return 'pts';
    }
  }

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
                    '$points ${_pointsSuffix(context)}',
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

class _CriteriaData {
  final String level;
  final String subtitle;
  final int points;
  final List<String> items;

  const _CriteriaData({
    required this.level,
    required this.subtitle,
    required this.points,
    required this.items,
  });
}
