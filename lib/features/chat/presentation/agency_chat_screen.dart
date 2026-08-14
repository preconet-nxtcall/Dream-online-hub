import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../models/agency/agency_user_item_model.dart';
import '../../../providers/agency_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../socket/socket_service.dart';
import '../../../storage/local_storage_repository.dart';
import '../../../storage/secure_storage_service.dart';
import 'widgets/attachment_sheet_widget.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_message_skeleton.dart';
import 'widgets/date_separator_widget.dart';
import 'widgets/typing_indicator_widget.dart';
import 'widgets/voice_recorder_widget.dart';
import '../../user_dashboard/presentation/widgets/recharge_records_widget.dart';

/// Specialized Luxury Deep Midnight Chat Screen for AGENCY APP (Agency Portal chatting with Assigned Client)
class AgencyChatScreen extends StatefulWidget {
  final String userId;
  final AgencyUserItem? userItem;
  final String? initialGameName;

  const AgencyChatScreen({
    super.key,
    required this.userId,
    this.userItem,
    this.initialGameName,
  });

  @override
  State<AgencyChatScreen> createState() => _AgencyChatScreenState();
}

class _AgencyChatScreenState extends State<AgencyChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _sendBtnController;
  bool _hasText = false;
  StreamSubscription<Set<String>>? _onlineSub;
  bool _lastOnlineStatus = false;
  bool _showScrollToBottomBtn = false;

  @override
  void initState() {
    super.initState();
    _sendBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().clearActiveConversation();
      }
    });

    _onlineSub = SocketService.instance.onlineUsersStream.listen((onlineSet) {
      if (!mounted) return;
      final activeRecipient = context.read<ChatProvider>().activeRecipientId ?? widget.userId;
      final isOnlineNow = onlineSet.contains(activeRecipient);
      if (isOnlineNow != _lastOnlineStatus) {
        _lastOnlineStatus = isOnlineNow;
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final secureStorage = SecureStorageService();
      final chatEmailId = await secureStorage.read(StorageKeys.chatEmailId) ?? '';
      final chatAgentId = await secureStorage.read(StorageKeys.chatAgentId) ?? chatEmailId;
      final currentUser = LocalStorageRepositoryImpl().getUser();

      final rawAgent = (chatAgentId.isNotEmpty && chatAgentId != chatEmailId)
          ? chatAgentId
          : (currentUser?.agencyId ?? (currentUser?.id ?? ''));

      final effectiveAgentId = (rawAgent.startsWith('AGENCY-') || rawAgent.toUpperCase().contains('ADMIN') || rawAgent.contains('@'))
          ? rawAgent
          : (rawAgent.isNotEmpty ? 'AGENCY-$rawAgent' : 'AGENCY-23');

      if (!mounted) return;
      AgencyUserItem? resolvedUser = widget.userItem;
      if (resolvedUser == null || resolvedUser.email.isEmpty) {
        final agencyUsers = context.read<AgencyProvider>().users;
        for (final u in agencyUsers) {
          if (u.id == widget.userId || (widget.userId.contains('@') && u.email.toLowerCase() == widget.userId.toLowerCase())) {
            resolvedUser = u;
            break;
          }
        }
      }
      if (resolvedUser == null || resolvedUser.email.isEmpty) {
        final cachedUsers = LocalStorageRepositoryImpl().getCachedRecentChats();
        for (final u in cachedUsers) {
          if (u.id == widget.userId || (widget.userId.contains('@') && u.email.toLowerCase() == widget.userId.toLowerCase())) {
            resolvedUser = u;
            break;
          }
        }
      }

      String targetUserId = (resolvedUser?.email.isNotEmpty == true && resolvedUser!.email.contains('@'))
          ? resolvedUser.email.trim().toLowerCase()
          : ((widget.userId.isNotEmpty && widget.userId.contains('@'))
              ? widget.userId.trim().toLowerCase()
              : ((resolvedUser?.id != null && resolvedUser!.id.isNotEmpty)
                  ? resolvedUser.id
                  : widget.userId));

      if (mounted) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.resetHigherAuthority();
        chatProvider.fetchConversations();
      }

      final conversationId = ApiEndpoints.buildConversationId(effectiveAgentId, targetUserId);
      final recipientId = targetUserId;

      if (!mounted) return;
      final chatProv = context.read<ChatProvider>();
      await chatProv.fetchMessages(
            conversationId,
            recipientId: recipientId,
            limit: 20,
          );
      if (!mounted) return;
      _scrollToBottom(immediate: true);
    });
  }

  @override
  void dispose() {
    _onlineSub?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendBtnController.forward();
      } else {
        _sendBtnController.reverse();
      }
    }
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ChatProvider>();
      if (provider.hasMoreMessages && !provider.isLoadingMore) {
        provider.loadMoreMessages();
      }
    }

    final showBtn = _scrollController.offset > 250;
    if (showBtn != _showScrollToBottomBtn) {
      setState(() => _showScrollToBottomBtn = showBtn);
    }
  }

  void _scrollToBottom({bool immediate = false}) {
    if (!_scrollController.hasClients) return;
    if (immediate) {
      _scrollController.jumpTo(0.0);
    } else {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _sendMessage({String type = 'text', String? imageUrl, String? voiceDuration}) async {
    final chatProvider = context.read<ChatProvider>();
    final text = _messageController.text.trim();
    final stagedPath = chatProvider.stagedImagePath;

    if (text.isEmpty && imageUrl == null && voiceDuration == null && stagedPath == null) {
      return;
    }

    final sendToId = chatProvider.activeRecipientId ?? widget.userId;
    _messageController.clear();
    await chatProvider.sendMessage(
      sendToId,
      text,
      type: stagedPath != null ? 'image' : type,
      imageUrl: imageUrl ?? stagedPath,
      voiceDuration: voiceDuration,
      isAgencyAdmin: true,
    );
    _scrollToBottom();
  }

  void _handleAttachmentSelected(String type) async {
    if (type == 'camera' || type == 'gallery') {
      final picker = ImagePicker();
      final source = type == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final image = await picker.pickImage(source: source, imageQuality: 75);
      if (image != null && mounted) {
        _sendMessage(type: 'image', imageUrl: image.path);
      }
    } else if (type == 'recharge' || type == 'withdraw') {
      _showClientDetailModal();
    }
  }

  void _showClientDetailModal() {
    final clientName = widget.userItem?.name ?? 'Assigned Client';
    final clientEmail = widget.userItem?.email ?? widget.userId;
    final clientId = widget.userItem?.id ?? widget.userId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF10142D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(clientName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            Text(clientEmail, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 16),
            RechargeRecordsWidget(userId: clientId),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final agencyProvider = context.watch<AgencyProvider>();

    String clientName = widget.userItem?.name ?? '';
    if (clientName.isEmpty || clientName == 'Agency Client') {
      for (final u in agencyProvider.users) {
        if (u.id == widget.userId || (widget.userId.contains('@') && u.email.toLowerCase() == widget.userId.toLowerCase())) {
          clientName = u.name;
          break;
        }
      }
    }
    if (clientName.isEmpty || clientName == 'Agency Client') {
      final cached = LocalStorageRepositoryImpl().getCachedRecentChats();
      for (final u in cached) {
        if (u.id == widget.userId || (widget.userId.contains('@') && u.email.toLowerCase() == widget.userId.toLowerCase())) {
          clientName = u.name;
          break;
        }
      }
    }
    if (clientName.isEmpty) {
      clientName = widget.userId.contains('@') ? widget.userId : 'Client #${widget.userId}';
    }

    final initialLetter = clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildAgencyAppBar(context, clientName, initialLetter),
      body: SafeArea(
        child: Column(
          children: [
            if (chatProvider.errorMessage != null)
              Container(
                width: double.infinity,
                color: Colors.red.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatProvider.errorMessage!,
                        style: const TextStyle(color: Colors.black87, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: (chatProvider.isLoading && chatProvider.messages.isEmpty)
                  ? const ChatMessageSkeletonWidget()
                  : (chatProvider.errorMessage != null && chatProvider.messages.isEmpty)
                      ? _buildAgencyErrorState(context, chatProvider, widget.userId)
                      : chatProvider.messages.isEmpty
                          ? _buildEmptyAgencyState(clientName)
                          : Stack(
                              children: [
                                RefreshIndicator(
                                  color: const Color(0xFF075E54),
                                  onRefresh: () async {
                                    final targetId = chatProvider.activeConversationId ?? widget.userId;
                                    await chatProvider.fetchMessages(
                                      targetId,
                                      recipientId: chatProvider.activeRecipientId,
                                    );
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    reverse: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    itemCount: chatProvider.messages.length +
                                        (chatProvider.isLoadingMore || chatProvider.loadMoreError ? 1 : 0),
                                    findChildIndexCallback: (Key key) {
                                      if (key is ValueKey<String>) {
                                        final id = key.value.replaceFirst('msg_', '');
                                        final idx = chatProvider.messages.indexWhere((m) => m.id == id);
                                        if (idx != -1) {
                                          return chatProvider.messages.length - 1 - idx;
                                        }
                                        return null;
                                      }
                                      return null;
                                    },
                                    itemBuilder: (context, index) {
                                      if (index == chatProvider.messages.length) {
                                        if (chatProvider.loadMoreError) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: () => chatProvider.loadMoreMessages(),
                                                icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF075E54)),
                                                label: const Text(
                                                  'Failed to load older messages. Tap to retry',
                                                  style: TextStyle(fontSize: 12, color: Color(0xFF075E54), fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        if (chatProvider.isLoadingMore) {
                                          return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(10.0),
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF075E54),
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF075E54).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: const Color(0xFF075E54).withValues(alpha: 0.2)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.arrow_upward_rounded, size: 13, color: Color(0xFF075E54)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Scroll up for older history',
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF075E54)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      final displayIndex = chatProvider.messages.length - 1 - index;
                                      final msg = chatProvider.messages[displayIndex];
                                      final showDate = displayIndex == 0 ||
                                          !_isSameDay(msg.timestamp, chatProvider.messages[displayIndex - 1].timestamp);

                                      return Column(
                                        key: ValueKey('msg_${msg.id}'),
                                        children: [
                                          if (showDate) DateSeparatorWidget(date: msg.timestamp),
                                          ChatMessageBubble(
                                            message: msg,
                                            accentColor: const Color(0xFF075E54),
                                            onReply: () => chatProvider.setReplyingTo(msg),
                                            onDelete: () => chatProvider.deleteMessage(msg.id),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),

                                // Floating WhatsApp-style Scroll-to-Bottom button
                                if (_showScrollToBottomBtn)
                                  Positioned(
                                    right: 16,
                                    bottom: 16,
                                    child: GestureDetector(
                                      onTap: () => _scrollToBottom(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF075E54),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Scroll Down',
                                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
            ),

            if (chatProvider.isAgencyTyping)
              TypingIndicatorWidget(
                agencyName: clientName,
                accentColor: const Color(0xFF075E54),
              ),

            _buildAgencyInputField(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAgencyAppBar(BuildContext context, String clientName, String initialLetter) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(66),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2C34),
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF00A884),
              width: 1.2,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
                GestureDetector(
                  onTap: _showClientDetailModal,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00A884), Color(0xFF059669)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initialLetter,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _showClientDetailModal,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00A884),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Assigned Client Portal',
                              style: TextStyle(color: Color(0xFF8696A0), fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF00A884), size: 22),
                  onPressed: _showClientDetailModal,
                  tooltip: 'Client Info',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgencyInputField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F2F5),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF075E54), size: 24),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => AttachmentSheetWidget(
                    onAttachmentSelected: (type, _) => _handleAttachmentSelected(type),
                  ),
                );
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Color(0xFF111B21), fontSize: 14.5),
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Type response to client...',
                    hintStyle: TextStyle(color: Color(0xFF667781), fontSize: 13.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (_hasText)
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF075E54),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: () => _sendMessage(),
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF075E54),
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: VoiceRecorderWidget(
                          onSend: (path, dur) {
                            Navigator.pop(ctx);
                            final provider = context.read<ChatProvider>();
                            final sendToId = provider.activeRecipientId ?? widget.userId;
                            provider.sendVoiceMessage(sendToId, path, dur);
                            _scrollToBottom();
                          },
                          onCancel: () => Navigator.pop(ctx),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyErrorState(BuildContext context, ChatProvider chatProvider, String clientId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Chat',
              style: TextStyle(color: Color(0xFF111B21), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              chatProvider.errorMessage ?? 'Connection issue occurred while fetching messages.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667781), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                final targetId = chatProvider.activeConversationId ?? clientId;
                chatProvider.fetchMessages(targetId, recipientId: clientId);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075E54),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAgencyState(String clientName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF075E54).withValues(alpha: 0.12),
                border: Border.all(color: const Color(0xFF075E54).withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(Icons.forum_outlined, color: Color(0xFF075E54), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat with $clientName',
              style: const TextStyle(color: Color(0xFF111B21), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Send a message to fulfill client requests, answer questions, or provide support.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF667781), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}
