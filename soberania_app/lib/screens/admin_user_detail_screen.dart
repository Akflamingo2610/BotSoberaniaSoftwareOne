import 'package:flutter/material.dart';

import '../api/backend_api.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import 'admin_results_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final int userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _api = BackendApi();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _answersLoading = false;
  String? _error;
  int _selectedAssessmentIndex = 0;

  static const _pilars = ['Compliance', 'Continuity', 'Control'];

  static const _pilarColors = {
    'Compliance': Brand.accentRed,
    'Continuity': Brand.accentBlue,
    'Control': Brand.controlPurple,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AppStorage().getAuthToken();
      if (token == null) throw StateError('Sem token');
      final data = await _api.adminUserProgress(
        authToken: token,
        userId: widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
      await _ensureAnswersForSelectedIndex();
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  /// Carrega `answers` sob demanda (API envia só o assessment mais recente completo).
  Future<void> _ensureAnswersForSelectedIndex() async {
    if (_data == null) return;
    final assessments = (_data!['assessments'] as List<dynamic>?) ?? [];
    final i = _selectedAssessmentIndex;
    if (i < 0 || i >= assessments.length) return;
    final m = Map<String, dynamic>.from(assessments[i] as Map);
    final answers = (m['answers'] as List<dynamic>?) ?? [];
    final count = (m['answer_count'] as num?)?.toInt() ?? answers.length;
    if (answers.isNotEmpty || count == 0) return;

    setState(() => _answersLoading = true);
    try {
      final token = await AppStorage().getAuthToken();
      if (token == null || !mounted) {
        if (mounted) setState(() => _answersLoading = false);
        return;
      }
      final aid = (m['id'] as num).toInt();
      final loaded = await _api.adminAssessmentAnswers(
        authToken: token,
        assessmentId: aid,
      );
      if (!mounted) return;
      final newList = List<dynamic>.from(assessments);
      m['answers'] = loaded['answers'] as List<dynamic>;
      newList[i] = m;
      setState(() {
        _data!['assessments'] = newList;
        _answersLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _answersLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar respostas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(
        context,
        title: 'Detalhe do Usuário',
        showBack: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Brand.accentRed,
                  ),
                  const SizedBox(height: 8),
                  Text('Erro: $_error', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final user = _data!['user'] as Map<String, dynamic>;
    final assessments = (_data!['assessments'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UserProfileCard(user: user, onProfileUpdated: _load),
          const SizedBox(height: 16),
          if (assessments.isEmpty) ...[
            const _EmptyAssessmentCard(),
          ] else ...[
            if (assessments.length > 1)
              _AssessmentSelector(
                assessments: assessments,
                selectedIndex: _selectedAssessmentIndex,
                onSelect: (i) {
                  setState(() => _selectedAssessmentIndex = i);
                  _ensureAnswersForSelectedIndex();
                },
              ),
            if (_answersLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            _AssessmentDetailCard(
              assessment:
                  assessments[_selectedAssessmentIndex] as Map<String, dynamic>,
              pilars: _pilars,
              pilarColors: _pilarColors,
              userName: [
                user['name'] ?? '',
                user['last_name'] ?? '',
              ].where((s) => s.toString().isNotEmpty).join(' '),
            ),
          ],
        ],
      ),
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({required this.user, required this.onProfileUpdated});
  final Map<String, dynamic> user;
  final VoidCallback onProfileUpdated;

  Future<void> _openEditDialog(BuildContext context) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditUserProfileDialog(user: user),
    );
    if (updated == true) {
      onProfileUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (user['name'] ?? '').toString().trim();
    final lastName = (user['last_name'] ?? '').toString().trim();
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'user';
    final phone = _fmt(user['phone']);
    final company = user['company'] as Map<String, dynamic>?;
    final companyName = company == null ? '—' : _fmt(company['name']);
    final cargo = _fmt(role.toString().toLowerCase() == 'admin' ? null : role);

    return Card(
      elevation: 0,
      color: Brand.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: avatar + nome + badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: role == 'admin'
                      ? Brand.black
                      : Brand.primaryCtaBlue,
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Brand.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      if (lastName.isNotEmpty && firstName.isNotEmpty)
                        Text(
                          'Nome: $firstName · Sobrenome: $lastName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: role == 'admin'
                        ? Brand.black
                        : Brand.accentBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role == 'admin' ? 'Admin' : 'Usuário',
                    style: TextStyle(
                      color: role == 'admin' ? Brand.white : Brand.accentBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (ctx) => OutlinedButton.icon(
                    onPressed: () => _openEditDialog(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Brand.black,
                      side: const BorderSide(color: Brand.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text(
                      'Editar perfil',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Dados de contato (somente o que foi preenchido no cadastro)
            _SectionTitle(title: 'Dados de contato'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.email_outlined, label: 'E-mail', text: email),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Telefone',
              text: phone,
            ),
            _InfoRow(
              icon: Icons.business_outlined,
              label: 'Empresa',
              text: companyName,
            ),
            _InfoRow(icon: Icons.work_outline, label: 'Cargo', text: cargo),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }
}

class _EditUserProfileDialog extends StatefulWidget {
  const _EditUserProfileDialog({required this.user});
  final Map<String, dynamic> user;

  @override
  State<_EditUserProfileDialog> createState() => _EditUserProfileDialogState();
}

class _EditUserProfileDialogState extends State<_EditUserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _companyName;
  late final TextEditingController _cargo;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final company = widget.user['company'] as Map<String, dynamic>?;
    _name = TextEditingController(text: _str(widget.user['name']));
    _lastName = TextEditingController(text: _str(widget.user['last_name']));
    _phone = TextEditingController(text: _str(widget.user['phone']));
    _companyName = TextEditingController(text: _str(company?['name']));
    final currentRole = _str(widget.user['role']);
    _cargo = TextEditingController(
      text: currentRole.toLowerCase() == 'admin' ? '' : currentRole,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _phone.dispose();
    _companyName.dispose();
    _cargo.dispose();
    super.dispose();
  }

  String _str(dynamic v) => v == null ? '' : v.toString();

  bool get _isAdmin => _str(widget.user['role']).toLowerCase() == 'admin';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await AppStorage().getAuthToken();
      if (token == null) throw StateError('Sessão expirada');
      // Preserva 'admin' para contas administrativas; demais usam o cargo informado.
      final cargoText = _cargo.text.trim();
      final roleToSend = _isAdmin ? 'admin' : cargoText;
      await BackendApi().adminUpdateUserProfile(
        authToken: token,
        userId: widget.user['id'] as int,
        name: _name.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.replaceAll(RegExp(r'[^\d]'), ''),
        role: roleToSend,
        companyName: _companyName.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined, color: Brand.black),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Editar perfil do usuário',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'E-mail: ${widget.user['email'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  _SectionTitle(title: 'Dados pessoais'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o nome'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _lastName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Sobrenome',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      hintText: 'Somente números',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _companyName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Empresa',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cargo,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isAdmin,
                    decoration: InputDecoration(
                      labelText: 'Cargo',
                      hintText: 'Ex: Gerente, Analista',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText: _isAdmin
                          ? 'Conta administrativa — cargo não editável'
                          : null,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Brand.accentRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Brand.accentRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Brand.accentRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Brand.accentRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.assessmentCtaBlue,
                          foregroundColor: Brand.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Brand.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(_saving ? 'Salvando...' : 'Salvar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.black45,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.label});
  final IconData icon;
  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.black38),
          const SizedBox(width: 8),
          if (label != null) ...[
            SizedBox(
              width: 90,
              child: Text(
                label!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssessmentCard extends StatelessWidget {
  const _EmptyAssessmentCard();

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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: Colors.black26),
            const SizedBox(height: 10),
            const Text(
              'Este usuário ainda não iniciou nenhum assessment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentSelector extends StatelessWidget {
  const _AssessmentSelector({
    required this.assessments,
    required this.selectedIndex,
    required this.onSelect,
  });
  final List<dynamic> assessments;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: assessments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final a = assessments[i] as Map<String, dynamic>;
          final selected = i == selectedIndex;
          return FilterChip(
            label: Text('Assessment #${a['id']}'),
            selected: selected,
            onSelected: (_) => onSelect(i),
            backgroundColor: Brand.white,
            selectedColor: Brand.black,
            labelStyle: TextStyle(
              color: selected ? Brand.white : Brand.black,
              fontWeight: FontWeight.w600,
            ),
            side: const BorderSide(color: Brand.border),
          );
        },
      ),
    );
  }
}

class _AssessmentDetailCard extends StatelessWidget {
  const _AssessmentDetailCard({
    required this.assessment,
    required this.pilars,
    required this.pilarColors,
    this.userName = '',
  });
  final Map<String, dynamic> assessment;
  final List<String> pilars;
  final Map<String, Color> pilarColors;
  final String userName;

  static const _scoreLabels = {
    'Totalmente alinhado': 5,
    'Bem alinhado': 4,
    'Parcialmente alinhado': 3,
    'Pouco alinhado': 2,
    'Não alinhado': 1,
  };

  @override
  Widget build(BuildContext context) {
    final answers = (assessment['answers'] as List<dynamic>?) ?? [];
    final answerCount =
        (assessment['answer_count'] as num?)?.toInt() ?? answers.length;
    final createdAt = assessment['created_at'] != null
        ? _formatDate(assessment['created_at'].toString())
        : '—';

    final byPilar = <String, List<Map<String, dynamic>>>{};
    for (final pilar in pilars) {
      byPilar[pilar] = answers
          .where((a) => (a as Map)['pilar'] == pilar)
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList();
    }
    final totalQuestions =
        (assessment['total_questions'] as num?)?.toInt() ?? 72;
    final rawByPilar = assessment['questions_by_pilar'];
    final questionsByPilar = <String, int>{};
    if (rawByPilar is Map) {
      rawByPilar.forEach((k, v) {
        final key = k.toString().trim();
        if (key.isEmpty) return;
        final n = v is num ? v.toInt() : int.tryParse(v.toString());
        if (n != null && n > 0) {
          questionsByPilar[key] = n;
        }
      });
    }

    // Status concluído passa a seguir o total real do catálogo do backend.
    final isCompletedByTotal =
        totalQuestions > 0 && answerCount >= totalQuestions;
    // Fallback por pilar caso o total não esteja disponível.
    final isCompleted = pilars.every(
      (p) =>
          (byPilar[p]?.length ?? 0) >=
          (questionsByPilar[p] ?? byPilar[p]?.length ?? 0),
    );
    final showCompleted = isCompletedByTotal || isCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: Brand.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Brand.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  showCompleted ? Icons.check_circle : Icons.hourglass_empty,
                  color: showCompleted
                      ? const Color(0xFF2E9E5B)
                      : Brand.accentOrange,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Assessment #${assessment['id']} · $createdAt',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                _StatusBadge(isCompleted: showCompleted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...pilars.map(
          (pilar) => _PilarAnswersCard(
            pilar: pilar,
            color: pilarColors[pilar] ?? Brand.accentBlue,
            answers: byPilar[pilar] ?? [],
            totalInPilar: questionsByPilar[pilar] ?? 24,
            scoreLabels: _scoreLabels,
          ),
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (ctx) => Center(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => AdminResultsScreen(
                      assessment: assessment,
                      userName: userName,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Brand.assessmentCtaBlue,
                foregroundColor: Brand.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: const Text(
                'Ver Resultados',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isCompleted});
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF2E9E5B).withValues(alpha: 0.12)
            : Brand.accentOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF2E9E5B).withValues(alpha: 0.4)
              : Brand.accentOrange.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        isCompleted ? 'Concluído' : 'Em progresso',
        style: TextStyle(
          color: isCompleted ? const Color(0xFF2E9E5B) : Brand.accentOrange,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PilarAnswersCard extends StatefulWidget {
  const _PilarAnswersCard({
    required this.pilar,
    required this.color,
    required this.answers,
    required this.totalInPilar,
    required this.scoreLabels,
  });
  final String pilar;
  final Color color;
  final List<Map<String, dynamic>> answers;
  final int totalInPilar;
  final Map<String, int> scoreLabels;

  @override
  State<_PilarAnswersCard> createState() => _PilarAnswersCardState();
}

class _PilarAnswersCardState extends State<_PilarAnswersCard> {
  bool _expanded = false;

  double get _avgScore {
    if (widget.answers.isEmpty) return 0;
    final scores = widget.answers
        .map((a) => widget.scoreLabels[a['score']] ?? 0)
        .where((s) => s > 0)
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  @override
  Widget build(BuildContext context) {
    final answered = widget.answers.length;
    final pct = widget.totalInPilar > 0
        ? (answered / widget.totalInPilar).clamp(0.0, 1.0)
        : 0.0;
    final avg = _avgScore;

    return Card(
      elevation: 0,
      color: Brand.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: widget.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.pilar,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: widget.color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$answered/${widget.totalInPilar} respondidas',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: widget.color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                    ),
                  ),
                  if (avg > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Média de alinhamento: ',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        _ScoreStars(score: avg, color: widget.color),
                        const SizedBox(width: 6),
                        Text(
                          avg.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded && widget.answers.isNotEmpty) ...[
            const Divider(height: 1),
            ...widget.answers.map(
              (a) => _AnswerRow(answer: a, color: widget.color),
            ),
          ],
          if (_expanded && widget.answers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nenhuma resposta neste pilar ainda.',
                style: const TextStyle(fontSize: 13, color: Colors.black38),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreStars extends StatelessWidget {
  const _ScoreStars({required this.score, required this.color});
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = (i + 1) <= score.round();
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: filled ? color : Colors.black26,
        );
      }),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({required this.answer, required this.color});
  final Map<String, dynamic> answer;
  final Color color;

  static const _scoreColors = {
    'Totalmente alinhado': Color(0xFF2E9E5B),
    'Bem alinhado': Color(0xFF4E79A7),
    'Parcialmente alinhado': Color(0xFFF28E2B),
    'Pouco alinhado': Color(0xFFE05C2F),
    'Não alinhado': Color(0xFFE30613),
  };

  @override
  Widget build(BuildContext context) {
    final code = answer['question_code'] ?? '—';
    final recommendation = answer['recommendation'] ?? '—';
    final score = answer['score'] ?? '—';
    final scoreColor = _scoreColors[score] ?? Colors.black45;
    final justification = (answer['justification'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              code,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation,
                  style: const TextStyle(fontSize: 12, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (justification.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Justificativa: $justification',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: scoreColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              score,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
