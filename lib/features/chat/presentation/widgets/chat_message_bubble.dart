import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../models/chat/chat_message_model.dart';
import '../../../../providers/chat_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/date_formatter.dart';
import 'media_preview_dialog.dart';
import 'voice_player_widget.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessageModel message;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final Color accentColor;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.onReply,
    required this.onDelete,
    this.accentColor = AppColors.primary,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1830) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 16),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildMenuOption(
                  icon: Icons.copy_rounded,
                  label: 'Copy Text',
                  color: widget.accentColor,
                  isDark: isDark,
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.message.message));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: widget.accentColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                _buildMenuOption(
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  color: AppColors.userAccent,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onReply();
                  },
                ),
                if (widget.message.imageUrl != null)
                  _buildMenuOption(
                    icon: Icons.open_in_full_rounded,
                    label: 'Preview Image',
                    color: AppColors.info,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      MediaPreviewDialog.show(
                        context,
                        imageUrl: widget.message.imageUrl!,
                        timeString:
                            DateFormatter.formatTime(widget.message.timestamp),
                      );
                    },
                  ),
                if (widget.message.isMe)
                  _buildMenuOption(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: AppColors.error,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete();
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTicks(String status) {
    if (status == 'uploading' || status == 'sending') {
      return const Icon(Icons.access_time_rounded,
          size: 13, color: Colors.white60);
    } else if (status == 'sent') {
      return const Icon(Icons.check_rounded, size: 14, color: Colors.white60);
    } else if (status == 'delivered') {
      return const Icon(Icons.done_all_rounded, size: 14, color: Colors.white60);
    } else {
      return Icon(Icons.done_all_rounded,
          size: 14, color: widget.accentColor.withValues(alpha: 0.9));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final msg = widget.message;
    final timeStr = DateFormatter.formatTime(msg.timestamp);
    final accent = widget.accentColor;

    final isUploading = msg.status == 'uploading' ||
        (msg.uploadProgress != null && msg.uploadProgress! < 1.0);
    final isDownloading =
        msg.downloadProgress != null && msg.downloadProgress! < 1.0;
    final isImage = msg.imageUrl != null || msg.type == 'image';
    final isVoice = msg.voiceDuration != null || msg.type == 'voice';
    final isDoc = msg.type == 'document';

    // Bubble colors
    final myBubbleBg = accent;
    final theirBubbleBg = isDark ? const Color(0xFF1E1B3A) : Colors.white;
    final theirBubbleBorder = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFE8E7FF);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onLongPress: () => _showContextMenu(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Align(
              alignment:
                  msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: msg.isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Tail for incoming messages
                  if (!msg.isMe) ...[
                    const SizedBox(width: 4),
                  ],

                  // Bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isMe ? myBubbleBg : theirBubbleBg,
                      gradient: msg.isMe
                          ? LinearGradient(
                              colors: [
                                accent,
                                accent.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft:
                            Radius.circular(msg.isMe ? 20 : 4),
                        bottomRight:
                            Radius.circular(msg.isMe ? 4 : 20),
                      ),
                      border: msg.isMe
                          ? null
                          : Border.all(color: theirBubbleBorder),
                      boxShadow: [
                        BoxShadow(
                          color: msg.isMe
                              ? accent.withValues(alpha: 0.25)
                              : Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quoted Reply Preview
                        if (msg.replyToMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                            decoration: BoxDecoration(
                              color: msg.isMe
                                  ? Colors.black.withValues(alpha: 0.18)
                                  : accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border(
                                left: BorderSide(
                                  color: msg.isMe
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : accent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Replying to',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: msg.isMe
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : accent,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  msg.replyToMessage!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: msg.isMe
                                        ? Colors.white70
                                        : (isDark
                                            ? Colors.white60
                                            : Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Image Attachment
                        if (isImage)
                          GestureDetector(
                            onTap: () {
                              if (msg.imageUrl != null && msg.isDownloaded) {
                                MediaPreviewDialog.show(
                                  context,
                                  imageUrl: msg.imageUrl!,
                                  timeString: timeStr,
                                );
                              } else if (!msg.isDownloaded) {
                                context
                                    .read<ChatProvider>()
                                    .simulateMediaDownload(msg.id);
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                height: 190,
                                decoration: const BoxDecoration(
                                    color: Colors.black26),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Hero(
                                      tag: msg.imageUrl ?? msg.id,
                                      child: msg.imageUrl != null &&
                                              msg.imageUrl!.startsWith('http')
                                          ? Image.network(
                                              msg.imageUrl!,
                                              width: double.infinity,
                                              height: 190,
                                              fit: BoxFit.cover,
                                              cacheWidth: 600,
                                              cacheHeight: 600,
                                              errorBuilder: (ctx, _, __) =>
                                                  _buildPlaceholderImage(),
                                            )
                                          : _buildPlaceholderImage(),
                                    ),
                                    // Upload overlay
                                    if (isUploading)
                                      Container(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 40,
                                                height: 40,
                                                child:
                                                    CircularProgressIndicator(
                                                  value:
                                                      msg.uploadProgress ?? 0.2,
                                                  strokeWidth: 3,
                                                  color: Colors.white,
                                                  backgroundColor:
                                                      Colors.white24,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${((msg.uploadProgress ?? 0) * 100).toInt()}%',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Download button
                                    if (!msg.isMe && !msg.isDownloaded)
                                      Container(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        child: Center(
                                          child: GestureDetector(
                                            onTap: () {
                                              context
                                                  .read<ChatProvider>()
                                                  .simulateMediaDownload(
                                                      msg.id);
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.7),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                border: Border.all(
                                                    color: Colors.white38),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  isDownloading
                                                      ? SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                            value: msg
                                                                .downloadProgress,
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.download_rounded,
                                                          color: Colors.white,
                                                          size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    isDownloading
                                                        ? '${((msg.downloadProgress ?? 0) * 100).toInt()}%'
                                                        : 'Tap to download',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Preview badge
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.zoom_in_rounded,
                                                color: Colors.white, size: 12),
                                            SizedBox(width: 3),
                                            Text('View',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9.5,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Voice Note
                        if (isVoice)
                          Column(
                            children: [
                              if (isUploading)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Uploading... ${((msg.uploadProgress ?? 0) * 100).toInt()}%',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              VoicePlayerWidget(
                                durationStr: msg.voiceDuration ?? '0:15',
                                isMe: msg.isMe,
                              ),
                            ],
                          ),

                        // Document
                        if (isDoc)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: msg.isMe
                                  ? Colors.black.withValues(alpha: 0.15)
                                  : accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.error.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.picture_as_pdf_rounded,
                                      color: AppColors.error, size: 28),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.message.isNotEmpty
                                            ? msg.message
                                            : 'Document.pdf',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: msg.isMe
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black87),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        msg.fileSize ?? '2.4 MB • PDF',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: msg.isMe
                                              ? Colors.white60
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.download_rounded,
                                      size: 20,
                                      color: msg.isMe
                                          ? Colors.white70
                                          : accent),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            const Text('Downloading...'),
                                        backgroundColor: accent,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                        // Text message
                        if (msg.message.isNotEmpty &&
                            !isDoc &&
                            (isImage
                                ? msg.message != '📷 Image Attachment'
                                : true))
                          Text(
                            msg.message,
                            style: TextStyle(
                              color: msg.isMe
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : const Color(0xFF1E293B)),
                              fontSize: 14.5,
                              height: 1.4,
                            ),
                          ),

                        const SizedBox(height: 5),

                        // Timestamp + Status
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: msg.isMe
                                    ? Colors.white.withValues(alpha: 0.65)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.35)
                                        : Colors.black38),
                              ),
                            ),
                            if (msg.isMe) ...[
                              const SizedBox(width: 4),
                              _buildStatusTicks(msg.status),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (msg.isMe) const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFF1A1830),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_rounded,
                size: 40, color: widget.accentColor.withValues(alpha: 0.5)),
            const SizedBox(height: 6),
            Text('Media',
                style: TextStyle(
                    color: widget.accentColor.withValues(alpha: 0.5),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
