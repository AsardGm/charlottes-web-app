import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/theme.dart';
import '../../../providers/offline_queue_provider.dart';
import '../../../services/offline_queue_service.dart';

/// Widget pro zobrazeni stavu offline fronty
class OfflineQueueIndicator extends ConsumerWidget {
  final String? conversationId;

  const OfflineQueueIndicator({
    super.key,
    this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(offlineQueueStreamProvider);

    return queueAsync.when(
      data: (queue) {
        // Filtruj podle conversationId pokud je zadano
        final filtered = conversationId != null
            ? queue.where((m) => m.conversationId == conversationId).toList()
            : queue;

        if (filtered.isEmpty) return const SizedBox.shrink();

        final pendingCount = filtered.where((m) => m.status == MessageStatus.pending).length;
        final sendingCount = filtered.where((m) => m.status == MessageStatus.sending).length;
        final failedCount = filtered.where((m) => m.status == MessageStatus.failed).length;

        if (pendingCount == 0 && sendingCount == 0 && failedCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: failedCount > 0
                ? AppColors.error.withAlpha(20)
                : AppColors.warning.withAlpha(20),
            border: Border(
              bottom: BorderSide(
                color: failedCount > 0 ? AppColors.error : AppColors.warning,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (sendingCount > 0) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (failedCount > 0) ...[
                Icon(Icons.error_outline, size: 16, color: AppColors.error),
                const SizedBox(width: 8),
              ] else ...[
                Icon(Icons.cloud_off, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  _buildStatusText(pendingCount, sendingCount, failedCount),
                  style: TextStyle(
                    fontSize: 12,
                    color: failedCount > 0 ? AppColors.error : AppColors.warning,
                  ),
                ),
              ),
              if (failedCount > 0)
                TextButton(
                  onPressed: () => _retryAll(ref, filtered),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(
                    'Zkusit znovu',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _buildStatusText(int pending, int sending, int failed) {
    final parts = <String>[];

    if (sending > 0) {
      parts.add('Odesilam $sending ${_pluralize(sending, 'zpravu', 'zpravy', 'zprav')}');
    }
    if (pending > 0) {
      parts.add('$pending ${_pluralize(pending, 'zprava', 'zpravy', 'zprav')} ceka');
    }
    if (failed > 0) {
      parts.add('$failed ${_pluralize(failed, 'zprava', 'zpravy', 'zprav')} selhalo');
    }

    return parts.join(' · ');
  }

  String _pluralize(int count, String one, String few, String many) {
    if (count == 1) return one;
    if (count >= 2 && count <= 4) return few;
    return many;
  }

  void _retryAll(WidgetRef ref, List<QueuedMessage> queue) {
    final service = ref.read(offlineQueueServiceProvider);
    for (final message in queue) {
      if (message.status == MessageStatus.failed) {
        service.retry(message.id);
      }
    }
  }
}

/// Widget pro zobrazeni jednotlive zpravy ve fronte (pro pending message bubble)
class PendingMessageBubble extends StatelessWidget {
  final QueuedMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const PendingMessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isFailed = message.status == MessageStatus.failed;
    final isSending = message.status == MessageStatus.sending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3, left: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(isFailed ? 100 : 180),
                    AppColors.primary.withAlpha(isFailed ? 80 : 150),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: Colors.white.withAlpha(isFailed ? 180 : 255),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSending) ...[
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.white.withAlpha(180),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Odesilam...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withAlpha(180),
                          ),
                        ),
                      ] else if (isFailed) ...[
                        Icon(Icons.error_outline, size: 12, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Neodeslano',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onRetry,
                          child: Text(
                            'Zkusit znovu',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(Icons.schedule, size: 12, color: Colors.white.withAlpha(150)),
                        const SizedBox(width: 4),
                        Text(
                          'Ceka na odeslani',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withAlpha(150),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
