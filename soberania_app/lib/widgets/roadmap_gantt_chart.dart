import 'package:flutter/material.dart';

import '../ui/brand.dart';

class RoadmapGanttStep {
  const RoadmapGanttStep({
    required this.period,
    required this.title,
    required this.description,
    this.actions = const [],
    this.services = const [],
    this.performanceNote,
  });

  final String period;
  final String title;
  final String description;
  final List<String> actions;
  final List<String> services;
  final String? performanceNote;
}

class RoadmapGanttCard extends StatelessWidget {
  const RoadmapGanttCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.steps,
    this.compact = false,
    this.activityColumnLabel = 'Atividade / Fase',
    this.phaseLabels = const ['0-30 dias', '31-60 dias', '61-90 dias'],
    this.legendTitle = 'Legenda das fases',
  });

  final String title;
  final String subtitle;
  final List<RoadmapGanttStep> steps;
  final bool compact;
  final String activityColumnLabel;
  final List<String> phaseLabels;
  final String legendTitle;

  static const _phaseColors = [
    Brand.assessmentCtaBlue,
    Brand.accentBlue,
    Brand.controlPurple,
  ];

  static const _totalDays = 90.0;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Brand.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Brand.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            SizedBox(height: compact ? 12 : 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final labelWidth = constraints.maxWidth >= 900 ? 280.0 : 210.0;
                final chartWidth = constraints.maxWidth - labelWidth - 8;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GanttHeader(
                      labelWidth: labelWidth,
                      chartWidth: chartWidth,
                      activityColumnLabel: activityColumnLabel,
                      phaseLabels: phaseLabels,
                    ),
                    const SizedBox(height: 8),
                    ...steps.asMap().entries.expand((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      final color = _phaseColors[index % _phaseColors.length];
                      final start = index * 30.0;
                      final end = (index + 1) * 30.0;
                      final actionCount = step.actions.isEmpty
                          ? 1
                          : step.actions.length;
                      final chunk = 30.0 / actionCount;

                      return [
                        _GanttRow(
                          labelWidth: labelWidth,
                          chartWidth: chartWidth,
                          label: step.title,
                          badge: step.period,
                          badgeColor: color,
                          startDay: start,
                          endDay: end,
                          barColor: color,
                          barHeight: compact ? 20 : 24,
                          bold: true,
                        ),
                        ...step.actions.asMap().entries.map((actionEntry) {
                          final actionIndex = actionEntry.key;
                          final action = actionEntry.value;
                          return _GanttRow(
                            labelWidth: labelWidth,
                            chartWidth: chartWidth,
                            label: action,
                            indent: true,
                            startDay: start + actionIndex * chunk,
                            endDay: start + (actionIndex + 1) * chunk,
                            barColor: color.withValues(alpha: 0.55),
                            barHeight: compact ? 14 : 16,
                          );
                        }),
                        if (!compact && step.services.isNotEmpty)
                          _PhaseMetaRow(
                            labelWidth: labelWidth,
                            services: step.services,
                            note: step.performanceNote,
                          ),
                        SizedBox(height: compact ? 6 : 10),
                      ];
                    }),
                    _GanttLegend(
                      steps: steps,
                      colors: _phaseColors,
                      legendTitle: legendTitle,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GanttHeader extends StatelessWidget {
  const _GanttHeader({
    required this.labelWidth,
    required this.chartWidth,
    required this.activityColumnLabel,
    required this.phaseLabels,
  });

  final double labelWidth;
  final double chartWidth;
  final String activityColumnLabel;
  final List<String> phaseLabels;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            activityColumnLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: chartWidth,
          height: 52,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: i.isEven
                              ? const Color(0xFFF3F6FB)
                              : const Color(0xFFFAFAFC),
                          border: Border(
                            right: i < 2
                                ? const BorderSide(color: Brand.border)
                                : BorderSide.none,
                          ),
                        ),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          phaseLabels[i],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Brand.assessmentCtaBlue,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _DayTick(label: '0'),
                    _DayTick(label: '30'),
                    _DayTick(label: '60'),
                    _DayTick(label: '90'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayTick extends StatelessWidget {
  const _DayTick({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.black.withValues(alpha: 0.45),
      ),
    );
  }
}

class _GanttRow extends StatelessWidget {
  const _GanttRow({
    required this.labelWidth,
    required this.chartWidth,
    required this.label,
    required this.startDay,
    required this.endDay,
    required this.barColor,
    this.badge,
    this.badgeColor,
    this.indent = false,
    this.bold = false,
    this.barHeight = 18,
  });

  final double labelWidth;
  final double chartWidth;
  final String label;
  final double startDay;
  final double endDay;
  final Color barColor;
  final String? badge;
  final Color? badgeColor;
  final bool indent;
  final bool bold;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final left = (startDay / RoadmapGanttCard._totalDays) * chartWidth;
    final width =
        ((endDay - startDay) / RoadmapGanttCard._totalDays) * chartWidth;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (indent)
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 6),
                    child: Icon(Icons.subdirectory_arrow_right, size: 14),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? Brand.assessmentCtaBlue)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor ?? Brand.assessmentCtaBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        label,
                        maxLines: bold ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: bold ? 13 : 11.5,
                          height: 1.25,
                          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                          color: bold ? Brand.black : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: chartWidth,
            height: barHeight + 8,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(child: Container(color: const Color(0xFFF8FAFD))),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Brand.border),
                              right: BorderSide(color: Brand.border),
                            ),
                            color: Color(0xFFFDFDFE),
                          ),
                        ),
                      ),
                      Expanded(child: Container(color: const Color(0xFFF8FAFD))),
                    ],
                  ),
                ),
                Positioned(
                  left: left,
                  width: width.clamp(6, chartWidth),
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withValues(alpha: 0.25),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseMetaRow extends StatelessWidget {
  const _PhaseMetaRow({
    required this.labelWidth,
    required this.services,
    this.note,
  });

  final double labelWidth;
  final List<String> services;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: labelWidth - 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: services
                      .map(
                        (svc) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Brand.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Brand.border),
                          ),
                          child: Text(
                            svc,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Brand.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GanttLegend extends StatelessWidget {
  const _GanttLegend({
    required this.steps,
    required this.colors,
    required this.legendTitle,
  });

  final List<RoadmapGanttStep> steps;
  final List<Color> colors;
  final String legendTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            legendTitle,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${step.period}: ${step.description}',
                      style: const TextStyle(fontSize: 11.5, height: 1.3),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
