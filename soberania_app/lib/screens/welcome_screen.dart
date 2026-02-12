import 'package:flutter/material.dart';

import '../storage/app_storage.dart';
import '../ui/brand.dart';
import 'assessment_intro_screen.dart';
import 'login_screen.dart';
import 'phases_screen.dart';
import 'signup_screen.dart';

/// Primeira tela do app: boas-vindas + Entrar ou Cadastre-se.
/// Se o usuário já estiver logado, vai direto para a introdução ou pilares.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final token = await AppStorage().getAuthToken();
    if (!mounted) return;
    setState(() => _checkingAuth = false);
    if (token != null && token.isNotEmpty) {
      final introSeen = await AppStorage().getIntroSeen();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              introSeen ? const PhasesScreen() : const AssessmentIntroScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        backgroundColor: Brand.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Brand.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SoftwareOneMark(size: 64),
                      const SizedBox(width: 24),
                      Container(width: 1, height: 48, color: Brand.border),
                      const SizedBox(width: 24),
                      const AwsMark(size: 64),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Bem-vindo à aplicação de soberania digital da Software One com a AWS',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Brand.black,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Brand.black,
                        foregroundColor: Brand.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Brand.white,
                        foregroundColor: Brand.black,
                        side: const BorderSide(color: Brand.black),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text('Cadastre-se'),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
