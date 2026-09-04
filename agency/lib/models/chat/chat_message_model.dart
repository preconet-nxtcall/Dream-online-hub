import '../../utils/date_formatter.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isMe;
  final String status; // 'sending' | 'uploading' | 'queued' | 'sent' | 'delivered' | 'read' | 'failed'
  final String type; // 'text', 'image', 'voice', 'reply', 'document'
  final String? imageUrl;
  final String? audioUrl;
  final String? voiceDuration; // e.g. '0:15'
  final String? replyToMessage; // quoted text
  final String? fileSize; // e.g. '1.4 MB'
  final double? uploadProgress; // 0.0 to 1.0
  final double? downloadProgress; // 0.0 to 1.0
  final bool isDownloaded;
  final String? localFilePath;
  final String conversationId;

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
    this.audioUrl,
    this.voiceDuration,
    this.replyToMessage,
    this.fileSize,
    this.uploadProgress,
    this.downloadProgress,
    this.isDownloaded = true,
    this.localFilePath,
    this.conversationId = '',
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, {
    String? currentUserId,
    Set<String>? userKeys,
    String userRole = 'user',
  }) {
    dynamic rawSender = json['sender_id'] ??
        json['senderId'] ??
        json['sender'] ??
        json['from'] ??
        json['user_id'] ??
        json['userId'] ??
        json['agency_id'] ??
        json['agencyId'] ??
        json['emailId'] ??
        json['email'];

    String sender = '';
    String? senderType = (json['senderType'] ?? json['sender_type'] ?? json['role'] ?? json['type'])?.toString();

    if (rawSender is Map) {
      final senderMap = rawSender as Map<String, dynamic>;
      sender = (senderMap['emailId'] ??
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
      sender = rawSender.toString();
    }

    final t = json['timestamp'] ?? json['created_at'] ?? json['createdAt'];
    final parsedTime = DateFormatter.parseToLocal(t);

    final s = sender.trim().toLowerCase();
    final st = (senderType ?? '').trim().toLowerCase();
    final roleLower = userRole.trim().toLowerCase();

    final keys = (userKeys ?? {}).map((e) => e.trim().toLowerCase()).toSet();
    if (currentUserId != null &&
        currentUserId.trim().isNotEmpty &&
        !currentUserId.toLowerCase().contains('admin')) {
      keys.add(currentUserId.trim().toLowerCase());
    }
    keys.add('me');
    keys.remove('admin-1');
    keys.remove('admin@gmail.com');
    keys.remove('admin');

    final isAdminSender = s == 'admin-1' ||
        s == 'admin@gmail.com' ||
        s == 'admin' ||
        st == 'admin';

    bool isMe = false;
    if (isAdminSender) {
      isMe = roleLower == 'admin';
    } else if (json['is_me'] is bool) {
      isMe = json['is_me'] as bool;
    } else if (json['isMe'] is bool) {
      isMe = json['isMe'] as bool;
    } else if (s.isNotEmpty && keys.contains(s)) {
      isMe = true;
    } else if (st.isNotEmpty) {
      if (roleLower == 'agency' || roleLower == 'agent') {
        if (st == 'agency' || st == 'agent') {
          isMe = true;
        } else {
          isMe = false;
        }
      } else if (roleLower == 'admin') {
        isMe = st == 'admin';
      } else {
        isMe = st == 'user' || st == 'client';
      }
    }

    return ChatMessageModel(
      id: (json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      senderId: sender,
      receiverId: (json['receiver_id'] ?? json['receiverId'] ?? json['to'] ?? '').toString(),
      message: (json['message'] ?? json['text'] ?? json['content'] ?? '').toString(),
      timestamp: parsedTime ?? DateTime.now(),
      isMe: isMe,
      status: (json['status'] ?? 'sent').toString(),
      type: (json['type'] ?? 'text').toString(),
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? json['photo_url'] ?? json['photoUrl'],
      audioUrl: json['audio_url'] ??
          json['audioUrl'] ??
          json['audio'] ??
          json['voice_url'] ??
          json['voiceUrl'] ??
          json['file_url'] ??
          json['fileUrl'] ??
          json['media_url'] ??
          json['mediaUrl'] ??
          json['url'] ??
          ((json['type'] == 'voice' || json['type'] == 'audio')
              ? (json['image_url'] ?? json['imageUrl'] ?? json['url'])
              : null),
      voiceDuration: json['voice_duration'] ?? json['voiceDuration'],
      replyToMessage: json['reply_to'] ?? json['replyToMessage'],
      fileSize: json['file_size'] ?? json['fileSize'],
      uploadProgress: (json['upload_progress'] ?? json['uploadProgress'])?.toDouble(),
      downloadProgress: (json['download_progress'] ?? json['downloadProgress'])?.toDouble(),
      isDownloaded: json['is_downloaded'] ?? json['isDownloaded'] ?? true,
      localFilePath: json['local_file_path'] ?? json['localFilePath'],
      conversationId: (json['conversationId'] ?? json['conversation_id'] ?? '').toString(),
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
      if (audioUrl != null) 'audio_url': audioUrl,
      if (voiceDuration != null) 'voice_duration': voiceDuration,
      if (replyToMessage != null) 'reply_to': replyToMessage,
      if (fileSize != null) 'file_size': fileSize,
      if (uploadProgress != null) 'upload_progress': uploadProgress,
      if (downloadProgress != null) 'download_progress': downloadProgress,
      'is_downloaded': isDownloaded,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (conversationId.isNotEmpty) 'conversationId': conversationId,
    };
  }

  /// Sentinel object used to explicitly pass `null` to copyWith for nullable fields.
  // ignore: library_private_types_in_public_api
  static const _nullSentinel = Object();

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
    String? audioUrl,
    String? voiceDuration,
    String? replyToMessage,
    String? fileSize,
    Object? uploadProgress = _nullSentinel,
    Object? downloadProgress = _nullSentinel,
    bool? isDownloaded,
    String? localFilePath,
    String? conversationId,
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
      audioUrl: audioUrl ?? this.audioUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      fileSize: fileSize ?? this.fileSize,
      // Allow explicit null-clearing using sentinel
      uploadProgress: identical(uploadProgress, _nullSentinel)
          ? this.uploadProgress
          : uploadProgress as double?,
      downloadProgress: identical(downloadProgress, _nullSentinel)
          ? this.downloadProgress
          : downloadProgress as double?,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localFilePath: localFilePath ?? this.localFilePath,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}
