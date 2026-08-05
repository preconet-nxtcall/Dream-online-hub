class SendMessageRequestDto {
  final String receiverId;
  final String message;
  final String type;
  final String? imageUrl;
  final String? voiceDuration;
  final String? replyToMessage;

  const SendMessageRequestDto({
    required this.receiverId,
    required this.message,
    this.type = 'text',
    this.imageUrl,
    this.voiceDuration,
    this.replyToMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiver_id': receiverId,
      'message': message,
      'type': type,
      if (imageUrl != null) 'image_url': imageUrl,
      if (voiceDuration != null) 'voice_duration': voiceDuration,
      if (replyToMessage != null) 'reply_to': replyToMessage,
    };
  }
}
