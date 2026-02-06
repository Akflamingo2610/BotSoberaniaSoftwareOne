import 'package:flutter/material.dart';

import '../api/xano_api.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import 'login_screen.dart';
import 'phases_screen.dart';

/// Tela de cadastro (primeira vez) conectada ao endpoint signup_company do Xano.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _companyName = TextEditingController();
  final _cnpj = TextEditingController();
  final _segment = TextEditingController(text: 'Teste');
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _companyName.dispose();
    _cnpj.dispose();
    _segment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = XanoApi();
      final res = await api.signupCompany(
        email: _email.text.trim(),
        password: _password.text,
        cnpj: _cnpj.text.replaceAll(RegExp(r'[^\d]'), ''),
        segment: _segment.text.trim().isEmpty ? 'Teste' : _segment.text.trim(),
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        companyName: _companyName.text.trim().isEmpty
            ? null
            : _companyName.text.trim(),
      );

      final authToken = (res['authToken'] ?? '').toString();
      if (authToken.isEmpty) {
        throw StateError('authToken não retornou no cadastro');
      }

      final storage = AppStorage();
      await storage.setAuthToken(authToken);
      await storage.setUserEmail(_email.text.trim());
      await storage.setUserName(_name.text.trim().isEmpty
          ? _email.text.split('@').first
          : _name.text.trim());

      final assessment = await api.resumeAssessment(authToken: authToken);
      final assessmentId = (assessment['id'] as num).toInt();
      await storage.setAssessmentId(assessmentId);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PhasesScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: AppBar(
        backgroundColor: Brand.white,
        surfaceTintColor: Brand.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Brand.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cadastre-se',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Brand.black,
              ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 0,
                  color: Brand.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Brand.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Criar conta',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Brand.black,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Preencha os dados para se cadastrar.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              hintText: 'Seu nome',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return 'Informe seu e-mail';
                              if (!t.contains('@')) return 'E-mail inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Brand.black,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (v) {
                              final t = v ?? '';
                              if (t.isEmpty) return 'Informe uma senha';
                              if (t.length < 6) {
                                return 'Senha deve ter no mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _companyName,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nome da empresa',
                              hintText: 'Opcional',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _cnpj,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'CNPJ da empresa',
                              hintText: '00.000.000/0001-00',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = (v ?? '').replaceAll(RegExp(r'[^\d]'), '');
                              if (t.isEmpty) return 'Informe o CNPJ da empresa';
                              if (t.length != 14) {
                                return 'CNPJ deve ter 14 dígitos';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _segment,
                            decoration: const InputDecoration(
                              labelText: 'Segmento',
                              hintText: 'Teste (enquanto cria as empresas)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Brand.black,
                              foregroundColor: Brand.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Cadastrar'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Já tem conta? ',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black54),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Entrar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
