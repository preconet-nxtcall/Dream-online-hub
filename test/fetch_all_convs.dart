import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  final url = Uri.parse('https://chat-assistant-5698.onrender.com/api/v1/conversations');
  print('Fetching all conversations from $url...');

  try {
    final req = await client.getUrl(url);
    req.headers.set('Authorization', 'Bearer chat_fixed_auth_token_2026_prod');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    print('HTTP Status: ${res.statusCode}');
    print('Response: $body');
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
