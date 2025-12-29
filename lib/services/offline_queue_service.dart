import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model pro zpravu ve fronte
class QueuedMessage {
  final String id;
  final String conversationId;
  final String content;
  final String messageType;
  final Map<String, dynamic>? metadata;
  final String? replyToId;
  final DateTime createdAt;
  final int retryCount;
  final MessageStatus status;

  QueuedMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    this.messageType = 'text',
    this.metadata,
    this.replyToId,
    required this.createdAt,
    this.retryCount = 0,
    this.status = MessageStatus.pending,
  });

  QueuedMessage copyWith({
    String? id,
    String? conversationId,
    String? content,
    String? messageType,
    Map<String, dynamic>? metadata,
    String? replyToId,
    DateTime? createdAt,
    int? retryCount,
    MessageStatus? status,
  }) {
    return QueuedMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      replyToId: replyToId ?? this.replyToId,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'content': content,
        'messageType': messageType,
        'metadata': metadata,
        'replyToId': replyToId,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'status': status.name,
      };

  factory QueuedMessage.fromJson(Map<String, dynamic> json) {
    return QueuedMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      content: json['content'] as String,
      messageType: json['messageType'] as String? ?? 'text',
      metadata: json['metadata'] as Map<String, dynamic>?,
      replyToId: json['replyToId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.pending,
      ),
    );
  }
}

enum MessageStatus {
  pending,
  sending,
  sent,
  failed,
}

/// Callback pro odeslani zpravy
typedef SendMessageCallback = Future<bool> Function(QueuedMessage message);

/// Service pro spravu offline fronty zprav
class OfflineQueueService {
  static const String _storageKey = 'offline_message_queue';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  final List<QueuedMessage> _queue = [];
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SendMessageCallback? _sendCallback;
  bool _isProcessing = false;
  bool _isOnline = true;

  /// Stream pro sledovani stavu fronty
  final _queueController = StreamController<List<QueuedMessage>>.broadcast();
  Stream<List<QueuedMessage>> get queueStream => _queueController.stream;

  /// Aktualni stav fronty
  List<QueuedMessage> get queue => List.unmodifiable(_queue);

  /// Pocet zprav ve fronte
  int get pendingCount => _queue.where((m) => m.status == MessageStatus.pending).length;

  /// Inicializuje service
  Future<void> initialize({required SendMessageCallback sendCallback}) async {
    _sendCallback = sendCallback;

    // Nacti frontu z uloziste
    await _loadQueue();

    // Sleduj zmeny pripojeni
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Zkontroluj aktualni stav
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);

    // Pokud jsme online, zpracuj frontu
    if (_isOnline && _queue.isNotEmpty) {
      _processQueue();
    }
  }

  /// Ukonci service
  void dispose() {
    _connectivitySubscription?.cancel();
    _queueController.close();
  }

  /// Prida zpravu do fronty
  Future<QueuedMessage> enqueue({
    required String conversationId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    final message = QueuedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      content: content,
      messageType: messageType,
      metadata: metadata,
      replyToId: replyToId,
      createdAt: DateTime.now(),
    );

    _queue.add(message);
    await _saveQueue();
    _notifyQueueChanged();

    debugPrint('OfflineQueue: Enqueued message ${message.id}');

    // Pokud jsme online, ihned zpracuj
    if (_isOnline) {
      _processQueue();
    }

    return message;
  }

  /// Odebere zpravu z fronty
  Future<void> remove(String messageId) async {
    _queue.removeWhere((m) => m.id == messageId);
    await _saveQueue();
    _notifyQueueChanged();
  }

  /// Zrusi odeslani zpravy
  Future<void> cancel(String messageId) async {
    final index = _queue.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(status: MessageStatus.failed);
      await _saveQueue();
      _notifyQueueChanged();
    }
  }

  /// Zkusi znovu odeslat zpravu
  Future<void> retry(String messageId) async {
    final index = _queue.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: MessageStatus.pending,
        retryCount: 0,
      );
      await _saveQueue();
      _notifyQueueChanged();

      if (_isOnline) {
        _processQueue();
      }
    }
  }

  /// Zpracuje frontu zprav
  Future<void> _processQueue() async {
    if (_isProcessing || _sendCallback == null) return;
    _isProcessing = true;

    debugPrint('OfflineQueue: Processing queue (${_queue.length} messages)');

    while (_queue.isNotEmpty && _isOnline) {
      // Najdi dalsi pending zpravu
      final index = _queue.indexWhere((m) => m.status == MessageStatus.pending);
      if (index == -1) break;

      final message = _queue[index];

      // Oznac jako sending
      _queue[index] = message.copyWith(status: MessageStatus.sending);
      _notifyQueueChanged();

      try {
        final success = await _sendCallback!(message);

        if (success) {
          // Uspesne odeslano - odeber z fronty
          _queue.removeAt(index);
          debugPrint('OfflineQueue: Message ${message.id} sent successfully');
        } else {
          // Neuspesne - zvys pocet pokusu
          await _handleFailure(index, message);
        }
      } catch (e) {
        debugPrint('OfflineQueue: Error sending message ${message.id}: $e');
        await _handleFailure(index, message);
      }

      await _saveQueue();
      _notifyQueueChanged();
    }

    _isProcessing = false;
  }

  /// Zpracuje neuspesne odeslani
  Future<void> _handleFailure(int index, QueuedMessage message) async {
    if (message.retryCount >= _maxRetries) {
      // Prekrocen pocet pokusu
      _queue[index] = message.copyWith(status: MessageStatus.failed);
      debugPrint('OfflineQueue: Message ${message.id} failed after $_maxRetries retries');
    } else {
      // Zkusi znovu po prodleve
      _queue[index] = message.copyWith(
        status: MessageStatus.pending,
        retryCount: message.retryCount + 1,
      );
      debugPrint('OfflineQueue: Message ${message.id} retry ${message.retryCount + 1}/$_maxRetries');

      // Pockej pred dalsim pokusem
      await Future.delayed(_retryDelay);
    }
  }

  /// Reakce na zmenu pripojeni
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    debugPrint('OfflineQueue: Connectivity changed - online: $_isOnline');

    // Pokud jsme prave presli do online stavu, zpracuj frontu
    if (!wasOnline && _isOnline && _queue.isNotEmpty) {
      _processQueue();
    }
  }

  /// Nacte frontu z uloziste
  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _queue.clear();
        _queue.addAll(jsonList.map((j) => QueuedMessage.fromJson(j)));

        // Reset sending zprav na pending (mohly zustat ve stavu sending po padu)
        for (var i = 0; i < _queue.length; i++) {
          if (_queue[i].status == MessageStatus.sending) {
            _queue[i] = _queue[i].copyWith(status: MessageStatus.pending);
          }
        }

        debugPrint('OfflineQueue: Loaded ${_queue.length} messages from storage');
      }
    } catch (e) {
      debugPrint('OfflineQueue: Error loading queue: $e');
    }
  }

  /// Ulozi frontu do uloziste
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_queue.map((m) => m.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('OfflineQueue: Error saving queue: $e');
    }
  }

  /// Notifikuje o zmene fronty
  void _notifyQueueChanged() {
    if (!_queueController.isClosed) {
      _queueController.add(List.unmodifiable(_queue));
    }
  }
}
