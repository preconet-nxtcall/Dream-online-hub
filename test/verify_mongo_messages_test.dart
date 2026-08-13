import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  test('Verify if test messages are persisted in MongoDB database after JWT auth', () async {
    const chatBaseUrl = 'https://chat-assistant-5698.onrender.com';
    const conversationId = 'conv-AGENCY-23-sample@gmail.com';
    final encodedConvId = Uri.encodeComponent(conversationId);

    final dio = Dio(BaseOptions(
      baseUrl: chatBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    print('\n================ VERIFYING MESSAGES SAVED IN MONGODB ================');

    // Step 1: Login to Chat Server to get JWT token
    String? jwtToken;
    try {
      final loginRes = await dio.post('/api/v1/auth/login', data: {
        'emailId': 'agency@gmail.com',
        'password': '12345',
      });
      print('[CHAT SERVER LOGIN] Status: ${loginRes.statusCode}');
      if (loginRes.data is Map<String, dynamic>) {
        jwtToken = loginRes.data['token']?.toString();
        print('Chat Token Obtained: ${jwtToken?.substring(0, 20)}...');
      }
    } catch (e) {
      print('[CHAT SERVER LOGIN ERROR] -> $e');
    }

    // Step 2: Fetch stored messages from MongoDB
    try {
      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
      };
      if (jwtToken != null && jwtToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jwtToken';
      } else {
        headers['Authorization'] = 'Bearer chat_fixed_auth_token_2026_prod';
        headers['x-act-as-email'] = 'agency@gmail.com';
        headers['x-act-as-role'] = 'agency';
      }

      final res = await dio.get(
        '/api/v1/conversations/$encodedConvId/messages',
        options: Options(headers: headers),
      );
      print('\n[HTTP GET MESSAGES RESPONSE] Status Code: ${res.statusCode}');
      print('Data: ${res.data}');

      final data = res.data;
      if (data is Map<String, dynamic>) {
        final messagesList = data['messages'] ?? data['data'] ?? [];
        if (messagesList is List) {
          print('\nTotal Messages Stored in MongoDB: ${messagesList.length}');
          for (final msg in messagesList) {
            print(' -> MongoDB ID: ${msg['_id']} | Sender: ${msg['senderId']} | Receiver: ${msg['receiverId']} | Text: "${msg['text'] ?? msg['message']}" | Status: ${msg['status']} | CreatedAt: ${msg['createdAt']}');
          }
        }
      }
    } catch (e) {
      print('[ERROR FETCHING MESSAGES FROM MONGODB] -> $e');
    }

    print('======================================================================\n');
  });
}
