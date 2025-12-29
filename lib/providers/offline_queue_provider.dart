import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_queue_service.dart';
import 'chat_provider.dart';

/// Provider pro offline queue service
final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  final service = OfflineQueueService();
  final chatService = ref.watch(chatServiceProvider);

  // Inicializuj service s callback pro odeslani zpravy
  service.initialize(
    sendCallback: (message) async {
      try {
        await chatService.sendMessage(
          conversationId: message.conversationId,
          content: message.content,
          messageType: message.messageType,
          metadata: message.metadata,
          replyToId: message.replyToId,
        );
        return true;
      } catch (e) {
        return false;
      }
    },
  );

  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider pro stream zprav ve fronte
final offlineQueueStreamProvider = StreamProvider<List<QueuedMessage>>((ref) {
  final service = ref.watch(offlineQueueServiceProvider);
  return service.queueStream;
});

/// Provider pro pocet cekajicich zprav
final pendingMessagesCountProvider = Provider<int>((ref) {
  final queueAsync = ref.watch(offlineQueueStreamProvider);
  return queueAsync.when(
    data: (queue) => queue.where((m) => m.status == MessageStatus.pending).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});
