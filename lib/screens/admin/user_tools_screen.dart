import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/user_avatar.dart';

/// Obrazovka pro uživatelské nástroje
class UserToolsScreen extends ConsumerStatefulWidget {
  const UserToolsScreen({super.key});

  @override
  ConsumerState<UserToolsScreen> createState() => _UserToolsScreenState();
}

class _UserToolsScreenState extends ConsumerState<UserToolsScreen> {
  final _searchController = TextEditingController();
  UserModel? _selectedUser;
  bool _isSearching = false;
  List<UserModel> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await ref.read(adminServiceProvider).searchUsers(query, limit: 10);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_search, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Uzivatelske nastroje'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vyhledávání uživatele
            Text(
              'Vyhledat uzivatele',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Zadejte jmeno uzivatele...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _selectedUser = null;
                              });
                            },
                          )
                        : null,
              ),
            ),

            // Výsledky vyhledávání
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: UserAvatar(
                        imageUrl: user.avatarUrl,
                        name: user.username,
                        size: 36,
                      ),
                      title: Text(user.username),
                      subtitle: Text(
                        user.role,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      trailing: user.isBlocked
                          ? Icon(Icons.block, color: AppColors.error, size: 18)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedUser = user;
                          _searchResults = [];
                          _searchController.text = user.username;
                        });
                      },
                    );
                  },
                ),
              ),
            ],

            // Vybraný uživatel - nástroje
            if (_selectedUser != null) ...[
              const SizedBox(height: 24),
              _buildSelectedUserCard(),
              const SizedBox(height: 16),
              _buildToolsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUserCard() {
    final user = _selectedUser!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: user.avatarUrl,
            name: user.username,
            size: 56,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _RoleBadge(role: user.role),
                    if (user.isBlocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Zablokovany',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => context.push('/profile/${user.id}'),
            tooltip: 'Zobrazit profil',
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nastroje',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // GDPR nástroje
        _ToolCard(
          title: 'GDPR Export',
          subtitle: 'Exportovat vsechna data uzivatele',
          icon: Icons.download,
          color: Colors.blue,
          onTap: () => _showGdprExportDialog(),
        ),
        const SizedBox(height: 8),

        _ToolCard(
          title: 'GDPR Smazani',
          subtitle: 'Smazat vsechna data uzivatele (nevratne!)',
          icon: Icons.delete_forever,
          color: Colors.red,
          onTap: () => _showGdprDeleteDialog(),
        ),
        const SizedBox(height: 8),

        // Dočasný ban
        _ToolCard(
          title: 'Docasny ban',
          subtitle: 'Zablokovat uzivatele na urcitou dobu',
          icon: Icons.timer,
          color: Colors.orange,
          onTap: () => _showTemporaryBanDialog(),
        ),
        const SizedBox(height: 8),

        // Odeslat varování
        _ToolCard(
          title: 'Odeslat varovani',
          subtitle: 'Poslat varovnou notifikaci uzivateli',
          icon: Icons.warning_amber,
          color: Colors.amber,
          onTap: () => _showWarningDialog(),
        ),
      ],
    );
  }

  Future<void> _showGdprExportDialog() async {
    final user = _selectedUser!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('GDPR Export'),
        content: Text('Exportovat vsechna data uzivatele ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrusit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Exportovat'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final data = await ref.read(adminServiceProvider).exportUserData(user.id);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Kopírovat do schránky
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data zkopirována do schranky'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showGdprDeleteDialog() async {
    final user = _selectedUser!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('GDPR Smazani'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opravdu chcete TRVALE smazat vsechna data uzivatele ${user.username}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bude smazano:',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('• Vsechny prispevky', style: TextStyle(color: AppColors.error)),
                  Text('• Vsechny komentare', style: TextStyle(color: AppColors.error)),
                  Text('• Vsechny reakce', style: TextStyle(color: AppColors.error)),
                  Text('• Profilove informace', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tato akce je NEVRATNA!',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrusit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Smazat vse'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Druhé potvrzení
    final doubleConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Posledni upozorneni'),
        content: const Text('Opravdu jste si jisti? Tato akce nelze vratit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ne, zrusit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Ano, smazat'),
          ),
        ],
      ),
    );

    if (doubleConfirm != true) return;

    try {
      await ref.read(adminServiceProvider).deleteUserData(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data uzivatele smazana'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _selectedUser = null;
          _searchController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showTemporaryBanDialog() async {
    final user = _selectedUser!;

    await showDialog(
      context: context,
      builder: (context) => _TemporaryBanDialog(
        user: user,
        onBan: (duration, reason) async {
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref.read(adminServiceProvider).temporaryBan(user.id, duration, reason);
            if (mounted) {
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Uzivatel zablokovany na ${duration.inHours} hodin'),
                  backgroundColor: AppColors.success,
                ),
              );
              setState(() {
                _selectedUser = user.copyWith(isBlocked: true);
              });
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Chyba: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showWarningDialog() async {
    final user = _selectedUser!;
    final messageController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Odeslat varovani'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Varovani pro: ${user.username}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Napiste zpravu...',
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrusit'),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = messageController.text.trim();
              if (message.isEmpty) return;

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await ref.read(adminServiceProvider).sendWarning(user.id, message);
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Varovani odeslano'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Chyba: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Odeslat'),
          ),
        ],
      ),
    );

    messageController.dispose();
  }
}

/// Badge pro roli
class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'admin':
        color = Colors.purple;
        break;
      case 'moderator':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Karta nástroje
class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog pro dočasný ban
class _TemporaryBanDialog extends StatefulWidget {
  final UserModel user;
  final Future<void> Function(Duration duration, String reason) onBan;

  const _TemporaryBanDialog({
    required this.user,
    required this.onBan,
  });

  @override
  State<_TemporaryBanDialog> createState() => _TemporaryBanDialogState();
}

class _TemporaryBanDialogState extends State<_TemporaryBanDialog> {
  final _reasonController = TextEditingController();
  int _selectedHours = 24;
  bool _isLoading = false;

  final _durations = [
    {'hours': 1, 'label': '1 hodina'},
    {'hours': 6, 'label': '6 hodin'},
    {'hours': 24, 'label': '1 den'},
    {'hours': 72, 'label': '3 dny'},
    {'hours': 168, 'label': '1 tyden'},
    {'hours': 720, 'label': '30 dni'},
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Docasny ban'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Uzivatel: ${widget.user.username}'),
            const SizedBox(height: 16),

            const Text(
              'Doba banu:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((d) {
                final hours = d['hours'] as int;
                final isSelected = _selectedHours == hours;
                return ChoiceChip(
                  label: Text(d['label'] as String),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedHours = hours),
                  selectedColor: AppColors.primary.withAlpha(50),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text(
              'Duvod:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Zadejte duvod banu...',
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Zrusit'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Zablokovat'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zadejte duvod'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await widget.onBan(Duration(hours: _selectedHours), reason);
    setState(() => _isLoading = false);
  }
}
