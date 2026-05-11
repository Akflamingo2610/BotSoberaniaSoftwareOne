import 'package:flutter/material.dart';

import '../api/backend_api.dart';
import '../l10n/app_localizations.dart';
import '../ui/brand.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ResetPasswordScreen({super.key, this.initialEmail});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password1 = TextEditingController();
  final _password2 = TextEditingController();
  bool _loading = false;
  bool _emailConfirmed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _email.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password1.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _confirmEmail() async {
    if (!_formKeyEmail.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = BackendApi();
      await api.forgotPassword(email: _email.text.trim());
      if (!mounted) return;
      setState(() {
        _emailConfirmed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail validado. Agora defina a nova senha.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao validar e-mail: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitPassword() async {
    if (!_formKeyPassword.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = BackendApi();
      await api.resetPassword(
        email: _email.text.trim(),
        newPassword: _password1.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha redefinida com sucesso. Faça login com a nova senha.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao redefinir senha: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(
        context,
        title: AppLocalizations.of(context).t('login_forgot_password'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/signup_bg_custom.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Brand.surface),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.34)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 0,
                      color: Brand.white.withValues(alpha: 0.94),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Brand.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Redefinir senha',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Brand.black,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Form(
                              key: _formKeyEmail,
                              child: TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) {
                                    return 'Informe o e-mail';
                                  }
                                  if (!value.contains('@')) {
                                    return 'E-mail inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Brand.black,
                                foregroundColor: Brand.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _loading ? null : _confirmEmail,
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Continuar'),
                            ),
                            if (_emailConfirmed) ...[
                              const SizedBox(height: 24),
                              Form(
                                key: _formKeyPassword,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _password1,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Nova senha',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) {
                                        final value = (v ?? '').trim();
                                        if (value.isEmpty) {
                                          return 'Informe a nova senha';
                                        }
                                        if (value.length < 8) {
                                          return 'Use pelo menos 8 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _password2,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Confirme a nova senha',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) {
                                        final value = (v ?? '').trim();
                                        if (value.isEmpty) {
                                          return 'Confirme a nova senha';
                                        }
                                        if (value != _password1.text.trim()) {
                                          return 'As senhas não coincidem';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Brand.black,
                                        foregroundColor: Brand.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: _loading ? null : _submitPassword,
                                      child: _loading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Salvar nova senha'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

