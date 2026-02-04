import 'package:flutter/material.dart';

import '../models/models.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'questions_screen.dart';

class PhasesScreen extends StatelessWidget {
  const PhasesScreen({super.key});

  static const phases = <PhaseOption>[
    // IMPORTANTE: esses valores precisam bater com o enum do Xano.
    // No seu Xano (pelo CSV importado) costuma ser: Quick_Wins, Foundational, Efficient, Optimized
    PhaseOption('Quick_Wins', 'Quick Wins', 'Ações rápidas com alto impacto'),
    PhaseOption(
      'Foundational',
      'Foundational',
      'Base de governança e controles',
    ),
    PhaseOption('Efficient', 'Efficient', 'Eficiência operacional e automação'),
    PhaseOption('Optimized', 'Optimized', 'Maturidade avançada e resiliência'),
  ];

  Future<void> _logout(BuildContext context) async {
    await AppStorage().clearAll();
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
      appBar: soberaniaAppBar(context, title: 'Fases'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
        },
        backgroundColor: Brand.white,
        foregroundColor: Brand.black,
        icon: const Icon(Icons.gavel),
        label: const Text('Consultar Leis'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Escolha uma fase para responder',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Brand.black,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...phases.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      elevation: 0,
                      color: Brand.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Brand.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        title: Text(
                          p.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(p.subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuestionsScreen(
                                phase: p.value,
                                phaseLabel: p.label,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Obs: os valores das fases precisam bater com seu enum no Xano.\n'
                  'Se der erro de "not one of the allowable values", copie o valor exato do enum no Swagger do Xano.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
