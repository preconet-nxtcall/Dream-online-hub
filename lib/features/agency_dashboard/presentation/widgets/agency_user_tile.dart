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
    final localDt = dateTime.toLocal();
    final difference = DateTime.now().difference(localDt);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return DateFormatter.formatShortDate(localDt);
  }

  Map<String, List<Color>> _getVibrantAvatarGradient(String name) {
    final gradients = [
      [const Color(0xFF6366F1), const Color(0xFF4F46E5)], // Electric Indigo
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Deep Violet
      [const Color(0xFFEC4899), const Color(0xFFD946EF)], // Magenta Rose
      [const Color(0xFF10B981), const Color(0xFF059669)], // Emerald Mint
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber Warmth
      [const Color(0xFF06B6D4), const Color(0xFF0284C7)], // Cyan Sky
    ];
    if (name.isEmpty) return {'colors': gradients[0]};
    return {'colors': gradients[name.codeUnitAt(0) % gradients.length]};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = user.unreadCount > 0;
    final gradientColors = _getVibrantAvatarGradient(user.name)['colors']!;
    final initials = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';

    final cardBg = isDark ? const Color(0xFF16132D) : Colors.white;
    final cardBorder = hasUnread
        ? const Color(0xFF6366F1).withValues(alpha: 0.5)
        : (isDark
            ? const Color(0xFF2B264A)
            : const Color(0xFFE2E8F0));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cardBorder,
                width: hasUnread ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasUnread
                      ? const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.1)
                      : Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: hasUnread ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // 1. Vibrant Avatar Ring with Online Dot
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: (user.avatarUrl != null && user.avatarUrl!.startsWith('http'))
                          ? ClipOval(
                              child: Image.network(
                                user.avatarUrl!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 21,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 21,
                              ),
                            ),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: user.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF16132D) : Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: user.isOnline
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // 2. Client Name, Email/ID Tag, & Message Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Badges Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (user.isOnline ? const Color(0xFF10B981) : const Color(0xFF6366F1))
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.isOnline ? 'ONLINE' : 'CLIENT #${user.id}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: user.isOnline ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Email / Last Message Subtitle
                      Row(
                        children: [
                          Icon(
                            hasUnread
                                ? Icons.mark_chat_unread_rounded
                                : Icons.chat_bubble_outline_rounded,
                            size: 13,
                            color: hasUnread
                                ? (isDark ? const Color(0xFFC4B5FD) : const Color(0xFF4338CA))
                                : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              (user.lastMessage != null && user.lastMessage!.isNotEmpty)
                                  ? user.lastMessage!
                                  : (user.email.isNotEmpty ? user.email : 'Tap to view records & profile'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                                color: hasUnread
                                    ? (isDark ? const Color(0xFFC4B5FD) : const Color(0xFF4338CA))
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.55)
                                        : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // 3. Last Active Time, Unread Badge, & Action Chevron Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (user.lastActiveTime != null)
                      Text(
                        _formatRelativeTime(user.lastActiveTime),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                          color: hasUnread
                              ? const Color(0xFF6366F1)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : const Color(0xFF94A3B8)),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasUnread) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              user.unreadCount > 99
                                  ? '99+ new'
                                  : '${user.unreadCount} new',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF221D42)
                                : const Color(0xFFF0EFFF),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Color(0xFF6366F1),
                          ),
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
