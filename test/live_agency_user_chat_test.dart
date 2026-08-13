import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

void main() {
  test('Live Real-Time Socket Chat Test between Agency and Assigned User', () async {
    const chatSocketUrl = 'https://chat-assistant-5698.onrender.com';
    const fixedToken = 'chat_fixed_auth_token_2026_prod';

    const agencyEmail = 'agency@gmail.com';
    const agencyId = 'AGENCY-23';

    const userEmail = 'sample@gmail.com';

    final conversationId = 'conv-$agencyId-$userEmail';

    print('\n================ LIVE AGENCY <-> ASSIGNED USER REALTIME CHAT TEST ================');
    print('Conversation ID: $conversationId');
    print('Agency: $agencyEmail ($agencyId)');
    print('Assigned User: $userEmail');

    // 1. Connect Agency Socket
    final agencySocket = io.io(
      chatSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setExtraHeaders({
            'Authorization': 'Bearer $fixedToken',
            'x-act-as-email': agencyEmail,
            'x-act-as-role': 'agency',
            'x-act-as-name': 'Ritdz 4k Agency',
          })
          .setQuery({'token': fixedToken})
          .build(),
    );

    // 2. Connect User Socket
    final userSocket = io.io(
      chatSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setExtraHeaders({
            'Authorization': 'Bearer $fixedToken',
            'x-act-as-email': userEmail,
            'x-act-as-role': 'user',
            'x-act-as-name': 'Lorem Ipsum User',
          })
          .setQuery({'token': fixedToken})
          .build(),
    );

    final agencyReceivedCompleter = Completer<Map<String, dynamic>>();
    final userReceivedCompleter = Completer<Map<String, dynamic>>();

    agencySocket.on('message:receive', (data) {
      print('[AGENCY SOCKET] Received incoming message: $data');
      if (!agencyReceivedCompleter.isCompleted && data is Map<String, dynamic>) {
        agencyReceivedCompleter.complete(data);
      }
    });

    userSocket.on('message:receive', (data) {
      print('[USER SOCKET] Received incoming agency reply: $data');
      if (!userReceivedCompleter.isCompleted && data is Map<String, dynamic>) {
        userReceivedCompleter.complete(data);
      }
    });

    agencySocket.connect();
    userSocket.connect();

    // Wait briefly for both sockets to connect
    await Future.delayed(const Duration(seconds: 2));
    print('Agency Socket Connected: ${agencySocket.connected}');
    print('User Socket Connected: ${userSocket.connected}');

    // 3. User sends message to Agency
    final userMsgText = 'Hello Agency! I need support with my account. (${DateTime.now().second}s)';
    print('\n[USER -> AGENCY] Sending message: "$userMsgText"');

    final userMsgPayload = {
      'conversationId': conversationId,
      'recipientId': agencyId,
      'type': 'text',
      'text': userMsgText,
    };

    userSocket.emit('message:send', userMsgPayload);

    // 4. Agency sends reply back to User
    final agencyReplyText = 'Hello Client! We are here to help you right now. (${DateTime.now().second}s)';
    print('[AGENCY -> USER] Sending reply: "$agencyReplyText"');

    final agencyReplyPayload = {
      'conversationId': conversationId,
      'recipientId': userEmail,
      'type': 'text',
      'text': agencyReplyText,
    };

    agencySocket.emit('message:send', agencyReplyPayload);

    await Future.delayed(const Duration(seconds: 3));

    agencySocket.disconnect();
    agencySocket.dispose();
    userSocket.disconnect();
    userSocket.dispose();

    print('\n================ CHAT EXCHANGE TEST COMPLETE ================');
  });
}
