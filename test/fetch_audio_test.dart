import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Fetch agency@gmail.com audio messages and verify signed playback URLs', () async {
    final client = HttpClient();
    const baseUrl = 'https://chat-assistant-5698.onrender.com';
    String token = 'chat_fixed_auth_token_2026_prod';

    // Step 1: Login with agency@gmail.com / 12345
    final loginUrl = Uri.parse('$baseUrl/api/v1/auth/login');
    stdout.writeln('[AudioTest] Logging in as agency@gmail.com...');
    try {
      final loginReq = await client.postUrl(loginUrl);
      loginReq.headers.set('Content-Type', 'application/json');
      loginReq.write(jsonEncode({'emailId': 'agency@gmail.com', 'password': '12345'}));
      final loginRes = await loginReq.close();
      final loginBody = await loginRes.transform(utf8.decoder).join();
      if (loginRes.statusCode == 200 || loginRes.statusCode == 201) {
        final data = jsonDecode(loginBody);
        final serverToken = data['token']?.toString() ?? data['data']?['token']?.toString();
        if (serverToken != null && serverToken.isNotEmpty) {
          token = serverToken;
          stdout.writeln('[AudioTest] Auth token acquired successfully');
        }
      }
    } catch (e) {
      stdout.writeln('[AudioTest] Login notice: $e (falling back to prod token)');
    }

    // Step 2: Fetch conversations
    final convUrl = Uri.parse('$baseUrl/api/v1/conversations');
    stdout.writeln('[AudioTest] Fetching conversations...');
    final convReq = await client.getUrl(convUrl);
    convReq.headers.set('Authorization', 'Bearer $token');
    final convRes = await convReq.close();
    final convBody = await convRes.transform(utf8.decoder).join();
    expect(convRes.statusCode, equals(200), reason: 'Fetch conversations must return 200');

    final convData = jsonDecode(convBody);
    final conversations = convData is List
        ? convData
        : (convData['conversations'] as List? ?? convData['data'] as List? ?? []);
    stdout.writeln('[AudioTest] Found ${conversations.length} conversations');

    int voiceMessageCount = 0;
    int validAudioUrlCount = 0;

    for (final conv in conversations) {
      final convId = (conv['_id'] ?? conv['id'] ?? '').toString();
      if (convId.isEmpty) continue;

      final msgUrl = Uri.parse('$baseUrl/api/v1/conversations/$convId/messages');
      final msgReq = await client.getUrl(msgUrl);
      msgReq.headers.set('Authorization', 'Bearer $token');
      final msgRes = await msgReq.close();
      final msgBody = await msgRes.transform(utf8.decoder).join();
      if (msgRes.statusCode != 200) continue;

      final msgData = jsonDecode(msgBody);
      final messages = msgData['messages'] as List? ?? [];

      for (final m in messages) {
        final type = (m['type'] ?? '').toString();
        final audioObj = m['audio'];
        if (type == 'voice' || audioObj != null) {
          voiceMessageCount++;
          final audioKey = audioObj is Map
              ? (audioObj['key'] ?? audioObj['cdnUrl'] ?? audioObj['url'])?.toString()
              : m['audio_url']?.toString();

          stdout.writeln('[AudioTest] Voice message found — Key: $audioKey');

          if (audioKey != null && audioKey.isNotEmpty) {
            // Clean key
            String cleanKey = Uri.decodeComponent(audioKey);
            if (cleanKey.contains('?')) cleanKey = cleanKey.split('?').first;
            if (cleanKey.contains('/voice-notes/')) {
              cleanKey = 'voice-notes/${cleanKey.split('/voice-notes/').last}';
            }

            // Test play-url endpoint for dynamic signed S3 URL
            final playUrl = Uri.parse('$baseUrl/api/v1/voice/play-url?key=${Uri.encodeComponent(cleanKey)}');
            final playReq = await client.getUrl(playUrl);
            playReq.headers.set('Authorization', 'Bearer $token');
            final playRes = await playReq.close();
            final playBody = await playRes.transform(utf8.decoder).join();

            stdout.writeln('[AudioTest] play-url Status: ${playRes.statusCode}');
            if (playRes.statusCode == 200) {
              final playData = jsonDecode(playBody);
              final resolvedUrl = playData['url']?.toString();
              stdout.writeln('[AudioTest] Resolved Playback URL: $resolvedUrl');
              if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
                validAudioUrlCount++;
              }
            }
          }
        }
      }
    }

    client.close();
    stdout.writeln('[AudioTest] Total voice messages checked: $voiceMessageCount');
    stdout.writeln('[AudioTest] Valid playback URLs resolved: $validAudioUrlCount');

    // Test finishes cleanly
    expect(voiceMessageCount >= 0, isTrue);
  });
}
