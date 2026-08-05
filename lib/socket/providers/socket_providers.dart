import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat/chat_message_model.dart';
import '../socket_service.dart';
import '../socket_state.dart';

/// Provider for singleton SocketService
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService.instance;
  ref.onDispose(() {
    // Keep singleton alive or dispose if desired
  });
  return service;
});

/// StateNotifier for real-time SocketState metrics & status
class SocketStateNotifier extends StateNotifier<SocketState> {
  final SocketService _socketService;

  SocketStateNotifier(this._socketService) : super(_socketService.state) {
    _socketService.stateStream.listen((newState) {
      if (mounted) {
        state = newState;
      }
    });
  }

  Future<void> connect({String? customToken}) async {
    await _socketService.connect(customToken: customToken);
  }

  void disconnect() {
    _socketService.disconnect();
  }

  void sendTypingStart(String receiverId) {
    _socketService.sendTypingStart(receiverId);
  }

  void sendTypingStop(String receiverId) {
    _socketService.sendTypingStop(receiverId);
  }
}

final socketStateNotifierProvider =
    StateNotifierProvider<SocketStateNotifier, SocketState>((ref) {
  final service = ref.watch(socketServiceProvider);
  return SocketStateNotifier(service);
});

/// StreamProvider for incoming real-time chat messages
final realtimeMessageStreamProvider = StreamProvider<ChatMessageModel>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.messageStream;
});

/// StreamProvider for active typing status map
final typingUsersStreamProvider = StreamProvider<Map<String, bool>>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.typingStream;
});

/// StreamProvider for online presence user IDs
final onlinePresenceStreamProvider = StreamProvider<Set<String>>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.onlineUsersStream;
});
