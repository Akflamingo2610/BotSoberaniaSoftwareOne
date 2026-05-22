import 'package:flutter/material.dart';

import '../api/backend_api.dart';
import '../storage/app_storage.dart';
import '../ui/brand.dart';
import 'welcome_screen.dart';
import 'admin_user_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _api = BackendApi();
  List<dynamic> _users = [];
  bool _loading = true;
  String _search = '';
  String? _error;

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
      final users = await _api.adminListUsers(authToken: token);
      if (mounted)
        setState(() {
          _users = users;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AppStorage().clearAll();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(initialAdminMode: true),
      ),
      (_) => false,
    );
  }

  List<dynamic> get _filteredUsers {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users.where((u) {
      final name = '${u['name'] ?? ''} ${u['last_name'] ?? ''}'.toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final company = (u['company']?['name'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || company.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: soberaniaAppBar(
        context,
        title: 'Painel Admin',
        trailing: TextButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout, size: 18, color: Brand.black),
          label: const Text('Sair', style: TextStyle(color: Brand.black)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdminSummaryHeader(users: _users),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome, e-mail ou empresa...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Brand.border),
                      ),
                      filled: true,
                      fillColor: Brand.white,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Atualizar',
                  style: IconButton.styleFrom(
                    backgroundColor: Brand.black,
                    foregroundColor: Brand.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
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
                        Text(
                          'Erro ao carregar: $_error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  )
                : _filteredUsers.isEmpty
                ? const Center(child: Text('Nenhum usuário encontrado.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (_, i) =>
                        _UserCard(user: _filteredUsers[i], api: _api),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdminSummaryHeader extends StatelessWidget {
  const _AdminSummaryHeader({required this.users});
  final List<dynamic> users;

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final withAssessment = users.where((u) => u['assessment'] != null).length;
    final completed = users.where((u) {
      final a = u['assessment'];
      if (a == null) return false;
      final status = (a['status'] ?? '').toString().toUpperCase();
      if (status == 'COMPLETED') return true;
      final answered = (a['answered_count'] as num?)?.toInt() ?? 0;
      final totalQuestions = (a['total_questions'] as num?)?.toInt() ?? 72;
      return totalQuestions > 0 && answered >= totalQuestions;
    }).length;

    return Container(
      color: Brand.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _StatChip(label: 'Usuários', value: '$total', icon: Icons.people),
          const SizedBox(width: 12),
          _StatChip(
            label: 'Com Assessment',
            value: '$withAssessment',
            icon: Icons.assignment,
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: 'Concluídos',
            value: '$completed',
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Brand.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Brand.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Brand.white.withValues(alpha: 0.75)),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Brand.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Brand.white.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.api});
  final dynamic user;
  final BackendApi api;

  @override
  Widget build(BuildContext context) {
    final name = '${user['name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final email = user['email'] ?? '';
    final company = user['company']?['name'] ?? '—';
    final role = user['role'] ?? 'user';
    final assessment = user['assessment'];
    final answeredCount = (assessment?['answered_count'] as num?)?.toInt() ?? 0;
    final totalQuestions =
        (assessment?['total_questions'] as num?)?.toInt() ?? 72;
    final createdAt = user['created_at'] != null
        ? _formatDate(user['created_at'].toString())
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Brand.border),
      ),
      color: Brand.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminUserDetailScreen(userId: user['id'] as int),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: role == 'admin'
                    ? Brand.black
                    : Brand.accentBlue,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Brand.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isNotEmpty ? name : email,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (role == 'admin')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Brand.black,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                color: Brand.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 13,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            company,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.calendar_today,
                          size: 13,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          createdAt,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _fmtPhone(user['phone']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.email_outlined,
                          size: 13,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (assessment != null) ...[
                      const SizedBox(height: 8),
                      _AssessmentProgressBar(
                        answeredCount: answeredCount,
                        totalQuestions: totalQuestions,
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                        'Sem assessment iniciado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtPhone(dynamic v) {
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }
}

class _AssessmentProgressBar extends StatelessWidget {
  const _AssessmentProgressBar({
    required this.answeredCount,
    required this.totalQuestions,
  });
  final int answeredCount;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final pct = totalQuestions > 0
        ? (answeredCount / totalQuestions).clamp(0.0, 1.0)
        : 0.0;
    final color = pct >= 1.0
        ? const Color(0xFF2E9E5B)
        : pct >= 0.5
        ? Brand.accentBlue
        : Brand.accentOrange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso do Assessment',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            Text(
              '$answeredCount/$totalQuestions',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
