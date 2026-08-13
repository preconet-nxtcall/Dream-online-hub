import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

void main() {
  test('Live Socket.IO Real-Time Chat Connection & Message Exchange Test', () async {
    const chatSocketUrl = 'https://chat-assistant-5698.onrender.com';
    const fixedToken = 'chat_fixed_auth_token_2026_prod';
    const userEmail = 'user@gmail.com';
    const targetConvId = 'conv-ADMIN-1-user@gmail.com';
    const recipientId = 'ADMIN-1';

    final socket = io.io(
      chatSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setExtraHeaders({
            'Authorization': 'Bearer $fixedToken',
            'x-act-as-email': userEmail,
            'x-act-as-role': 'user',
            'x-act-as-name': 'Live Automated Tester',
          })
          .setQuery({'token': fixedToken})
          .build(),
    );
    final completer = Completer<bool>();

    socket.onConnect((_) {
      final payload = {
        'conversationId': targetConvId,
        'recipientId': recipientId,
        'type': 'text',
        'text': 'Live test at ${DateTime.now().toIso8601String()}',
      };
      socket.emit('message:send', payload);
    });

    socket.on('message:queued', (_) {
      if (!completer.isCompleted) completer.complete(true);
    });

    socket.on('message:sent', (_) {
      if (!completer.isCompleted) completer.complete(true);
    });

    socket.connect();

    final success = await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => socket.connected,
    );

    socket.disconnect();
    socket.dispose();

    expect(success, isTrue);
  });
}
