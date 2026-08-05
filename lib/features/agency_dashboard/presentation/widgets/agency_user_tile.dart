import 'package:flutter/material.dart';
import '../../../../models/agency/agency_user_item_model.dart';
import '../../../../utils/date_formatter.dart';

class AgencyUserTile extends StatelessWidget {
  final AgencyUserItem user;
  final VoidCallback onTap;

  const AgencyUserTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormatter.formatShortDate(dateTime);
  }

  Map<String, Color> _getPastelAvatarColor(String name) {
    final colors = [
      {'bg': const Color(0xFFECE6FF), 'text': const Color(0xFF6366F1)}, // Soft Purple
      {'bg': const Color(0xFFFFEAD5), 'text': const Color(0xFFF97316)}, // Soft Orange
      {'bg': const Color(0xFFFFE4E6), 'text': const Color(0xFFF43F5E)}, // Soft Pink
      {'bg': const Color(0xFFFEF3C7), 'text': const Color(0xFFD97706)}, // Soft Yellow
      {'bg': const Color(0xFFE0F2FE), 'text': const Color(0xFF0284C7)}, // Soft Blue
      {'bg': const Color(0xFFDCFCE7), 'text': const Color(0xFF16A34A)}, // Soft Green
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = user.unreadCount > 0;
    final avatarColors = _getPastelAvatarColor(user.name);
    final initials = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18152D) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F0FE),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar with Online/Offline Status Dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: avatarColors['bg'],
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: avatarColors['text'],
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: user.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF18152D) : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name & Subtitle Preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.lastMessage ?? user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time, Unread Badge, and Chevron Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (user.lastActiveTime != null)
                      Text(
                        _formatRelativeTime(user.lastActiveTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasUnread) ...[
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4338CA),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              user.unreadCount > 99
                                  ? '99+'
                                  : user.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
