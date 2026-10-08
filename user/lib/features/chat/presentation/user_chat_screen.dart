import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../models/agency/agency_user_item_model.dart';
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
import '../../user_dashboard/presentation/widgets/recharge_now_widget.dart';
import '../../user_dashboard/presentation/widgets/withdraw_request_widget.dart';
import '../../../utils/date_formatter.dart';
import '../../../models/user/recharge_record_model.dart';

/// Specialized Luxury Dark Chat Screen for USER APP (User chatting with Assigned Support Agency)
class UserChatScreen extends StatefulWidget {
  final String userId;
  final AgencyUserItem? userItem;
  final String? initialGameName;

  const UserChatScreen({
    super.key,
    required this.userId,
    this.userItem,
    this.initialGameName,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _sendBtnController;
  bool _hasText = false;
  StreamSubscription<Set<String>>? _onlineSub;
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

    if (widget.initialGameName != null && widget.initialGameName!.isNotEmpty) {
      _messageController.text =
          'Hi, I need assistance with ${widget.initialGameName}';
      _hasText = true;
    }

    _onlineSub = SocketService.instance.onlineUsersStream.listen((_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final secureStorage = SecureStorageService();
      final chatEmailId =
          await secureStorage.read(StorageKeys.chatEmailId) ?? '';
      final currentUser = LocalStorageRepositoryImpl().getUser();
      final effectiveEmail =
          chatEmailId.isNotEmpty ? chatEmailId : (currentUser?.email ?? '');

      SocketService.instance.checkUserPresence(ApiEndpoints.adminEmailId);
      SocketService.instance.checkUserPresence(ApiEndpoints.adminAgencyUnqId);

      if (!mounted) return;
      final chatProv = context.read<ChatProvider>();
      await chatProv.fetchConversations();

      if (mounted) {
        await chatProv.setHigherAuthority(
          true,
          ApiEndpoints.adminAgencyUnqId,
          chatEmailId: effectiveEmail,
        );
        if (mounted) {
          _scrollToBottom(immediate: true);
        }
      }
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
    // In a reverse:true ListView, offset 0 = newest messages (bottom),
    // higher offsets = older messages (top). maxScrollExtent is the physical
    // start of the list (oldest messages). Trigger loadMore when near the top.
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      final provider = context.read<ChatProvider>();
      if (provider.hasMoreMessages && !provider.isLoadingMore) {
        provider.loadMoreMessages();
      }
    }

    // Show scroll-to-bottom button when user has scrolled away from latest messages
    final showBtn = _scrollController.offset > 300;
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

  void _sendMessage(
      {String type = 'text', String? imageUrl, String? voiceDuration}) async {
    final chatProvider = context.read<ChatProvider>();
    final text = _messageController.text.trim();
    final stagedPath = chatProvider.stagedImagePath;

    if (text.isEmpty &&
        imageUrl == null &&
        voiceDuration == null &&
        stagedPath == null) {
      return;
    }

    final sendToId =
        chatProvider.activeRecipientId ?? ApiEndpoints.adminAgencyUnqId;
    _messageController.clear();
    await chatProvider.sendMessage(
      sendToId,
      text,
      type: stagedPath != null ? 'image' : type,
      imageUrl: imageUrl ?? stagedPath,
      voiceDuration: voiceDuration,
    );
    _scrollToBottom();
  }

  void _handleAttachmentSelected(String type) async {
    if (type == 'camera' || type == 'gallery') {
      final picker = ImagePicker();
      final source =
          type == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final image = await picker.pickImage(source: source, imageQuality: 75);
      if (image != null && mounted) {
        _sendMessage(type: 'image', imageUrl: image.path);
      }
    } else if (type == 'recharge') {
      _showRechargeModal();
    } else if (type == 'withdraw') {
      _showWithdrawModal();
    }
  }

  void _showRechargeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: RechargeNowWidget(
          onRechargeSubmitted: (RechargeRecordModel record) {
            if (!mounted) return;
            final chatProvider = context.read<ChatProvider>();
            final sendToId =
                chatProvider.activeRecipientId ?? ApiEndpoints.adminAgencyUnqId;
            final rechargeMsg =
                '💰 Recharge Submitted: ₹${record.amount.toStringAsFixed(0)} on ${record.bookName}\nTxn ID: ${record.transactionDetails}';
            chatProvider.sendMessage(
              sendToId,
              rechargeMsg,
              type: 'text',
            );
            _scrollToBottom();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recharge submitted and posted to chat!'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showWithdrawModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: WithdrawRequestWidget(
          onWithdrawSubmitted: (WithdrawRequestModel record) {
            if (!mounted) return;
            final chatProvider = context.read<ChatProvider>();
            final sendToId =
                chatProvider.activeRecipientId ?? ApiEndpoints.adminAgencyUnqId;
            final withdrawMsg =
                '💸 Withdrawal Request: ₹${record.amount.toStringAsFixed(0)} from ${record.bookName}';
            chatProvider.sendMessage(
              sendToId,
              withdrawMsg,
              type: 'text',
            );
            _scrollToBottom();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Withdrawal submitted and posted to chat!'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildDashboardAppBar(context, chatProvider),
      body: SafeArea(
        child: Column(
          children: [
            if (chatProvider.errorMessage != null)
              Container(
                width: double.infinity,
                color: Colors.red.withValues(alpha: 0.15),
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatProvider.errorMessage!,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Action Cards Bar (Recharge & Withdraw)
            _buildQuickActionCardsRow(context),

            Expanded(
              child: (chatProvider.isLoading && chatProvider.messages.isEmpty)
                  ? const ChatMessageSkeletonWidget()
                  : (chatProvider.errorMessage != null &&
                          chatProvider.messages.isEmpty)
                      ? _buildErrorState(context, chatProvider)
                      : chatProvider.messages.isEmpty
                          ? _buildEmptyLightState()
                          : Stack(
                              children: [
                                RefreshIndicator(
                                  color: const Color(0xFF00D2FF),
                                  onRefresh: () async {
                                    final targetId =
                                        chatProvider.activeConversationId ??
                                            widget.userId;
                                    await chatProvider.fetchMessages(
                                      targetId,
                                      recipientId:
                                          chatProvider.activeRecipientId,
                                    );
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    reverse: true,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    itemCount: chatProvider.messages.length +
                                        (chatProvider.isLoadingMore ||
                                                chatProvider.loadMoreError
                                            ? 1
                                            : 0),
                                    findChildIndexCallback: (Key key) {
                                      if (key is ValueKey<String>) {
                                        final id =
                                            key.value.replaceFirst('msg_', '');
                                        final idx = chatProvider.messages
                                            .indexWhere((m) => m.id == id);
                                        if (idx != -1) {
                                          return chatProvider.messages.length -
                                              1 -
                                              idx;
                                        }
                                        return null;
                                      }
                                      return null;
                                    },
                                    itemBuilder: (context, index) {
                                      if (index ==
                                          chatProvider.messages.length) {
                                        if (chatProvider.loadMoreError) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: () => chatProvider
                                                    .loadMoreMessages(),
                                                icon: const Icon(
                                                    Icons.refresh_rounded,
                                                    size: 16,
                                                    color: Color(0xFF00D2FF)),
                                                label: const Text(
                                                  'Failed to load older messages. Tap to retry',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF00D2FF),
                                                      fontWeight:
                                                          FontWeight.bold),
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
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF00D2FF),
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10.0),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0066FF)
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFF0066FF)
                                                            .withValues(
                                                                alpha: 0.3)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .arrow_upward_rounded,
                                                      size: 13,
                                                      color: Color(0xFF00D2FF)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Scroll up for older history',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF00D2FF)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      final displayIndex =
                                          chatProvider.messages.length -
                                              1 -
                                              index;
                                      final msg =
                                          chatProvider.messages[displayIndex];
                                      final showDate = displayIndex == 0 ||
                                          !_isSameDay(
                                              msg.timestamp,
                                              chatProvider
                                                  .messages[displayIndex - 1]
                                                  .timestamp);

                                      return Column(
                                        key: ValueKey('msg_${msg.id}'),
                                        children: [
                                          if (showDate)
                                            DateSeparatorWidget(
                                                date: msg.timestamp),
                                          ChatMessageBubble(
                                            message: msg,
                                            accentColor:
                                                const Color(0xFF0066FF),
                                            onReply: () =>
                                                chatProvider.setReplyingTo(msg),
                                            onDelete: () => chatProvider
                                                .deleteMessage(msg.id),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),

                                // Floating Scroll-to-Bottom button
                                if (_showScrollToBottomBtn)
                                  Positioned(
                                    right: 16,
                                    bottom: 16,
                                    child: GestureDetector(
                                      onTap: () => _scrollToBottom(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF00D2FF),
                                              Color(0xFF0066FF)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0066FF)
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Scroll Down',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
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
              const TypingIndicatorWidget(
                agencyName: 'DreamHub Official Support',
                accentColor: Color(0xFF00D2FF),
              ),

            _buildDashboardInputField(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDashboardAppBar(
      BuildContext context, ChatProvider chatProvider) {
    const activeTitle = 'DreamHub  Support';
    const activeRecipient = ApiEndpoints.adminAgencyUnqId;
    const String targetEmail = ApiEndpoints.adminEmailId;
    final isOnline = SocketService.instance
        .isUserOnline(activeRecipient, targetEmail: targetEmail);
    final lastSeen = SocketService.instance
        .getLastSeen(activeRecipient, targetEmail: targetEmail);
    final String activeSubtitle = isOnline
        ? 'online'
        : (lastSeen != null
            ? DateFormatter.formatLastSeen(lastSeen)
            : 'offline');

    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF070D22),
          gradient: const LinearGradient(
            colors: [Color(0xFF0B1536), Color(0xFF070D22)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                // Back Button Box
                InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2346),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 17),
                  ),
                ),
                const SizedBox(width: 10),

                // Support Avatar Box
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFFA78BFA),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),

                // Support Title & Subtitle
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF8F9BBA),
                              shape: BoxShape.circle,
                              boxShadow: isOnline
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.8),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activeSubtitle,
                            style: GoogleFonts.plusJakartaSans(
                              color: isOnline
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF8F9BBA),
                              fontSize: 11.5,
                              fontWeight:
                                  isOnline ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Admin Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFA78BFA),
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardInputField(BuildContext context) {
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
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: Color(0xFF0066FF), size: 24),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => AttachmentSheetWidget(
                    onAttachmentSelected: (type, _) =>
                        _handleAttachmentSelected(type),
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
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111B21), fontSize: 14.5),
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Message DreamHub Admin Support...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF667781), fontSize: 13.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_hasText)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 19),
                  onPressed: () => _sendMessage(),
                ),
              )
            else
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 19),
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
                            final sendToId =
                                provider.activeRecipientId ?? widget.userId;
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

  Widget _buildErrorState(BuildContext context, ChatProvider chatProvider) {
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
                border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: Colors.red, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Chat',
              style: TextStyle(
                  color: Color(0xFF111B21),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              chatProvider.errorMessage ??
                  'Connection issue occurred while fetching messages.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667781), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                final targetId =
                    chatProvider.activeConversationId ?? widget.userId;
                chatProvider.fetchMessages(targetId,
                    recipientId: widget.userId);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075E54),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLightState() {
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
                color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                border: Border.all(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                    width: 1.5),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF0066FF), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'DreamHub Official Support',
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF111B21),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Send a message for instant support, deposits, withdrawals, or account assistance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF667781), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildQuickActionCardsRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F2F5),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // 1. Recharge Card
          Expanded(
            child: _buildActionCard(
              title: 'Recharge',
              subtitle: 'Add Cash Deposit',
              icon: Icons.add_circle_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              onTap: _showRechargeModal,
            ),
          ),
          const SizedBox(width: 8),

          // 2. Withdraw Card
          Expanded(
            child: _buildActionCard(
              title: 'Withdraw',
              subtitle: 'Request Cash Out',
              icon: Icons.arrow_circle_up_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              ),
              onTap: _showWithdrawModal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111B21),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF667781),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
