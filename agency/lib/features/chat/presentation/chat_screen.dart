import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../models/agency/agency_user_item_model.dart';
import '../../../providers/agency_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../socket/socket_service.dart';
import '../../../theme/app_colors.dart';
import 'widgets/attachment_sheet_widget.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/date_separator_widget.dart';
import 'widgets/typing_indicator_widget.dart';
import 'widgets/voice_recorder_widget.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final AgencyUserItem? userItem;
  final String? initialGameName;

  const ChatScreen({
    super.key,
    required this.userId,
    this.userItem,
    this.initialGameName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _sendBtnController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _sendBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);

    final currentUser = LocalStorageRepositoryImpl().getUser();
    final agencyId = currentUser?.agencyId;
    final userId = currentUser?.id;
    final userEmail = currentUser?.email;
    final rawAgent = (agencyId != null && agencyId.isNotEmpty)
        ? agencyId
        : ((userId != null && userId.isNotEmpty) ? userId : (userEmail ?? ''));
    final effectiveAgentId = (rawAgent.startsWith('AGENCY-') || rawAgent.toUpperCase().contains('ADMIN') || rawAgent.contains('@'))
        ? rawAgent
        : (rawAgent.isNotEmpty ? 'AGENCY-$rawAgent' : 'AGENCY');

    final targetUserId = widget.userId.trim().toLowerCase();
    final conversationId = targetUserId.startsWith('conv-')
        ? targetUserId
        : ApiEndpoints.buildConversationId(effectiveAgentId, targetUserId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chatProv = context.read<ChatProvider>();
      chatProv.fetchMessages(
        conversationId,
        recipientId: targetUserId,
        limit: 35,
      );
      context.read<AgencyProvider>().markUserAsRead(widget.userId);
    });
  }

  String _getDynamicConversationId() {
    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.activeConversationId != null && chatProvider.activeConversationId!.isNotEmpty) {
      return chatProvider.activeConversationId!;
    }
    final currentUser = LocalStorageRepositoryImpl().getUser();
    final agencyId = currentUser?.agencyId;
    final userId = currentUser?.id;
    final userEmail = currentUser?.email;
    final rawAgent = (agencyId != null && agencyId.isNotEmpty)
        ? agencyId
        : ((userId != null && userId.isNotEmpty) ? userId : (userEmail ?? ''));
    final effectiveAgentId = (rawAgent.startsWith('AGENCY-') || rawAgent.toUpperCase().contains('ADMIN') || rawAgent.contains('@'))
        ? rawAgent
        : (rawAgent.isNotEmpty ? 'AGENCY-$rawAgent' : 'AGENCY');
    final targetUserId = widget.userId.trim().toLowerCase();
    return targetUserId.startsWith('conv-')
        ? targetUserId
        : ApiEndpoints.buildConversationId(effectiveAgentId, targetUserId);
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ChatProvider>();
      if (provider.hasMoreMessages && !provider.isLoadingMore) {
        provider.loadMoreMessages();
      }
    }
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

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  void _sendMessage({String? imageUrl, String? voiceDuration, String type = 'text'}) async {
    final chatProvider = context.read<ChatProvider>();
    final text = _messageController.text;
    final stagedPath = chatProvider.stagedImagePath;

    if (text.trim().isEmpty &&
        imageUrl == null &&
        voiceDuration == null &&
        stagedPath == null) { return; }

    final targetUserId = chatProvider.isHigherAuthorityActive
        ? 'admin_higher_authority'
        : widget.userId;

    SocketService.instance.sendTypingStop(targetUserId);

    _messageController.clear();
    final success = await chatProvider.sendMessage(
      targetUserId,
      text,
      type: stagedPath != null ? 'image' : type,
      imageUrl: imageUrl ?? stagedPath,
      voiceDuration: voiceDuration,
      isAgencyAdmin: widget.userItem != null,
    );

    if (success) {
      if (!mounted) return;
      if (widget.userItem != null && !chatProvider.isHigherAuthorityActive) {
        final lastPreview = text.isNotEmpty
            ? text
            : (imageUrl != null || stagedPath != null
                ? '📷 Image'
                : '🎤 Voice Note');
        context
            .read<AgencyProvider>()
            .updateUserLastMessage(widget.userId, lastPreview);
      }
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 140,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openAttachmentSheet() {
    AttachmentSheetWidget.show(context, (type, path) {
      final chatProvider = context.read<ChatProvider>();
      if (type == 'image') {
        chatProvider.setStagedImage(path);
      } else if (type == 'voice') {
        _sendMessage(type: 'voice', voiceDuration: path);
      }
    });
  }

  bool _isDifferentDay(DateTime date1, DateTime date2) {
    return date1.year != date2.year ||
        date1.month != date2.month ||
        date1.day != date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHigherAdmin = chatProvider.isHigherAuthorityActive;
    final isClientUser = widget.userItem != null;

    const Map<String, dynamic>? agencyData = null;
    final partnerName = widget.userItem?.name ??
        (agencyData?['name'] ?? 'Agency Support');
    final activeTitle =
        isHigherAdmin ? 'Admin Higher Authority' : partnerName;
    final isOnline = isHigherAdmin
        ? true
        : (widget.userItem?.isOnline ?? (agencyData?['is_online'] ?? true));

    final partnerBadgeText = isHigherAdmin
        ? 'SYSTEM ADMIN'
        : (isClientUser ? 'CLIENT' : 'AGENCY SUPPORT');

    final accentColor = isHigherAdmin
        ? const Color(0xFFDC3545)
        : (isClientUser ? const Color(0xFF6366F1) : const Color(0xFF7C3AED));

    // Background colors based on mode (Agency chat vs User chat)
    final bgColor = isDark
        ? (isClientUser ? const Color(0xFF0F0C20) : const Color(0xFF04020A))
        : const Color(0xFFF7F7FD);

    final headerBg = isClientUser ? const Color(0xFF0C0720) : const Color(0xFF04020A);
    final buttonBg = isClientUser ? const Color(0xFF1D0D45) : const Color(0xFF0E0921);
    final buttonBorder = isClientUser ? const Color(0xFF3C2373) : const Color(0xFF3C2373);
    final borderBottomColor = isClientUser ? const Color(0xFF6366F1) : const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(
              bottom: BorderSide(
                color: borderBottomColor,
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: borderBottomColor.withValues(alpha: isClientUser ? 0.25 : 0.4),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: buttonBg,
                          border: Border.all(
                            color: buttonBorder,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B39CF).withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Avatar with online dot
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: buttonBg,
                          border: Border.all(
                            color: borderBottomColor.withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: borderBottomColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          backgroundImage: widget.userItem?.avatarUrl != null
                              ? NetworkImage(widget.userItem!.avatarUrl!)
                              : null,
                          child: widget.userItem?.avatarUrl == null
                              ? (isHigherAdmin
                                  ? const Icon(
                                      Icons.admin_panel_settings_rounded,
                                      color: Color(0xFFFFC700),
                                      size: 22,
                                    )
                                  : isClientUser
                                      ? Text(
                                          partnerName.isNotEmpty
                                              ? partnerName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 17,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.support_agent_rounded,
                                          color: Color(0xFFA78BFA),
                                          size: 22,
                                        ))
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: headerBg,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // Name + badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          activeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: borderBottomColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                partnerBadgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 11,
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : (isClientUser ? const Color(0xFFC4B5FD) : const Color(0xFF94A3B8)),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Higher Authority toggle button
                  GestureDetector(
                    onTap: () =>
                        chatProvider.toggleHigherAuthority(widget.userId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isHigherAdmin
                            ? borderBottomColor
                            : buttonBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isHigherAdmin
                              ? const Color(0xFF8B5CF6)
                              : buttonBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHigherAdmin
                                ? Icons.business_center_rounded
                                : Icons.shield_rounded,
                            size: 14,
                            color: isHigherAdmin
                                ? Colors.white
                                : const Color(0xFFA78BFA),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isHigherAdmin ? 'Agency' : 'Admin',
                            style: TextStyle(
                              color: isHigherAdmin
                                  ? Colors.white
                                  : const Color(0xFFA78BFA),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // WhatsApp Chat Wallpaper Doodle Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: WhatsAppDoodleBackgroundPainter(isDark: isDark),
            ),
          ),

          // Chat Area & Inputs
          Column(
            children: [
              // ── Quick Action Cards (Recharge, Wallet, Withdraw) ────────────
              _buildQuickActionCardsRow(context, isDark, accentColor),

              // ── Message List ────────────────────────────────────────────────
              Expanded(
                child: chatProvider.isLoading
                    ? const ChatMessageSkeletonWidget()
                    : chatProvider.messages.isEmpty
                        ? _buildEmptyState(
                            partnerName, isClientUser, accentColor, isDark)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 16),
                            itemCount: chatProvider.messages.length,
                            addAutomaticKeepAlives: true,
                            addRepaintBoundaries: true,
                            itemBuilder: (context, index) {
                              final msg = chatProvider.messages[index];
                              final bool showDateSeparator = index == 0 ||
                                  _isDifferentDay(
                                    chatProvider.messages[index - 1].timestamp,
                                    msg.timestamp,
                                  );
                              return Column(
                                key: ValueKey(msg.id),
                                children: [
                                  if (showDateSeparator)
                                    DateSeparatorWidget(date: msg.timestamp),
                                  ChatMessageBubble(
                                    message: msg,
                                    accentColor: accentColor,
                                    onReply: () =>
                                        chatProvider.setReplyingTo(msg),
                                    onDelete: () =>
                                        chatProvider.deleteMessage(msg.id),
                                  ),
                                ],
                              );
                            },
                          ),
              ),

              // ── Typing Indicator ────────────────────────────────────────────
              if (chatProvider.isAgencyTyping)
                TypingIndicatorWidget(
                    agencyName: partnerName, accentColor: accentColor),

              // ── Staged Image Preview ───────────────────────────────────────
              if (chatProvider.stagedImagePath != null)
                _buildStagedImageBar(chatProvider, isDark, accentColor),

              // ── Reply Quote Banner ─────────────────────────────────────────
              if (chatProvider.replyingToMessage != null)
                _buildReplyBanner(chatProvider, isDark, accentColor),

              // ── Input Bar ─────────────────────────────────────────────────
              _buildInputBar(
                  chatProvider, isDark, isClientUser, partnerName, accentColor),
            ],
          ),
        ],
      ),
    );
  }

  // ── Staged Image Preview ─────────────────────────────────────────────────
  Widget _buildStagedImageBar(
      ChatProvider chatProvider, bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1830) : const Color(0xFFF0EFFF),
        border: Border(
          top: BorderSide(color: accentColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: chatProvider.stagedImagePath!.startsWith('http')
                ? Image.network(chatProvider.stagedImagePath!,
                    width: 48, height: 48, fit: BoxFit.cover)
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.image_rounded,
                        color: accentColor, size: 24),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image ready to send',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add a caption or tap Send',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => chatProvider.clearStagedImage(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.error, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reply Banner ─────────────────────────────────────────────────────────
  Widget _buildReplyBanner(
      ChatProvider chatProvider, bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1830) : const Color(0xFFF0EFFF),
        border: Border(
          top: BorderSide(color: accentColor.withValues(alpha: 0.2)),
          left: BorderSide(color: accentColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  chatProvider.replyingToMessage!.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white54
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => chatProvider.cancelReply(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Bar ────────────────────────────────────────────────────────────
  Widget _buildInputBar(ChatProvider chatProvider, bool isDark,
      bool isClientUser, String partnerName, Color accentColor) {
    final inputBg = isDark ? const Color(0xFF12102A) : Colors.white;
    final fieldBg =
        isDark ? const Color(0xFF1E1B3A) : const Color(0xFFF0EFFF);

    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: chatProvider.isRecording
              ? VoiceRecorderWidget(
                  onCancel: () {},
                  onSend: (filePath, durationStr) {
                    final sendToId = chatProvider.activeRecipientId ?? widget.userId;
                    chatProvider.sendVoiceMessage(sendToId, filePath, durationStr);
                    _scrollToBottom();
                  },
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Attachment button
                    _buildInputAction(
                      icon: Icons.add_rounded,
                      color: accentColor,
                      onTap: _openAttachmentSheet,
                    ),
                    const SizedBox(width: 6),

                    // Camera button
                    _buildInputAction(
                      icon: Icons.camera_alt_rounded,
                      color: accentColor,
                      onTap: () {
                        chatProvider.setStagedImage(
                            'https://picsum.photos/800/600');
                      },
                    ),
                    const SizedBox(width: 8),

                    // Text field
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: fieldBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _hasText
                                ? accentColor.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: isClientUser
                                ? 'Message $partnerName...'
                                : 'Message agency support...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black38,
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Mic / Send button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: _hasText || chatProvider.stagedImagePath != null
                          ? _buildSendButton(chatProvider, accentColor)
                          : _buildMicButton(chatProvider, accentColor),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInputAction(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildSendButton(ChatProvider chatProvider, Color accentColor) {
    return GestureDetector(
      key: const ValueKey('send'),
      onTap: chatProvider.isSending ? null : () => _sendMessage(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: chatProvider.isSending
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildMicButton(ChatProvider chatProvider, Color accentColor) {
    return GestureDetector(
      key: const ValueKey('mic'),
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: VoiceRecorderWidget(
              onSend: (path, dur) {
                Navigator.pop(ctx);
                final sendToId = chatProvider.activeRecipientId ?? widget.userId;
                chatProvider.sendVoiceMessage(sendToId, path, dur);
                _scrollToBottom();
              },
              onCancel: () => Navigator.pop(ctx),
            ),
          ),
        );
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.mic_rounded, color: accentColor, size: 22),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(String name, bool isClientUser, Color accentColor,
      bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                isClientUser
                    ? Icons.person_outline_rounded
                    : Icons.support_agent_rounded,
                size: 52,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isClientUser ? name : 'Agency Support',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isClientUser
                  ? 'Start the conversation with $name.'
                  : 'Your assigned agency is ready to assist you.\nSend a message to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black38,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 14,
                      color: accentColor.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'End-to-end secured conversation',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: accentColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Action Cards Bar (Recharge, Wallet, Withdraw) ────────────────
  Widget _buildQuickActionCardsRow(
      BuildContext context, bool isDark, Color accentColor) {
    final authProvider = context.watch<AuthProvider>();
    final isAgencyUser = authProvider.currentUser?.isAgency ?? false;
    final isClientUser = widget.userItem != null;

    // Hide Recharge, Wallet, Withdraw cards on Agency Dashboard & Agency user conversations
    if (isAgencyUser || isClientUser) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141226) : const Color(0xFFEBE9FF),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFDDD8FF),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Recharge Card
          Expanded(
            child: _buildActionCard(
              title: 'Recharge',
              subtitle: 'Add Cash',
              icon: Icons.add_circle_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              onTap: () => _openRechargeModal(context),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Wallet Card
          Expanded(
            child: _buildActionCard(
              title: 'Wallet',
              subtitle: '₹0.00 Bal',
              icon: Icons.account_balance_wallet_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
              onTap: () => _openWalletModal(context),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Withdraw Card
          Expanded(
            child: _buildActionCard(
              title: 'Withdraw',
              subtitle: 'Cash Out',
              icon: Icons.arrow_circle_up_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              ),
              onTap: () => _openWithdrawModal(context),
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // ── 1. Recharge Modal ───────────────────────────────────────────────────
  void _openRechargeModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGame = widget.initialGameName ?? 'KALYAN MORNING';
    final amountController = TextEditingController(text: '500');
    final gameController = TextEditingController(text: defaultGame);
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1830) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_circle_rounded,
                                color: Color(0xFF10B981), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recharge Request',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Submit money deposit details to Agency Support',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Game Name Input
                      const Text(
                        'Game Name / Market',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: gameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. KALYAN MORNING, RUMMY GAME',
                          prefixIcon: const Icon(Icons.casino_rounded,
                              color: Color(0xFF10B981)),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF252244)
                              : const Color(0xFFF5F4FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Recharge Amount Input
                      const Text(
                        'Total Amount (₹)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Enter amount (e.g. 500)',
                          prefixIcon: const Icon(Icons.currency_rupee_rounded,
                              color: Color(0xFF10B981)),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF252244)
                              : const Color(0xFFF5F4FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Amount Chips
                      Row(
                        children: [100, 500, 1000, 2000, 5000].map((amt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text('₹$amt',
                                  style: const TextStyle(fontSize: 11)),
                              backgroundColor: const Color(0xFF10B981)
                                  .withValues(alpha: 0.1),
                              onPressed: () {
                                setModalState(() {
                                  amountController.text = amt.toString();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Optional Payment Note / UTR
                      const Text(
                        'Payment UTR / Reference Note (Optional)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          hintText: 'e.g. GPay UTR 1234567890',
                          prefixIcon: const Icon(Icons.receipt_long_rounded,
                              color: Colors.grey),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF252244)
                              : const Color(0xFFF5F4FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Confirm Button
                      ElevatedButton(
                        onPressed: () {
                          final gameName = gameController.text.trim();
                          final amount = amountController.text.trim();
                          final note = noteController.text.trim();

                          if (amount.isEmpty ||
                              double.tryParse(amount) == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter a valid recharge amount'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);

                          final reqMessage = '💰 RECHARGE REQUEST\n'
                              '• Game: ${gameName.isNotEmpty ? gameName : defaultGame}\n'
                              '• Amount: ₹$amount'
                              '${note.isNotEmpty ? "\n• Note: $note" : ""}';

                          _sendDirectRequestMessage(reqMessage);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Recharge request sent to Agency Support!'),
                              backgroundColor: Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'CONFIRM & SUBMIT RECHARGE',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── 2. Withdraw Modal ───────────────────────────────────────────────────
  void _openWithdrawModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGame = widget.initialGameName ?? 'KALYAN MORNING';
    final amountController = TextEditingController(text: '500');
    final gameController = TextEditingController(text: defaultGame);
    final paymentDetailsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1830) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_circle_up_rounded,
                                color: Color(0xFFF97316), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Withdrawal Request',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Request payout to your UPI or Bank account',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Game Name Input
                      const Text(
                        'Game Name / Market',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: gameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. KALYAN MORNING, MAIN BAZAR',
                          prefixIcon: const Icon(Icons.casino_rounded,
                              color: Color(0xFFF97316)),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF252244)
                              : const Color(0xFFF5F4FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Withdraw Amount Input
                      const Text(
                        'Withdraw Amount (₹)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Enter amount (e.g. 500)',
                          prefixIcon: const Icon(Icons.currency_rupee_rounded,
                              color: Color(0xFFF97316)),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF252244)
                              : const Color(0xFFF5F4FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Amount Chips
                      Row(
                        children: [500, 1000, 2000, 5000].map((amt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text('₹$amt',
                                  style: const TextStyle(fontSize: 11)),
                              backgroundColor: const Color(0xFFF97316)
                                  .withValues(alpha: 0.1),
                              onPressed: () {
                                setModalState(() {
                                  amountController.text = amt.toString();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // UPI / Bank Details Input
                      const Text(
                        'UPI ID or Bank Details',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: paymentDetailsController,
                        decoration: InputDecoration(
                          hintText:
                              'e.g. 9876543210@paytm or Bank Account & IFSC',
                          prefixIcon: const Icon(Icons.account_balance_rounded,
                              color: Color(0xFFF97316)),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF252244)
                              : const Color(0xFFF5F4FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Confirm Button
                      ElevatedButton(
                        onPressed: () {
                          final gameName = gameController.text.trim();
                          final amount = amountController.text.trim();
                          final details = paymentDetailsController.text.trim();

                          if (amount.isEmpty ||
                              double.tryParse(amount) == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter a valid withdrawal amount'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          if (details.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter your UPI ID or Bank account details'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);

                          final reqMessage = '💸 WITHDRAWAL REQUEST\n'
                              '• Game: ${gameName.isNotEmpty ? gameName : defaultGame}\n'
                              '• Amount: ₹$amount\n'
                              '• Payment Details: $details';

                          _sendDirectRequestMessage(reqMessage);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Withdrawal request submitted!'),
                              backgroundColor: Color(0xFFF97316),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'CONFIRM & SUBMIT WITHDRAWAL',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── 3. Wallet Modal ─────────────────────────────────────────────────────
  void _openWalletModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1830) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.account_balance_wallet_rounded,
                  size: 48, color: Color(0xFF8B5CF6)),
              const SizedBox(height: 8),
              const Text('Available Wallet Balance',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('₹0.00',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openRechargeModal(context);
                      },
                      icon: const Icon(Icons.add_circle_rounded),
                      label: const Text('Recharge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openWithdrawModal(context);
                      },
                      icon: const Icon(Icons.arrow_circle_up_rounded),
                      label: const Text('Withdraw'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendDirectRequestMessage(String text) async {
    final chatProvider = context.read<ChatProvider>();
    final targetUserId = chatProvider.isHigherAuthorityActive
        ? 'admin_higher_authority'
        : widget.userId;

    await chatProvider.sendMessage(
      targetUserId,
      text,
      type: 'text',
      isAgencyAdmin: widget.userItem != null,
    );

    if (!mounted) return;
    _scrollToBottom();
  }
}

// ─── WhatsApp Style Doodle Chat Wallpaper Painter ─────────────────────────────
class WhatsAppDoodleBackgroundPainter extends CustomPainter {
  final bool isDark;

  WhatsAppDoodleBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFF54656F).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const stepX = 75.0;
    const stepY = 75.0;

    int index = 0;
    for (double y = 25; y < size.height; y += stepY) {
      for (double x = 25; x < size.width; x += stepX) {
        final shapeType = (index + (y / stepY).floor()) % 6;
        final dx = x + ((index % 2 == 0) ? 12 : -12);
        final dy = y;

        switch (shapeType) {
          case 0:
            final r = RRect.fromRectAndRadius(
              Rect.fromLTWH(dx, dy, 18, 14),
              const Radius.circular(4),
            );
            canvas.drawRRect(r, paint);
            canvas.drawLine(Offset(dx + 4, dy + 14), Offset(dx + 2, dy + 18), paint);
            canvas.drawLine(Offset(dx + 2, dy + 18), Offset(dx + 8, dy + 14), paint);
            break;
          case 1:
            final path = Path();
            path.moveTo(dx + 8, dy);
            path.lineTo(dx + 10, dy + 6);
            path.lineTo(dx + 16, dy + 6);
            path.lineTo(dx + 11, dy + 10);
            path.lineTo(dx + 13, dy + 16);
            path.lineTo(dx + 8, dy + 12);
            path.lineTo(dx + 3, dy + 16);
            path.lineTo(dx + 5, dy + 10);
            path.lineTo(dx, dy + 6);
            path.lineTo(dx + 6, dy + 6);
            path.close();
            canvas.drawPath(path, paint);
            break;
          case 2:
            final path = Path();
            path.moveTo(dx + 8, dy + 14);
            path.cubicTo(dx - 4, dy + 4, dx + 2, dy - 2, dx + 8, dy + 4);
            path.cubicTo(dx + 14, dy - 2, dx + 20, dy + 4, dx + 8, dy + 14);
            canvas.drawPath(path, paint);
            break;
          case 3:
            final r = RRect.fromRectAndRadius(
              Rect.fromLTWH(dx, dy + 3, 18, 12),
              const Radius.circular(3),
            );
            canvas.drawRRect(r, paint);
            canvas.drawCircle(Offset(dx + 9, dy + 9), 3, paint);
            canvas.drawRect(Rect.fromLTWH(dx + 6, dy, 6, 3), paint);
            break;
          case 4:
            canvas.drawCircle(Offset(dx + 4, dy + 12), 3, paint);
            canvas.drawLine(Offset(dx + 7, dy + 12), Offset(dx + 7, dy + 2), paint);
            canvas.drawLine(Offset(dx + 7, dy + 2), Offset(dx + 14, dy + 5), paint);
            break;
          case 5:
            canvas.drawCircle(Offset(dx + 9, dy + 9), 8, paint);
            canvas.drawCircle(Offset(dx + 6, dy + 7), 1, paint);
            canvas.drawCircle(Offset(dx + 12, dy + 7), 1, paint);
            final arcPath = Path();
            arcPath.addArc(Rect.fromLTWH(dx + 5, dy + 6, 8, 7), 0.2, 2.7);
            canvas.drawPath(arcPath, paint);
            break;
        }
        index++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
