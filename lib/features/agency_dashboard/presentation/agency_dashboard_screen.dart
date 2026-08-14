import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/agency/agency_user_item_model.dart';
import '../../../providers/agency_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_buttons.dart';
import '../../../widgets/common/app_logout_dialog.dart';
import '../../profile/presentation/agency_profile_screen.dart';
import 'widgets/agency_user_skeleton_tile.dart';
import 'widgets/agency_user_tile.dart';
import '../../user_dashboard/presentation/widgets/recharge_records_widget.dart';

class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  int _currentNavIndex = 0; // 0: Dashboard, 1: Chat, 2: Profile

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgencyProvider>().fetchUsers();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<AgencyProvider>();
      if (!provider.isLoading && !provider.isLoadingMore && provider.hasMore) {
        provider.loadNextPage();
      }
    }
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
    final agencyProvider = context.watch<AgencyProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authProvider.currentUser;

    final surfaceColor = isDark ? const Color(0xFF18152D) : Colors.white;
    final surfaceHigh = isDark ? const Color(0xFF221F3D) : const Color(0xFFF8F7FF);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFECEAFE);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0C20) : const Color(0xFFF7F7FD),
      body: SafeArea(
        child: _currentNavIndex == 0
            ? _buildDashboardHomeTab(agencyProvider, user, isDark, surfaceColor, surfaceHigh, borderColor)
            : _currentNavIndex == 1
                ? _buildChatDirectoryTab(agencyProvider, isDark, surfaceColor, surfaceHigh, borderColor)
                : const AgencyProfileScreen(),
      ),
      bottomNavigationBar: _buildAgencyBottomNavBar(isDark),
    );
  }

  // ─── TAB 0: DASHBOARD HOME (Matching user layout) ──────────────────────────
  Widget _buildDashboardHomeTab(
    AgencyProvider agencyProvider,
    dynamic user,
    bool isDark,
    Color surfaceColor,
    Color surfaceHigh,
    Color borderColor,
  ) {
    return Column(
      children: [
        // Header with Stack for overlapping Stat Card
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Dark Header Container
            _buildHeaderBackground(
              context: context,
              user: user,
              isDark: isDark,
            ),

            // Floating Stat Summary Card
            Positioned(
              left: 16,
              right: 16,
              bottom: -32,
              child: _buildFloatingStatCard(agencyProvider, isDark),
            ),
          ],
        ),

        const SizedBox(height: 42),

        // Body Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input & Filter Button Row
                _buildSearchAndFilterRow(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  isDark: isDark,
                  agencyProvider: agencyProvider,
                ),
                const SizedBox(height: 16),

                // Section Header: Assigned Clients List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assigned Clients',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${agencyProvider.filteredUsers.length} clients',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main User List Body
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        agencyProvider.fetchUsers(isRefresh: true),
                    color: const Color(0xFF6366F1),
                    child: _buildUserListBody(
                      agencyProvider,
                      isDark,
                      surfaceColor,
                      surfaceHigh,
                      borderColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Client Complete Detail & Recharge Modal ──────────────────────────────
  void _showClientDetailModal(BuildContext context, AgencyUserItem client) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final avatarColors = _getPastelAvatarColor(client.name);
            final initials = client.name.isNotEmpty ? client.name[0].toUpperCase() : 'U';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14102B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User Info Header Block
                      Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: avatarColors['bg'],
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: avatarColors['text'],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: client.isOnline
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF14102B) : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  client.email.isNotEmpty ? client.email : 'Client ID: ${client.id}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (client.isOnline ? const Color(0xFF10B981) : const Color(0xFF6366F1))
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        client.isOnline ? 'Online Now' : 'Offline',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: client.isOnline ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (client.unreadCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${client.unreadCount} unread',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: isDark ? Colors.white60 : Colors.grey[600],
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // User Detail Cards Section
                      Text(
                        'User Complete Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF4338CA),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1838) : const Color(0xFFF8F7FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2E2756) : const Color(0xFFECEAFE),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildUserDetailRow(
                              icon: Icons.badge_outlined,
                              label: 'Client ID',
                              value: '#${client.id}',
                              isDark: isDark,
                            ),
                            const Divider(height: 16),
                            _buildUserDetailRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Full Name',
                              value: client.name,
                              isDark: isDark,
                            ),
                            const Divider(height: 16),
                            _buildUserDetailRow(
                              icon: Icons.mail_outline_rounded,
                              label: 'Email Address',
                              value: client.email.isNotEmpty ? client.email : 'Not registered',
                              isDark: isDark,
                            ),
                            const Divider(height: 16),
                            _buildUserDetailRow(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Account Status',
                              value: 'ACTIVE CLIENT',
                              valueColor: const Color(0xFF10B981),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // User Specific Recharge Requests Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_rounded, color: Color(0xFF6366F1), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'User Recharge Requests',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Fetched from DB',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Live DB Fetched User Recharge Records Widget for this specific client
                      RechargeRecordsWidget(
                        userId: client.id,
                      ),
                      const SizedBox(height: 20),

                      // Action Button: Open Chat
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(modalContext);
                            final targetChatId = client.email.isNotEmpty ? client.email : client.id;
                            context.push('/chat/$targetChatId', extra: client);
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                          label: const Text(
                            'Open Chat Thread',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
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

  Widget _buildUserDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  void _showNotificationModal(BuildContext context, AgencyProvider agencyProvider, bool isDark) {
    // Refresh recharge stats & mark all notifications as seen when opening modal
    agencyProvider.fetchRechargeStats();
    agencyProvider.markNotificationsAsSeen();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        bool showOnlyLast7Days = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer<AgencyProvider>(
              builder: (context, provider, child) {
                final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

                final unreadCount = provider.totalUnreadCount;
                final pendingRecharges = provider.pendingRechargeRequestsCount;
                final totalNotifications = unreadCount + pendingRecharges;

                final unreadClients = provider.users.where((u) {
                  if (u.unreadCount <= 0) return false;
                  if (!showOnlyLast7Days) return true;
                  if (u.lastActiveTime == null) return true;
                  return u.lastActiveTime!.isAfter(sevenDaysAgo);
                }).toList();

                return Container(
                  height: MediaQuery.of(context).size.height * 0.78,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14102B) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Modal Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? const Color(0xFF2E2756) : const Color(0xFFECEAFE),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: Color(0xFF8B5CF6),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Notifications & Alerts',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        totalNotifications > 0
                                            ? '$totalNotifications pending item${totalNotifications > 1 ? "s" : ""} require attention'
                                            : 'All agency requests and messages are clear',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (unreadCount > 0)
                                  TextButton.icon(
                                    onPressed: () {
                                      provider.markAllAsRead();
                                    },
                                    icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF6366F1)),
                                    label: const Text(
                                      'Read All',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  color: isDark ? Colors.white60 : Colors.grey[600],
                                  onPressed: () => Navigator.pop(modalContext),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Time Filter Range Selector: [ Last 7 Days ] vs [ All Time ]
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      showOnlyLast7Days = true;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: showOnlyLast7Days
                                          ? const Color(0xFF6366F1)
                                          : (isDark ? const Color(0xFF1E1B3A) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 12,
                                          color: showOnlyLast7Days ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Last 7 Days',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: showOnlyLast7Days ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      showOnlyLast7Days = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: !showOnlyLast7Days
                                          ? const Color(0xFF6366F1)
                                          : (isDark ? const Color(0xFF1E1B3A) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.history_rounded,
                                          size: 12,
                                          color: !showOnlyLast7Days ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'All Time',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: !showOnlyLast7Days ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                  // Modal Content Body
                  Expanded(
                    child: provider.isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(18),
                            child: _AgencyNotificationSkeletonList(isDark: isDark),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Counter Cards
                          Row(
                            children: [
                              // Card 1: Total Unread Messages
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(modalContext);
                                    provider.setFilter(AgencyUserFilterTab.unread);
                                    if (mounted) {
                                      setState(() {
                                        _currentNavIndex = 0;
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1B3A) : const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              color: Color(0xFF6366F1),
                                              size: 20,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6366F1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                unreadCount > 99 ? '99+' : '$unreadCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Unread Messages',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          unreadCount > 0
                                              ? '$unreadCount client chat${unreadCount > 1 ? "s" : ""}'
                                              : 'No unread chats',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Card 2: Pending Recharges
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(modalContext);
                                    provider.setFilter(AgencyUserFilterTab.all);
                                    if (mounted) {
                                      setState(() {
                                        _currentNavIndex = 0;
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2D2318) : const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Icon(
                                              Icons.hourglass_top_rounded,
                                              color: Color(0xFFF59E0B),
                                              size: 20,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '$pendingRecharges',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Pending Recharges',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          pendingRecharges > 0
                                              ? '$pendingRecharges request${pendingRecharges > 1 ? "s" : ""} pending'
                                              : 'No pending requests',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Section 1: Unread Client Messages List
                          if (unreadClients.isEmpty && unreadCount > 0 && showOnlyLast7Days) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'You have $unreadCount unread client message(s) older than 7 days. Tap "All Time" above to view them.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : const Color(0xFF4338CA),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (unreadClients.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Unread Client Chats',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF4338CA),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${unreadClients.length} clients',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: unreadClients.length > 20 ? 20 : unreadClients.length,
                              itemBuilder: (ctx, index) {
                                final client = unreadClients[index];
                                final avatarColors = _getPastelAvatarColor(client.name);
                                final initials = client.name.isNotEmpty ? client.name[0].toUpperCase() : 'U';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF13102B) : const Color(0xFFF8F7FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2E2756) : const Color(0xFFECEAFE),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: avatarColors['bg'],
                                        child: Text(
                                          initials,
                                          style: TextStyle(
                                            color: avatarColors['text'],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Single Line Format: Client Name • Message
                                      Expanded(
                                        child: Text(
                                          '${client.name} • ${client.lastMessage ?? "New message received"}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Single Line Action Badge Pill matching User App
                                      InkWell(
                                        onTap: () {
                                          Navigator.pop(modalContext);
                                          final targetChatId = client.email.isNotEmpty ? client.email : client.id;
                                          if (context.mounted) {
                                            context.push('/chat/$targetChatId', extra: client);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Text(
                                            'Chat',
                                            style: TextStyle(
                                              color: Color(0xFF6366F1),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            if (unreadClients.length > 20) ...[
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(modalContext);
                                    provider.setFilter(AgencyUserFilterTab.unread);
                                    if (mounted) {
                                      setState(() {
                                        _currentNavIndex = 1;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                  label: Text(
                                    'View All ${unreadClients.length} Unread Chats',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6366F1),
                                    side: const BorderSide(color: Color(0xFF6366F1)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],

                          // Section 2: Pending Recharge Requests List
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.history_rounded, color: Color(0xFFF59E0B), size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Recharge Requests Log',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$pendingRecharges Pending',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Live DB Fetched User Recharge Records Widget inside Modal (Single-line notification style)
                          const RechargeRecordsWidget(isCompactSingleLine: true),

                          // If All Caught Up
                          if (unreadCount == 0 && pendingRecharges == 0) ...[
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF172B23) : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Color(0xFF10B981),
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'All caught up!',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF065F46),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No unread client messages or pending recharge requests right now.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : const Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
            },
          );
        },
      );
    }).then((_) {
      agencyProvider.markNotificationsAsSeen();
    });
  }

  // ─── Header Background Widget ──────────────────────────────────────────────
  Widget _buildHeaderBackground({
    required BuildContext context,
    required dynamic user,
    required bool isDark,
  }) {
    final avatarUrl = user?.avatarUrl as String?;
    final String initialLetter = (user?.name != null && user.name.toString().isNotEmpty)
        ? user.name.toString()[0].toUpperCase()
        : 'A';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 52),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0720),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Logo Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF26105E),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: (avatarUrl != null && avatarUrl.startsWith('http'))
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        initialLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  )
                : Text(
                    initialLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Welcome Back Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agency Portal',
                  style: TextStyle(
                    color: Color(0xFFC4B5FD),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user?.name != null ? '${user.name} 👋' : 'Agency Team 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // Right Notification Button
          Builder(
            builder: (context) {
              final agencyProvider = context.watch<AgencyProvider>();
              final unseenCount = agencyProvider.unseenNotificationCount;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showNotificationModal(context, agencyProvider, isDark),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF1D0D45),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          unseenCount > 0
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          color: unseenCount > 0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFA78BFA),
                          size: 20,
                        ),
                        if (unseenCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF43F5E),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unseenCount > 99 ? '99+' : '$unseenCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Right Logout Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => AppLogoutDialog.show(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF1D0D45),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Floating Stat Summary Card ────────────────────────────────────────────
  Widget _buildFloatingStatCard(AgencyProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Clients Stat
          _buildMetricColumn(
            icon: Icons.people_rounded,
            iconBg: isDark ? const Color(0xFF26214C) : const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF6366F1),
            value: '${provider.users.length}',
            label: 'Total',
            isDark: isDark,
            onTap: () {
              provider.setFilter(AgencyUserFilterTab.all);
            },
          ),
          Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.15)),

          // Online Clients Stat
          _buildMetricColumn(
            icon: Icons.wifi_rounded,
            iconBg: isDark ? const Color(0xFF173827) : const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            value: '${provider.onlineUsersCount}',
            label: 'Online',
            isDark: isDark,
            onTap: () {
              provider.setFilter(AgencyUserFilterTab.online);
            },
          ),
          Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.15)),

          // Requests Stat (Total Database Recharge Requests)
          _buildMetricColumn(
            icon: Icons.receipt_long_rounded,
            iconBg: isDark ? const Color(0xFF382A15) : const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF59E0B),
            value: '${provider.totalRechargeRequestsCount}',
            label: 'Requests',
            isDark: isDark,
            onTap: () {
              provider.setFilter(AgencyUserFilterTab.all);
            },
          ),
          Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.15)),

          // Pending Stat (Total Pending Database Recharge Requests)
          _buildMetricColumn(
            icon: Icons.hourglass_top_rounded,
            iconBg: isDark ? const Color(0xFF3B1B29) : const Color(0xFFFFEEF0),
            iconColor: const Color(0xFFF43F5E),
            value: '${provider.pendingRechargeRequestsCount}',
            label: 'Pending',
            isDark: isDark,
            onTap: () {
              provider.setFilter(AgencyUserFilterTab.unread);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: icon == Icons.circle ? 12 : 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : const Color(0xFF64748B),
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



  // ─── Search Field ───────────────────────────────────────────────────────────
  Widget _buildSearchAndFilterRow({
    required Color surfaceColor,
    required Color borderColor,
    required bool isDark,
    required AgencyProvider agencyProvider,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (q) => agencyProvider.search(q),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Search clients by name or email...',
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.35)
                : const Color(0xFF94A3B8),
            fontSize: 13.5,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : const Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    agencyProvider.clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ─── TAB 1: DEDICATED CHAT DIRECTORY ──────────────────────────────────────
  Widget _buildChatDirectoryTab(
    AgencyProvider agencyProvider,
    bool isDark,
    Color surfaceColor,
    Color surfaceHigh,
    Color borderColor,
  ) {
    return Column(
      children: [
        // Dedicated Chat Directory Header Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Color(0xFF0C0720),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26105E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFFA78BFA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agency Client Chats',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Real-time messages and assigned client threads',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification Button
                  Builder(
                    builder: (context) {
                      final unseenCount = agencyProvider.unseenNotificationCount;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showNotificationModal(context, agencyProvider, isDark),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFF1D0D45),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  unseenCount > 0
                                      ? Icons.notifications_active_rounded
                                      : Icons.notifications_none_rounded,
                                  color: unseenCount > 0
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFA78BFA),
                                  size: 19,
                                ),
                                if (unseenCount > 0)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF43F5E),
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 15,
                                        minHeight: 15,
                                      ),
                                      child: Text(
                                        unseenCount > 99 ? '99+' : '$unseenCount',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Logout Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => AppLogoutDialog.show(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF1D0D45),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Search & Filter Section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                _buildSearchAndFilterRow(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  isDark: isDark,
                  agencyProvider: agencyProvider,
                ),
                const SizedBox(height: 14),

                // Directory Header Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assigned Client Threads',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Showing ${agencyProvider.filteredUsers.length} clients',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Main User List Body
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => agencyProvider.fetchUsers(isRefresh: true),
                    color: const Color(0xFF6366F1),
                    child: _buildUserListBody(
                      agencyProvider,
                      isDark,
                      surfaceColor,
                      surfaceHigh,
                      borderColor,
                      onUserTap: (user) {
                        // Chat tab: tap user → open chat immediately with user email
                        final targetChatId = user.email.isNotEmpty ? user.email : user.id;
                        context.push('/chat/$targetChatId', extra: user);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Floating Dark Pill Bottom Navigation Bar ─────────────────────────────
  Widget _buildAgencyBottomNavBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A091A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isSelected: _currentNavIndex == 0,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat',
                isSelected: _currentNavIndex == 1,
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: _currentNavIndex == 2,
                onTap: () => setState(() => _currentNavIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 14,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  // ─── User List Body ─────────────────────────────────────────────────────────
  Widget _buildUserListBody(
    AgencyProvider provider,
    bool isDark,
    Color surfaceColor,
    Color surfaceHigh,
    Color borderColor, {
    void Function(AgencyUserItem user)? onUserTap,
  }) {
    if (provider.isLoading) {
      return ListView.builder(
        itemCount: 8,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        itemBuilder: (_, __) => const AgencyUserSkeletonTile(),
      );
    }

    if (provider.errorMessage != null && provider.users.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 60),
          alignment: Alignment.center,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                text: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: () => provider.fetchUsers(),
              ),
            ],
          ),
        ),
      );
    }

    final displayList = provider.filteredUsers;

    if (displayList.isEmpty) {
      String emptyMsg = 'No clients assigned yet.';
      IconData emptyIcon = Icons.people_outline_rounded;
      if (provider.searchQuery.isNotEmpty) {
        emptyMsg = 'No results for "${provider.searchQuery}"';
        emptyIcon = Icons.search_off_rounded;
      } else if (provider.selectedFilter == AgencyUserFilterTab.unread) {
        emptyMsg = 'No unread messages right now.';
        emptyIcon = Icons.mark_chat_read_rounded;
      } else if (provider.selectedFilter == AgencyUserFilterTab.online) {
        emptyMsg = 'No clients currently online.';
        emptyIcon = Icons.wifi_off_rounded;
      }

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 60),
          alignment: Alignment.center,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.agencyAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon,
                    size: 48,
                    color: AppColors.agencyAccent.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : const Color(0xFF64748B),
                ),
              ),
              if (provider.searchQuery.isNotEmpty ||
                  provider.selectedFilter != AgencyUserFilterTab.all) ...[
                const SizedBox(height: 16),
                AppSecondaryButton(
                  text: 'Reset Filters',
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearch();
                    provider.setFilter(AgencyUserFilterTab.all);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: displayList.length + (provider.isLoadingMore ? 2 : 0),
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      itemBuilder: (context, index) {
        if (index >= displayList.length) {
          return const AgencyUserSkeletonTile();
        }
        final user = displayList[index];
        return AgencyUserTile(
          user: user,
          onTap: () => onUserTap != null
              ? onUserTap(user)
              : _showClientDetailModal(context, user),
        );
      },
    );
  }
}

class _AgencyNotificationSkeletonList extends StatefulWidget {
  final bool isDark;
  const _AgencyNotificationSkeletonList({required this.isDark});

  @override
  State<_AgencyNotificationSkeletonList> createState() => _AgencyNotificationSkeletonListState();
}

class _AgencyNotificationSkeletonListState extends State<_AgencyNotificationSkeletonList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _opacityAnim = Tween<double>(begin: 0.25, end: 0.75).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark ? const Color(0xFF231E40) : const Color(0xFFE2E8F0);
    final borderColor = widget.isDark ? const Color(0xFF2E2756) : const Color(0xFFCBD5E1);

    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, child) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E1B3A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: _opacityAnim.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 14,
                          decoration: BoxDecoration(
                            color: baseColor.withValues(alpha: _opacityAnim.value),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 90,
                          height: 10,
                          decoration: BoxDecoration(
                            color: baseColor.withValues(alpha: _opacityAnim.value),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 22,
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: _opacityAnim.value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

