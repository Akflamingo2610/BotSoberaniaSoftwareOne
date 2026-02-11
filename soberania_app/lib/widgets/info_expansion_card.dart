import 'package:flutter/material.dart';

import '../ui/brand.dart';

/// Card expansível para exibir informações de forma compacta inicialmente
/// e permitir "Ver detalhes" para expandir o conteúdo completo.
class InfoExpansionCard extends StatelessWidget {
  final String title;
  final String summary;
  final String fullContent;

  const InfoExpansionCard({
    super.key,
    required this.title,
    required this.summary,
    required this.fullContent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Brand.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Brand.black,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.5,
                ),
          ),
        ),
        children: [
          const SizedBox(height: 8),
          Text(
            fullContent,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
