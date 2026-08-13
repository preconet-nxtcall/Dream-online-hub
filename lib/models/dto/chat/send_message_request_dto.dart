class SendMessageRequestDto {
  final String? conversationId;
  final String recipientId;
  final String type; // 'text', 'voice', 'image'
  final String? text;
  final String? imageKey;
  final String? imageMimeType;
  final String? audioKey;
  final int? audioDuration;
  final String? audioMimeType;
  final String? replyToMessage;

  const SendMessageRequestDto({
    this.conversationId,
    required this.recipientId,
    this.type = 'text',
    this.text,
    this.imageKey,
    this.imageMimeType = 'image/png',
    this.audioKey,
    this.audioDuration,
    this.audioMimeType = 'audio/webm',
    this.replyToMessage,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      if (conversationId != null && conversationId!.isNotEmpty)
        'conversationId': conversationId,
      'recipientId': recipientId,
      'type': type,
    };

    if (type == 'voice' && audioKey != null && audioKey!.isNotEmpty) {
      json['audio'] = {
        'key': audioKey,
        'duration': audioDuration ?? 0,
        'mimeType': audioMimeType ?? 'audio/webm',
      };
    } else if (type == 'image' && imageKey != null && imageKey!.isNotEmpty) {
      json['image'] = {
        'key': imageKey,
        'mimeType': imageMimeType ?? 'image/png',
      };
    } else {
      json['text'] = text ?? '';
    }

    if (replyToMessage != null && replyToMessage!.isNotEmpty) {
      json['reply_to'] = replyToMessage;
    }

    return json;
  }
}

