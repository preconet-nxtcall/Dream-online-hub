class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isMe;
  final String status; // 'sent', 'delivered', 'seen', 'uploading'
  final String type; // 'text', 'image', 'voice', 'reply', 'document'
  final String? imageUrl;
  final String? voiceDuration; // e.g. '0:15'
  final String? replyToMessage; // quoted text
  final String? fileSize; // e.g. '1.4 MB'
  final double? uploadProgress; // 0.0 to 1.0
  final double? downloadProgress; // 0.0 to 1.0
  final bool isDownloaded;
  final String? localFilePath;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.isMe,
    this.status = 'sent',
    this.type = 'text',
    this.imageUrl,
    this.voiceDuration,
    this.replyToMessage,
    this.fileSize,
    this.uploadProgress,
    this.downloadProgress,
    this.isDownloaded = true,
    this.localFilePath,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final sender = (json['sender_id'] ?? json['senderId'] ?? json['from'] ?? '').toString();
    DateTime parsedTime = DateTime.now();

    if (json['timestamp'] != null || json['created_at'] != null) {
      final t = json['timestamp'] ?? json['created_at'];
      if (t is String) {
        parsedTime = DateTime.tryParse(t) ?? DateTime.now();
      } else if (t is int) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(t);
      }
    }

    return ChatMessageModel(
      id: (json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      senderId: sender,
      receiverId: (json['receiver_id'] ?? json['receiverId'] ?? json['to'] ?? '').toString(),
      message: (json['message'] ?? json['text'] ?? json['content'] ?? '').toString(),
      timestamp: parsedTime,
      isMe: json['is_me'] ?? (currentUserId != null && sender == currentUserId),
      status: (json['status'] ?? 'sent').toString(),
      type: (json['type'] ?? 'text').toString(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      voiceDuration: json['voice_duration'] ?? json['voiceDuration'],
      replyToMessage: json['reply_to'] ?? json['replyToMessage'],
      fileSize: json['file_size'] ?? json['fileSize'],
      uploadProgress: (json['upload_progress'] ?? json['uploadProgress'])?.toDouble(),
      downloadProgress: (json['download_progress'] ?? json['downloadProgress'])?.toDouble(),
      isDownloaded: json['is_downloaded'] ?? json['isDownloaded'] ?? true,
      localFilePath: json['local_file_path'] ?? json['localFilePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_me': isMe,
      'status': status,
      'type': type,
      if (imageUrl != null) 'image_url': imageUrl,
      if (voiceDuration != null) 'voice_duration': voiceDuration,
      if (replyToMessage != null) 'reply_to': replyToMessage,
      if (fileSize != null) 'file_size': fileSize,
      if (uploadProgress != null) 'upload_progress': uploadProgress,
      if (downloadProgress != null) 'download_progress': downloadProgress,
      'is_downloaded': isDownloaded,
      if (localFilePath != null) 'local_file_path': localFilePath,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    DateTime? timestamp,
    bool? isMe,
    String? status,
    String? type,
    String? imageUrl,
    String? voiceDuration,
    String? replyToMessage,
    String? fileSize,
    double? uploadProgress,
    double? downloadProgress,
    bool? isDownloaded,
    String? localFilePath,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      status: status ?? this.status,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      fileSize: fileSize ?? this.fileSize,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}
