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
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _companyName = TextEditingController();
  final _role = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _companyName.dispose();
    _role.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = XanoApi();
      final res = await api.signupCompany(
        name: _name.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.replaceAll(RegExp(r'[^\d]'), ''),
        companyName: _companyName.text.trim(),
        role: _role.text.trim().isEmpty ? null : _role.text.trim(),
        password: _password.text,
      );

      final authToken = (res['authToken'] ?? '').toString();
      if (authToken.isEmpty) {
        throw StateError('authToken não retornou no cadastro');
      }

      final storage = AppStorage();
      await storage.setAuthToken(authToken);
      await storage.setUserEmail(_email.text.trim());
      await storage.setUserName(_name.text.trim());

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
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return 'Informe seu nome';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lastName,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Sobrenome',
                              hintText: 'Seu sobrenome',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return 'Informe seu sobrenome';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              hintText: 'seu@email.com',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return 'Informe seu e-mail';
                              if (!t.contains('@') || !t.contains('.')) {
                                return 'E-mail inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Telefone',
                              hintText: '(11) 99999-9999',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final digits = (v ?? '').replaceAll(RegExp(r'[^\d]'), '');
                              if (digits.isEmpty) return 'Informe seu telefone';
                              if (digits.length < 10 || digits.length > 11) {
                                return 'Telefone deve ter 10 ou 11 dígitos (com DDD)';
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
                              hintText: 'Nome da sua empresa',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return 'Informe o nome da empresa';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _role,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Função na empresa',
                              hintText: 'Ex: Gerente, Analista',
                              border: OutlineInputBorder(),
                            ),
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
