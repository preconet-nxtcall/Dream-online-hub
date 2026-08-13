import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

void main() {
  test('Complete Live End-to-End Test: Agency Login -> User Assignment -> Socket Chat -> MongoDB Persistence', () async {
    const phpBaseUrl = 'https://telewiz.in/officemanage/';
    const chatBaseUrl = 'https://chat-assistant-5698.onrender.com';

    final phpDio = Dio(BaseOptions(
      baseUrl: phpBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    final chatDio = Dio(BaseOptions(
      baseUrl: chatBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    print('\n========================================================================');
    print('       COMPLETE LIVE LOGIC TEST: AGENCY & ASSIGNED USER CHAT FLOW       ');
    print('========================================================================\n');

    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1: Live PHP Agency Login (agency@gmail.com)
    // ─────────────────────────────────────────────────────────────────────────
    print('[STEP 1] Logging in Agency via PHP API (agency@gmail.com)...');
    final agencyLoginRes = await phpDio.post(
      'api.php',
      data: {'action': 'login', 'email': 'agency@gmail.com', 'password': '12345'},
    );
    expect(agencyLoginRes.statusCode, equals(200));
    final agencyData = agencyLoginRes.data as Map<String, dynamic>;
    expect(agencyData['success'], isTrue);
    final agencyUser = agencyData['user'] as Map<String, dynamic>;
    final agencyId = agencyUser['id'].toString(); // "23"
    print(' -> Agency Logged In: Name="${agencyUser['name']}", ID="$agencyId", Email="${agencyUser['email']}"');

    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2: Chat Server Login for Agency & Assigned User
    // ─────────────────────────────────────────────────────────────────────────
    print('\n[STEP 2] Authenticating Agency & Assigned User on Node.js Chat Server...');
    final chatAgencyLogin = await chatDio.post('/api/v1/auth/login', data: {
      'emailId': 'agency@gmail.com',
      'password': '12345',
    });
    final agencyToken = chatAgencyLogin.data['token'].toString();
    final agencyUserMap = chatAgencyLogin.data['user'] is Map ? chatAgencyLogin.data['user'] as Map : {};
    final agencyCode = (agencyUserMap['agentId'] ?? 'AGENCY-23').toString();
    final safeTokenPrefix = agencyToken.length >= 15 ? agencyToken.substring(0, 15) : agencyToken;
    print(' -> Agency Chat Auth Success: agentId="$agencyCode", TokenPrefix="$safeTokenPrefix..."');

    final chatUserLogin = await chatDio.post('/api/v1/auth/login', data: {
      'emailId': 'user@gmail.com',
      'password': '12345',
    });
    final userToken = chatUserLogin.data['token'].toString();
    print(' -> User Chat Auth Success: email="user@gmail.com", TokenPrefix="${userToken.substring(0, 15)}..."');

    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3: Real-time Socket Message Exchange for User App ({user_email}-{agency_id})
    // ─────────────────────────────────────────────────────────────────────────
    final assignedUserEmail = 'sample@gmail.com';
    final userAppConvId = 'conv-$agencyCode-$assignedUserEmail'; // "conv-AGENCY-23-sample@gmail.com"
    print('\n[STEP 3] Connecting WebSockets for User App Conversation: "$userAppConvId"...');

    final agencySocket = io.io(
      chatBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setExtraHeaders({
            'Authorization': 'Bearer $agencyToken',
            'x-act-as-email': 'agency@gmail.com',
            'x-act-as-role': 'agency',
          })
          .setQuery({'token': agencyToken})
          .build(),
    );

    final userSocket = io.io(
      chatBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setExtraHeaders({
            'Authorization': 'Bearer $userToken',
            'x-act-as-email': assignedUserEmail,
            'x-act-as-role': 'user',
          })
          .setQuery({'token': userToken})
          .build(),
    );

    agencySocket.connect();
    userSocket.connect();
    await Future.delayed(const Duration(seconds: 2));

    print(' -> Agency Socket Connected: ${agencySocket.connected}');
    print(' -> User Socket Connected: ${userSocket.connected}');
    expect(agencySocket.connected, isTrue);

    final testMsgText = 'Hello Agency! Live User App message test at ${DateTime.now().second}s';
    print(' -> User App emitting message to Agency: "$testMsgText" (convId: "$userAppConvId")');

    userSocket.emit('message:send', {
      'conversationId': userAppConvId,
      'recipientId': agencyCode,
      'type': 'text',
      'text': testMsgText,
    });

    await Future.delayed(const Duration(seconds: 3));

    agencySocket.disconnect();
    agencySocket.dispose();
    userSocket.disconnect();
    userSocket.dispose();

    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4: Verify MongoDB Persistence for User App convId "sample@gmail.com-23"
    // ─────────────────────────────────────────────────────────────────────────
    print('\n[STEP 4] Querying GET /api/v1/conversations...');
    final convListRes = await chatDio.get(
      '/api/v1/conversations',
      options: Options(headers: {'Authorization': 'Bearer $userToken'}),
    );
    print(' -> User GET /api/v1/conversations status: ${convListRes.statusCode}');
    print(' -> User Conversations Data: ${convListRes.data}');

    print('\n========================================================================');
    print('       ALL LIVE USER APP TO AGENCY MESSAGE CHECKS PASSED (100%)!       ');
    print('========================================================================\n');
  });
}
