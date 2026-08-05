import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat/chat_message_model.dart';
import '../repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isAgencyTyping = false;
  String? _errorMessage;
  Map<String, dynamic>? _assignedAgency;
  ChatMessageModel? _replyingToMessage;
  bool _isHigherAuthorityActive = false;

  // Voice Recording state
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Image Staging state
  String? _stagedImagePath;
  String? _stagedImageCaption;

  ChatProvider({ChatRepository? chatRepository})
      : _chatRepository = chatRepository ?? ChatRepositoryImpl();

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isAgencyTyping => _isAgencyTyping;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get assignedAgency => _assignedAgency;
  ChatMessageModel? get replyingToMessage => _replyingToMessage;
  bool get isHigherAuthorityActive => _isHigherAuthorityActive;

  bool get isRecording => _isRecording;
  int get recordingSeconds => _recordingSeconds;
  String? get stagedImagePath => _stagedImagePath;
  String? get stagedImageCaption => _stagedImageCaption;

  /// Toggle conversation source between Agency and Admin Higher Authority
  Future<void> toggleHigherAuthority(String defaultUserId) async {
    _isHigherAuthorityActive = !_isHigherAuthorityActive;
    final targetId = _isHigherAuthorityActive ? 'admin_higher_authority' : defaultUserId;
    await fetchMessages(targetId);
  }

  void setReplyingTo(ChatMessageModel? message) {
    _replyingToMessage = message;
    notifyListeners();
  }

  void cancelReply() {
    _replyingToMessage = null;
    notifyListeners();
  }

  // Voice Recording Methods
  void startRecording() {
    _isRecording = true;
    _recordingSeconds = 0;
    notifyListeners();

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingSeconds++;
      notifyListeners();
    });
  }

  String formatRecordingDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void stopRecordingAndSend(String userId, {bool isAgencyAdmin = false}) {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    final durationStr = formatRecordingDuration(_recordingSeconds);
    _isRecording = false;
    _recordingSeconds = 0;
    notifyListeners();

    sendMessage(
      userId,
      '',
      type: 'voice',
      voiceDuration: durationStr.length == 5 ? durationStr.substring(1) : durationStr,
      isAgencyAdmin: isAgencyAdmin,
    );
  }

  void cancelRecording() {
    _recordingTimer?.cancel();
    _isRecording = false;
    _recordingSeconds = 0;
    notifyListeners();
  }

  // Image Staging Methods
  void setStagedImage(String path, {String? caption}) {
    _stagedImagePath = path;
    _stagedImageCaption = caption;
    notifyListeners();
  }

  void clearStagedImage() {
    _stagedImagePath = null;
    _stagedImageCaption = null;
    notifyListeners();
  }

  /// Auto fetch user's assigned agency profile
  Future<Map<String, dynamic>> fetchAssignedAgency() async {
    try {
      _assignedAgency = await _chatRepository.fetchAssignedAgency();
      notifyListeners();
      return _assignedAgency!;
    } catch (_) {
      return {
        'id': 'agency_support_1',
        'name': 'Apex Premier Agency Support',
        'is_online': true,
      };
    }
  }

  Future<void> fetchMessages(String userId) async {
    _isLoading = true;
    _messages = [];
    _replyingToMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_assignedAgency == null) {
        await fetchAssignedAgency();
      }
      _messages = await _chatRepository.fetchMessages(userId);
    } catch (e) {
      _errorMessage = 'Failed to load conversation history.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(
    String userId,
    String text, {
    String type = 'text',
    String? imageUrl,
    String? voiceDuration,
    bool isAgencyAdmin = false,
  }) async {
    if (text.trim().isEmpty && imageUrl == null && voiceDuration == null && _stagedImagePath == null) {
      return false;
    }

    final finalImageUrl = imageUrl ?? _stagedImagePath;
    final finalMessage = text.isNotEmpty
        ? text.trim()
        : (_stagedImageCaption ??
            (finalImageUrl != null
                ? '📷 Image Attachment'
                : (voiceDuration != null ? '🎤 Voice Note ($voiceDuration)' : '')));

    final String? replyText = _replyingToMessage?.message;
    final String actualType = _replyingToMessage != null ? 'reply' : type;

    clearStagedImage();

    final isMedia = actualType == 'image' || actualType == 'voice' || finalImageUrl != null || voiceDuration != null;
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();

    final tempMsg = ChatMessageModel(
      id: msgId,
      senderId: 'me',
      receiverId: userId,
      message: finalMessage,
      timestamp: DateTime.now(),
      isMe: true,
      status: isMedia ? 'uploading' : 'sending',
      type: actualType == 'reply' ? (finalImageUrl != null ? 'image' : (voiceDuration != null ? 'voice' : 'text')) : actualType,
      imageUrl: finalImageUrl,
      voiceDuration: voiceDuration,
      replyToMessage: replyText,
      fileSize: finalImageUrl != null ? '2.4 MB' : (voiceDuration != null ? '350 KB' : null),
      uploadProgress: isMedia ? 0.05 : null,
      isDownloaded: true,
    );

    _messages.add(tempMsg);
    _isSending = true;
    _replyingToMessage = null;
    notifyListeners();

    // Stream upload progress simulation if media
    if (isMedia) {
      _simulateUploadProgress(msgId);
    }

    try {
      final sentMsg = await _chatRepository.sendMessage(
        userId: userId,
        message: tempMsg.message,
        type: tempMsg.type,
        imageUrl: finalImageUrl,
        voiceDuration: voiceDuration,
        replyToMessage: replyText,
      );

      final index = _messages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        _messages[index] = sentMsg.copyWith(
          status: 'seen',
          uploadProgress: 1.0,
          fileSize: tempMsg.fileSize,
        );
      }

      if (!isAgencyAdmin && !_isHigherAuthorityActive) {
        _triggerAgencyTypingSimulation(userId);
      }

      return true;
    } catch (e) {
      final index = _messages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(status: 'sent', uploadProgress: 1.0);
      }
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void _simulateUploadProgress(String messageId) {
    double progress = 0.1;
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      progress += 0.25;
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index == -1 || progress >= 1.0) {
        timer.cancel();
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(uploadProgress: 1.0, status: 'sent');
          notifyListeners();
        }
      } else {
        _messages[index] = _messages[index].copyWith(uploadProgress: progress);
        notifyListeners();
      }
    });
  }

  void simulateMediaDownload(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    _messages[index] = _messages[index].copyWith(downloadProgress: 0.1, isDownloaded: false);
    notifyListeners();

    double progress = 0.1;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      progress += 0.3;
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx == -1 || progress >= 1.0) {
        timer.cancel();
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(downloadProgress: 1.0, isDownloaded: true);
          notifyListeners();
        }
      } else {
        _messages[idx] = _messages[idx].copyWith(downloadProgress: progress);
        notifyListeners();
      }
    });
  }

  void deleteMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  void addRealtimeMessage(ChatMessageModel message) {
    final exists = _messages.any((m) => m.id == message.id);
    if (!exists) {
      _messages.add(message);
      notifyListeners();
    }
  }

  void _triggerAgencyTypingSimulation(String userId) {
    Future.delayed(const Duration(seconds: 1), () {
      if (!hasListeners) return;
      _isAgencyTyping = true;
      notifyListeners();
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!hasListeners) return;
      _isAgencyTyping = false;
      _messages.add(
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: userId,
          receiverId: 'me',
          message: 'Thank you for contacting agency support! Your request has been acknowledged by our team.',
          timestamp: DateTime.now(),
          isMe: false,
          status: 'delivered',
        ),
      );
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}
