import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme.dart';

/// Provider pro zakázaná slova
final bannedWordsProvider = FutureProvider<List<BannedWord>>((ref) async {
  return await ref.read(adminServiceProvider).getBannedWords();
});

/// Obrazovka pro moderační nástroje
class ModerationScreen extends ConsumerStatefulWidget {
  const ModerationScreen({super.key});

  @override
  ConsumerState<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends ConsumerState<ModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              child: const Icon(Icons.shield, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Moderace'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Zakazana slova'),
            Tab(text: 'Spam filtr'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BannedWordsTab(),
          _SpamFilterTab(),
        ],
      ),
    );
  }
}

/// Tab pro zakázaná slova
class _BannedWordsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannedWordsAsync = ref.watch(bannedWordsProvider);

    return Scaffold(
      body: bannedWordsAsync.when(
        data: (words) => words.isEmpty
            ? _buildEmptyState(context)
            : _buildWordsList(context, ref, words),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Chyba: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(bannedWordsProvider),
                child: const Text('Zkusit znovu'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWordDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Zadna zakazana slova',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pridejte slova, ktera chcete filtrovat',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordsList(BuildContext context, WidgetRef ref, List<BannedWord> words) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return _BannedWordTile(
          word: word,
          onDelete: () => _deleteWord(context, ref, word),
        );
      },
    );
  }

  void _showAddWordDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddWordDialog(
        onAdd: (word, action) async {
          try {
            await ref.read(adminServiceProvider).addBannedWord(word, action);
            ref.invalidate(bannedWordsProvider);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Slovo "$word" pridano'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _deleteWord(BuildContext context, WidgetRef ref, BannedWord word) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Smazat slovo?'),
        content: Text('Opravdu chcete smazat "${word.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrusit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminServiceProvider).removeBannedWord(word.id);
        ref.invalidate(bannedWordsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Slovo "${word.word}" smazano'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

/// Dlaždice pro zakázané slovo
class _BannedWordTile extends StatelessWidget {
  final BannedWord word;
  final VoidCallback onDelete;

  const _BannedWordTile({
    required this.word,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final actionInfo = _getActionInfo(word.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: actionInfo['color'].withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            actionInfo['icon'],
            color: actionInfo['color'],
            size: 20,
          ),
        ),
        title: Text(
          word.word,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          actionInfo['label'],
          style: TextStyle(
            color: actionInfo['color'],
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Map<String, dynamic> _getActionInfo(String action) {
    switch (action) {
      case 'warn':
        return {
          'label': 'Upozorneni',
          'icon': Icons.warning_amber,
          'color': Colors.orange,
        };
      case 'delete':
        return {
          'label': 'Automaticke smazani',
          'icon': Icons.delete,
          'color': Colors.red,
        };
      case 'block':
        return {
          'label': 'Zablokovani uzivatele',
          'icon': Icons.block,
          'color': Colors.red.shade900,
        };
      default:
        return {
          'label': 'Neznama akce',
          'icon': Icons.help,
          'color': Colors.grey,
        };
    }
  }
}

/// Dialog pro přidání slova
class _AddWordDialog extends StatefulWidget {
  final Future<void> Function(String word, String action) onAdd;

  const _AddWordDialog({required this.onAdd});

  @override
  State<_AddWordDialog> createState() => _AddWordDialogState();
}

class _AddWordDialogState extends State<_AddWordDialog> {
  final _wordController = TextEditingController();
  String _selectedAction = 'warn';
  bool _isLoading = false;

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Pridat zakazane slovo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _wordController,
            decoration: InputDecoration(
              labelText: 'Slovo nebo fraze',
              hintText: 'Zadejte slovo...',
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          const Text(
            'Akce pri nalezeni:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _ActionOption(
            value: 'warn',
            label: 'Upozornit moderatora',
            icon: Icons.warning_amber,
            color: Colors.orange,
            isSelected: _selectedAction == 'warn',
            onTap: () => setState(() => _selectedAction = 'warn'),
          ),
          _ActionOption(
            value: 'delete',
            label: 'Automaticky smazat',
            icon: Icons.delete,
            color: Colors.red,
            isSelected: _selectedAction == 'delete',
            onTap: () => setState(() => _selectedAction = 'delete'),
          ),
          _ActionOption(
            value: 'block',
            label: 'Zablokovat uzivatele',
            icon: Icons.block,
            color: Colors.red.shade900,
            isSelected: _selectedAction == 'block',
            onTap: () => setState(() => _selectedAction = 'block'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Zrusit'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Pridat'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zadejte slovo'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await widget.onAdd(word, _selectedAction);
    setState(() => _isLoading = false);
  }
}

/// Možnost akce
class _ActionOption extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Tab pro spam filtr
class _SpamFilterTab extends StatefulWidget {
  @override
  State<_SpamFilterTab> createState() => _SpamFilterTabState();
}

class _SpamFilterTabState extends State<_SpamFilterTab> {
  bool _enableSpamFilter = true;
  bool _blockNewUsersLinks = true;
  int _minPostsForLinks = 3;
  int _maxPostsPerHour = 10;
  bool _blockRepetitiveContent = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nastaveni spam filtru se uklada automaticky',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Hlavní přepínač
          _SettingSwitch(
            title: 'Spam filtr',
            subtitle: 'Automaticky detekovat a blokovat spam',
            icon: Icons.shield,
            value: _enableSpamFilter,
            onChanged: (value) => setState(() => _enableSpamFilter = value),
          ),
          const SizedBox(height: 16),

          if (_enableSpamFilter) ...[
            // Odkazy od nových uživatelů
            _SettingSwitch(
              title: 'Blokovat odkazy od novych uzivatelu',
              subtitle: 'Noví uživatelé nemohou sdílet odkazy',
              icon: Icons.link_off,
              value: _blockNewUsersLinks,
              onChanged: (value) => setState(() => _blockNewUsersLinks = value),
            ),
            const SizedBox(height: 16),

            // Min příspěvků pro odkazy
            if (_blockNewUsersLinks) ...[
              _SettingSlider(
                title: 'Min. prispevku pro sdileni odkazu',
                value: _minPostsForLinks.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) => setState(() => _minPostsForLinks = value.round()),
              ),
              const SizedBox(height: 16),
            ],

            // Max příspěvků za hodinu
            _SettingSlider(
              title: 'Max. prispevku za hodinu',
              value: _maxPostsPerHour.toDouble(),
              min: 5,
              max: 30,
              divisions: 5,
              onChanged: (value) => setState(() => _maxPostsPerHour = value.round()),
            ),
            const SizedBox(height: 16),

            // Opakující se obsah
            _SettingSwitch(
              title: 'Blokovat opakujici se obsah',
              subtitle: 'Detekovat duplicitní příspěvky',
              icon: Icons.content_copy,
              value: _blockRepetitiveContent,
              onChanged: (value) => setState(() => _blockRepetitiveContent = value),
            ),
          ],
        ],
      ),
    );
  }
}

/// Přepínač nastavení
class _SettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary),
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
                const SizedBox(height: 4),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary.withAlpha(150),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return null;
            }),
          ),
        ],
      ),
    );
  }
}

/// Slider nastavení
class _SettingSlider extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _SettingSlider({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  value.round().toString(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
