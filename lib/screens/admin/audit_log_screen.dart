import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme.dart';
import '../../utils/helpers.dart';

/// Provider pro audit log
final auditLogProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  return await ref.read(adminServiceProvider).getAuditLog();
});

/// Obrazovka s audit logem
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(auditLogProvider);

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
              child: const Icon(Icons.history, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Audit log'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(auditLogProvider),
          ),
        ],
      ),
      body: logAsync.when(
        data: (entries) => entries.isEmpty
            ? _buildEmptyState()
            : _buildLogList(context, entries),
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
              const SizedBox(height: 8),
              Text(
                'Tabulka audit_log pravdepodobne neexistuje',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(auditLogProvider),
                child: const Text('Zkusit znovu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Zadne zaznamy',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Audit log je prazdny',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(BuildContext context, List<AuditLogEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _AuditLogTile(entry: entry);
      },
    );
  }
}

/// Dlaždice pro záznam v audit logu
class _AuditLogTile extends StatelessWidget {
  final AuditLogEntry entry;

  const _AuditLogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final actionInfo = _getActionInfo(entry.action);

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
          actionInfo['label'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Admin: ${entry.adminUsername}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (entry.targetUsername != null) ...[
                  Text(
                    ' -> ',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  Text(
                    entry.targetUsername!,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            if (entry.details != null) ...[
              const SizedBox(height: 2),
              Text(
                entry.details!,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Text(
          Helpers.formatTimeAgo(entry.createdAt),
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
        isThreeLine: entry.details != null,
      ),
    );
  }

  Map<String, dynamic> _getActionInfo(String action) {
    switch (action) {
      case 'block_user':
        return {'label': 'Uzivatel zablokovany', 'icon': Icons.block, 'color': Colors.red};
      case 'unblock_user':
        return {'label': 'Uzivatel odblokovany', 'icon': Icons.check_circle, 'color': Colors.green};
      case 'temporary_ban':
        return {'label': 'Docasny ban', 'icon': Icons.timer, 'color': Colors.orange};
      case 'make_admin':
        return {'label': 'Povysen na admina', 'icon': Icons.admin_panel_settings, 'color': Colors.purple};
      case 'make_member':
        return {'label': 'Degradovan na clena', 'icon': Icons.person, 'color': Colors.blue};
      case 'delete_post':
        return {'label': 'Prispevek smazan', 'icon': Icons.delete, 'color': Colors.red};
      case 'delete_comment':
        return {'label': 'Komentar smazan', 'icon': Icons.delete_outline, 'color': Colors.orange};
      case 'pin_post':
        return {'label': 'Prispevek pripnut', 'icon': Icons.push_pin, 'color': Colors.blue};
      case 'unpin_post':
        return {'label': 'Prispevek odepnut', 'icon': Icons.push_pin_outlined, 'color': Colors.grey};
      case 'send_warning':
        return {'label': 'Varovani odeslano', 'icon': Icons.warning, 'color': Colors.orange};
      case 'send_broadcast':
        return {'label': 'Broadcast odeslan', 'icon': Icons.campaign, 'color': Colors.blue};
      case 'resolve_report':
        return {'label': 'Report vyresen', 'icon': Icons.check, 'color': Colors.green};
      case 'dismiss_report':
        return {'label': 'Report zamitnut', 'icon': Icons.close, 'color': Colors.grey};
      case 'add_banned_word':
        return {'label': 'Zakazane slovo pridano', 'icon': Icons.block, 'color': Colors.red};
      case 'remove_banned_word':
        return {'label': 'Zakazane slovo odebrano', 'icon': Icons.remove_circle, 'color': Colors.green};
      case 'gdpr_export':
        return {'label': 'GDPR export', 'icon': Icons.download, 'color': Colors.blue};
      case 'gdpr_delete':
        return {'label': 'GDPR smazani', 'icon': Icons.delete_forever, 'color': Colors.red};
      default:
        return {'label': action, 'icon': Icons.info, 'color': Colors.grey};
    }
  }
}
