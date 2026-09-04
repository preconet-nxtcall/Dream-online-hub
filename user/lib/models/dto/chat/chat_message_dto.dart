import '../../../core/constants/api_endpoints.dart';
import '../../../utils/date_formatter.dart';
import '../../chat/chat_message_model.dart';

class ChatMessageDto {
  final String id;
  final String senderId;
  final String? senderType;
  final String receiverId;
  final String message;
  final String timestamp;
  final String status;
  final String type;
  final String? imageUrl;
  final String? audioUrl;
  final String? voiceDuration;
  final String? replyToMessage;
  final bool? isMeExplicit;

  const ChatMessageDto({
    required this.id,
    required this.senderId,
    this.senderType,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.status,
    required this.type,
    this.imageUrl,
    this.audioUrl,
    this.voiceDuration,
    this.replyToMessage,
    this.isMeExplicit,
  });

  static String _resolveUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final url = rawUrl.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/uploads/') || url.startsWith('uploads/')) {
      final path = url.startsWith('/') ? url : '/$url';
      return '${ApiEndpoints.chatBaseUrl}$path';
    }
    // If it is an S3 fileKey (e.g. voice-notes/..., images/...), preserve raw key
    // so play-url endpoint can request dynamic signed URL.
    return url;
  }

  /// Parse a message from the real Node.js chat server response.
  /// [chatEmailId] is the currently logged-in user's emailId on the chat server.
  factory ChatMessageDto.fromJson(
    Map<String, dynamic> json, {
    String chatEmailId = '',
  }) {
    // ── Image CDN URL ──────────────────────────────────────────────────────
    String? imageUrl;
    if (json['image'] is Map) {
      final img = json['image'] as Map<String, dynamic>;
      final raw = img['cdnUrl']?.toString() ?? img['key']?.toString();
      if (raw != null && raw.isNotEmpty) imageUrl = _resolveUrl(raw);
    } else if (json['image_url'] != null || json['imageUrl'] != null) {
      final raw = (json['image_url'] ?? json['imageUrl']).toString();
      if (raw.isNotEmpty) imageUrl = _resolveUrl(raw);
    }

    // ── Voice duration & Audio URL ─────────────────────────────────────────────
    String? voiceDuration;
    String? audioUrl;
    if (json['audio'] is Map) {
      final audio = json['audio'] as Map<String, dynamic>;
      final dur = audio['duration'];
      if (dur != null) {
        final seconds = int.tryParse(dur.toString()) ?? 0;
        final mins = (seconds ~/ 60).toString().padLeft(2, '0');
        final secs = (seconds % 60).toString().padLeft(2, '0');
        voiceDuration = '$mins:$secs';
      }
      final rawAudio = audio['cdnUrl']?.toString() ?? audio['key']?.toString() ?? audio['url']?.toString();
      if (rawAudio != null && rawAudio.isNotEmpty) {
        audioUrl = _resolveUrl(rawAudio);
      }
    } else {
      voiceDuration =
          json['voice_duration']?.toString() ?? json['voiceDuration']?.toString();
      final rawAudio = json['audio_url']?.toString() ?? json['audioUrl']?.toString();
      if (rawAudio != null && rawAudio.isNotEmpty) {
        audioUrl = _resolveUrl(rawAudio);
      }
    }

    // Extract senderId safely whether it is String, Map, or number
    dynamic rawSender = json['senderId'] ??
        json['sender_id'] ??
        json['sender'] ??
        json['from'] ??
        json['user_id'] ??
        json['userId'] ??
        json['agency_id'] ??
        json['agencyId'] ??
        json['emailId'] ??
        json['email'];
    String senderId = '';
    String? senderType = (json['senderType'] ?? json['sender_type'] ?? json['role'] ?? json['type'])?.toString();

    if (rawSender is Map) {
      final senderMap = rawSender as Map<String, dynamic>;
      senderId = (senderMap['emailId'] ??
              senderMap['_id'] ??
              senderMap['email'] ??
              senderMap['id'] ??
              senderMap['userId'] ??
              senderMap['user_id'] ??
              senderMap['agencyId'] ??
              senderMap['agency_id'] ??
              '')
          .toString();
      if (senderType == null || senderType.isEmpty) {
        senderType = (senderMap['role'] ?? senderMap['type'] ?? senderMap['senderType'] ?? senderMap['sender_type'])?.toString();
      }
    } else if (rawSender != null) {
      senderId = rawSender.toString();
    }

    dynamic rawReceiver = json['recipientId'] ?? json['receiverId'] ?? json['receiver_id'] ?? json['to'] ?? json['recipient'];
    String receiverId = '';
    if (rawReceiver is Map) {
      final receiverMap = rawReceiver as Map<String, dynamic>;
      receiverId = (receiverMap['emailId'] ?? receiverMap['_id'] ?? receiverMap['email'] ?? receiverMap['id'] ?? '').toString();
    } else if (rawReceiver != null) {
      receiverId = rawReceiver.toString();
    }

    bool? isMeExplicit;
    if (json['is_me'] is bool) {
      isMeExplicit = json['is_me'] as bool;
    } else if (json['isMe'] is bool) {
      isMeExplicit = json['isMe'] as bool;
    }

    return ChatMessageDto(
      id: (json['_id'] ?? json['id'] ?? json['message_id'] ?? '').toString(),
      senderId: senderId,
      senderType: senderType,
      receiverId: receiverId,
      message: (json['text'] ?? json['message'] ?? '').toString(),
      timestamp: (json['createdAt'] ??
              json['created_at'] ??
              json['timestamp'] ??
              DateTime.now().toIso8601String())
          .toString(),
      status: (json['status'] ?? 'delivered').toString(),
      type: (json['type'] ?? 'text').toString(),
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      voiceDuration: voiceDuration,
      replyToMessage:
          json['reply_to']?.toString() ?? json['replyToMessage']?.toString(),
      isMeExplicit: isMeExplicit,
    );
  }

  /// Convert to domain model.
  /// Determines `isMe` based strictly on the actual sender of the message.
  ChatMessageModel toChatModel({
    String chatEmailId = '',
    String userId = '',
    String agentId = '',
    String userRole = 'user',
    String? activeRecipientId,
    bool? isMeOverride,
  }) {
    final parsedDate = DateFormatter.parseToLocal(timestamp);

    final sId = senderId.trim().toLowerCase();
    final sType = (senderType ?? '').trim().toLowerCase();
    final roleLower = userRole.trim().toLowerCase();

    final isAdminSender = sId == ApiEndpoints.adminAgencyUnqId.toLowerCase() ||
        sId == ApiEndpoints.adminEmailId.toLowerCase() ||
        sId == 'admin' ||
        sType == 'admin';

    bool isMeMsg = false;

    if (isAdminSender) {
      isMeMsg = roleLower == 'admin';
    } else if (isMeOverride != null) {
      isMeMsg = isMeOverride;
    } else if (isMeExplicit != null) {
      isMeMsg = isMeExplicit!;
    } else {
      final recipient = (activeRecipientId ?? '').trim().toLowerCase();

      // Collect all known identifiers for the CURRENT logged-in user of the app
      final userKeys = <String>{
        'me',
        if (chatEmailId.trim().isNotEmpty && !chatEmailId.toLowerCase().contains('admin'))
          chatEmailId.trim().toLowerCase(),
        if (userId.trim().isNotEmpty &&
            userId != ApiEndpoints.adminAgencyUnqId &&
            userId != ApiEndpoints.adminEmailId)
          userId.trim().toLowerCase(),
        if ((roleLower == 'agency' || roleLower == 'agent') &&
            agentId.trim().isNotEmpty &&
            agentId != ApiEndpoints.adminAgencyUnqId &&
            agentId != ApiEndpoints.adminEmailId)
          agentId.trim().toLowerCase(),
      };

      final partnerKeys = <String>{
        if (recipient.isNotEmpty) recipient,
        ApiEndpoints.adminAgencyUnqId.toLowerCase(),
        ApiEndpoints.adminEmailId.toLowerCase(),
        'admin',
      };

      if (sId.isNotEmpty && userKeys.contains(sId)) {
        // Direct match with current logged-in user's identifiers -> MY message (RIGHT)
        isMeMsg = true;
      } else if (sId.isNotEmpty && partnerKeys.contains(sId)) {
        // Direct match with partner / admin / client -> PARTNER message (LEFT)
        isMeMsg = false;
      } else if (sType.isNotEmpty) {
        // Evaluate based on senderType vs current logged-in app role
        if (roleLower == 'agency' || roleLower == 'agent') {
          if (sType == 'agent' || sType == 'agency') {
            isMeMsg = true; // Agency's own message -> RIGHT
          } else {
            isMeMsg = false; // Admin or Client message -> LEFT
          }
        } else if (roleLower == 'admin') {
          isMeMsg = sType == 'admin';
        } else {
          // User / Client app
          isMeMsg = sType == 'user' || sType == 'client';
        }
      } else if (sId.isNotEmpty) {
        // Sender ID exists, doesn't match current user -> PARTNER message (LEFT)
        isMeMsg = false;
      }
    }

    return ChatMessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: parsedDate ?? DateTime.now(),
      isMe: isMeMsg,
      status: status,
      type: type,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      voiceDuration: voiceDuration,
      replyToMessage: replyToMessage,
      fileSize: type == 'image'
          ? '1.8 MB'
          : (type == 'voice' ? '420 KB' : null),
      isDownloaded:
          imageUrl == null || !imageUrl.toString().startsWith('http_pending'),
    );
  }

  /// Helper — passes currentUserId & userRole
  ChatMessageModel toDomainModel({
    String currentUserId = '',
    String? activeUserRole,
  }) {
    return toChatModel(
      chatEmailId: currentUserId,
      userRole: activeUserRole ?? 'user',
    );
  }
}
