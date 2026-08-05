import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agency_user_app/socket/message_queue_service.dart';
import 'package:agency_user_app/socket/socket_events.dart';
import 'package:agency_user_app/socket/socket_service.dart';
import 'package:agency_user_app/socket/socket_state.dart';
import 'package:agency_user_app/socket/providers/socket_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SocketState Tests', () {
    test('Default SocketState is disconnected with zero metrics', () {
      const state = SocketState();
      expect(state.status, equals(SocketStatus.disconnected));
      expect(state.isConnected, isFalse);
      expect(state.isReconnecting, isFalse);
      expect(state.reconnectAttempts, equals(0));
      expect(state.pingLatencyMs, equals(0));
      expect(state.queuedMessagesCount, equals(0));
      expect(state.onlineUserIds, isEmpty);
      expect(state.typingUsers, isEmpty);
    });

    test('copyWith produces updated immutable SocketState', () {
      const state = SocketState();
      final updated = state.copyWith(
        status: SocketStatus.connected,
        reconnectAttempts: 2,
        pingLatencyMs: 45,
        onlineUserIds: {'usr_1', 'usr_2'},
      );

      expect(updated.status, equals(SocketStatus.connected));
      expect(updated.isConnected, isTrue);
      expect(updated.reconnectAttempts, equals(2));
      expect(updated.pingLatencyMs, equals(45));
      expect(updated.onlineUserIds.length, equals(2));
    });
  });

  group('MessageQueueService Tests', () {
    late MessageQueueService queueService;

    setUp(() {
      queueService = MessageQueueService();
    });

    test('Enqueueing buffers messages correctly', () {
      expect(queueService.count, equals(0));
      expect(queueService.isEmpty, isTrue);

      queueService.enqueue(
        event: SocketEvents.sendMessage,
        payload: {'receiver_id': 'usr_1', 'message': 'Hello'},
      );

      expect(queueService.count, equals(1));
      expect(queueService.isEmpty, isFalse);
      expect(queueService.pendingMessages.first.event, equals(SocketEvents.sendMessage));
    });

    test('Flushing queue executes emitter and clears pending items', () {
      queueService.enqueue(
        event: SocketEvents.sendMessage,
        payload: {'receiver_id': 'usr_1', 'message': 'Test 1'},
      );
      queueService.enqueue(
        event: SocketEvents.sendMessage,
        payload: {'receiver_id': 'usr_2', 'message': 'Test 2'},
      );

      expect(queueService.count, equals(2));

      final List<String> emittedEvents = [];
      queueService.flush((event, payload, onAck) {
        emittedEvents.add(event);
      });

      expect(emittedEvents.length, equals(2));
      expect(queueService.count, equals(0));
      expect(queueService.isEmpty, isTrue);
    });
  });

  group('Riverpod Socket Providers Tests', () {
    test('Riverpod container reads socketServiceProvider singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(socketServiceProvider);
      expect(service, isNotNull);
      expect(service, equals(SocketService.instance));
    });

    test('socketStateNotifierProvider initializes with SocketState', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(socketStateNotifierProvider);
      expect(state.status, equals(SocketStatus.disconnected));
    });
  });
}
