import '../../chat/chat_message_model.dart';

class ChatMessageDto {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final String timestamp;
  final String status;
  final String type;
  final String? imageUrl;
  final String? voiceDuration;
  final String? replyToMessage;

  const ChatMessageDto({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.status,
    required this.type,
    this.imageUrl,
    this.voiceDuration,
    this.replyToMessage,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: (json['id'] ?? json['_id'] ?? json['message_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? json['senderId'] ?? '').toString(),
      receiverId: (json['receiver_id'] ?? json['receiverId'] ?? '').toString(),
      message: (json['message'] ?? json['text'] ?? '').toString(),
      timestamp: (json['timestamp'] ?? json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      status: (json['status'] ?? 'delivered').toString(),
      type: (json['type'] ?? 'text').toString(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      voiceDuration: json['voice_duration'] ?? json['voiceDuration'],
      replyToMessage: json['reply_to'] ?? json['replyToMessage'],
    );
  }

  ChatMessageModel toDomainModel({required String currentUserId}) {
    DateTime parsedDate;
    final parsed = DateTime.tryParse(timestamp);
    if (parsed != null) {
      parsedDate = parsed;
    } else {
      final intDate = int.tryParse(timestamp);
      parsedDate = intDate != null
          ? DateTime.fromMillisecondsSinceEpoch(intDate)
          : DateTime.now();
    }

    return ChatMessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: parsedDate,
      isMe: senderId == currentUserId || senderId == 'me',
      status: status,
      type: type,
      imageUrl: imageUrl,
      voiceDuration: voiceDuration,
      replyToMessage: replyToMessage,
      fileSize: type == 'image' ? '1.8 MB' : (type == 'voice' ? '420 KB' : null),
      isDownloaded: !imageUrl.toString().startsWith('http_pending'),
    );
  }
}
