import '../storage/local_storage_repository.dart';
import '../utils/logger.dart';

class PendingSocketMessage {
  final String id;
  final String event;
  final dynamic payload;
  final DateTime timestamp;
  final Function(dynamic response)? onAck;

  PendingSocketMessage({
    required this.id,
    required this.event,
    required this.payload,
    required this.timestamp,
    this.onAck,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'event': event,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
      };
}

class MessageQueueService {
  final List<PendingSocketMessage> _queue = [];
  final LocalStorageRepository _localStorage;

  MessageQueueService({LocalStorageRepository? localStorage})
      : _localStorage = localStorage ?? LocalStorageRepositoryImpl() {
    _restorePersistentQueue();
  }

  List<PendingSocketMessage> get pendingMessages => List.unmodifiable(_queue);
  int get count => _queue.length;
  bool get isEmpty => _queue.isEmpty;

  void _restorePersistentQueue() {
    try {
      final saved = _localStorage.getOfflineQueue();
      if (saved.isNotEmpty) {
        for (final item in saved) {
          _queue.add(PendingSocketMessage(
            id: item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            event: item['event'] ?? 'unknown',
            payload: item['payload'],
            timestamp: item['timestamp'] != null
                ? DateTime.tryParse(item['timestamp']) ?? DateTime.now()
                : DateTime.now(),
          ));
        }
        AppLogger.info('Restored ${_queue.length} pending offline messages from persistent Hive storage.');
      }
    } catch (e) {
      AppLogger.error('Failed restoring persistent offline queue: $e');
    }
  }

  void _persistQueue() {
    try {
      final jsonList = _queue.map((m) => m.toJson()).toList();
      _localStorage.saveOfflineQueue(jsonList);
    } catch (_) {}
  }

  void enqueue({
    required String event,
    required dynamic payload,
    Function(dynamic response)? onAck,
  }) {
    final item = PendingSocketMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      event: event,
      payload: payload,
      timestamp: DateTime.now(),
      onAck: onAck,
    );
    _queue.add(item);
    _persistQueue();
    AppLogger.info('Message queued offline [${item.event}]. Current queue size: ${_queue.length}');
  }

  void flush(Function(String event, dynamic payload, Function(dynamic response)? onAck) emitter) {
    if (_queue.isEmpty) return;

    AppLogger.info('Flushing ${_queue.length} pending offline socket messages...');
    final itemsToFlush = List<PendingSocketMessage>.from(_queue);
    _queue.clear();
    _localStorage.clearOfflineQueue();

    for (final item in itemsToFlush) {
      try {
        emitter(item.event, item.payload, item.onAck);
      } catch (e) {
        AppLogger.error('Error flushing queued message [${item.event}]: $e');
      }
    }
  }

  void clear() {
    _queue.clear();
    _localStorage.clearOfflineQueue();
  }
}
