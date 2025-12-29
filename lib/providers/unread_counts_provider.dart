import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model pro počty nepřečtených položek
class UnreadCounts {
  final int messages;
  final int notifications;

  const UnreadCounts({
    this.messages = 0,
    this.notifications = 0,
  });

  int get total => messages + notifications;

  UnreadCounts copyWith({int? messages, int? notifications}) {
    return UnreadCounts(
      messages: messages ?? this.messages,
      notifications: notifications ?? this.notifications,
    );
  }
}

/// Notifier pro sledování nepřečtených zpráv a notifikací
class UnreadCountsNotifier extends Notifier<UnreadCounts> {
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _notificationsChannel;

  @override
  UnreadCounts build() {
    // Načti počty při inicializaci
    _loadCounts();
    _setupRealtimeListeners();

    ref.onDispose(() {
      _messagesChannel?.unsubscribe();
      _notificationsChannel?.unsubscribe();
    });

    return const UnreadCounts();
  }

  SupabaseClient get _supabase => Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> _loadCounts() async {
    if (_userId == null) return;

    try {
      // Počet nepřečtených zpráv
      final messagesCount = await _getUnreadMessagesCount();

      // Počet nepřečtených notifikací
      final notificationsCount = await _getUnreadNotificationsCount();

      state = UnreadCounts(
        messages: messagesCount,
        notifications: notificationsCount,
      );
    } catch (e) {
      // Ignoruj chyby při načítání
    }
  }

  Future<int> _getUnreadMessagesCount() async {
    if (_userId == null) return 0;

    try {
      // Získej všechny konverzace uživatele
      final participantsResponse = await _supabase
          .from('conversation_participants')
          .select('conversation_id, last_read_at')
          .eq('user_id', _userId!);

      int totalUnread = 0;

      for (final participant in participantsResponse as List) {
        final conversationId = participant['conversation_id'] as String;
        final lastReadAt = participant['last_read_at'] as String?;

        // Spočítej nepřečtené zprávy v konverzaci
        var query = _supabase
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId)
            .neq('sender_id', _userId!);

        if (lastReadAt != null) {
          query = query.gt('created_at', lastReadAt);
        }

        final messages = await query;
        totalUnread += (messages as List).length;
      }

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getUnreadNotificationsCount() async {
    if (_userId == null) return 0;

    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', _userId!)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  void _setupRealtimeListeners() {
    if (_userId == null) return;

    // Poslouchej nové zprávy
    _messagesChannel = _supabase
        .channel('unread_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final senderId = payload.newRecord['sender_id'] as String?;
            if (senderId != _userId) {
              // Nová zpráva od někoho jiného
              state = state.copyWith(messages: state.messages + 1);
            }
          },
        )
        .subscribe();

    // Poslouchej nové notifikace
    _notificationsChannel = _supabase
        .channel('unread_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (payload) {
            state = state.copyWith(notifications: state.notifications + 1);
          },
        )
        .subscribe();
  }

  /// Označí zprávy jako přečtené
  void markMessagesAsRead(int count) {
    final newCount = (state.messages - count).clamp(0, 999);
    state = state.copyWith(messages: newCount);
  }

  /// Označí všechny zprávy jako přečtené
  void markAllMessagesAsRead() {
    state = state.copyWith(messages: 0);
  }

  /// Označí notifikace jako přečtené
  void markNotificationsAsRead(int count) {
    final newCount = (state.notifications - count).clamp(0, 999);
    state = state.copyWith(notifications: newCount);
  }

  /// Označí všechny notifikace jako přečtené
  void markAllNotificationsAsRead() {
    state = state.copyWith(notifications: 0);
  }

  /// Obnoví počty z databáze
  Future<void> refresh() async {
    await _loadCounts();
  }
}

/// Provider pro nepřečtené počty
final unreadCountsProvider = NotifierProvider<UnreadCountsNotifier, UnreadCounts>(() {
  return UnreadCountsNotifier();
});

/// Provider jen pro počet nepřečtených zpráv
final unreadMessagesCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountsProvider).messages;
});

/// Provider jen pro počet nepřečtených notifikací
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountsProvider).notifications;
});
