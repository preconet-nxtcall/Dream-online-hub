import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/agency_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_buttons.dart';
import '../../../widgets/common/app_loading.dart';
import '../../../widgets/common/app_logout_dialog.dart';
import 'widgets/agency_user_skeleton_tile.dart';
import 'widgets/agency_user_tile.dart';

class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AgencyProvider>().loadNextPage();
    }
  }

  int _currentNavIndex = 0;

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
        child: Column(
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
                    const SizedBox(height: 14),

                    // Filter Pills
                    _buildFilterRow(agencyProvider: agencyProvider, isDark: isDark),
                    const SizedBox(height: 16),

                    // Client Conversations Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Client Conversations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
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
        ),
      ),

      // Bottom Navigation Bar with Floating '+' Button
      bottomNavigationBar: _buildAgencyBottomNavBar(isDark),
    );
  }

  // ─── Header Container ──────────────────────────────────────────────────────
  Widget _buildHeaderBackground({
    required BuildContext context,
    required dynamic user,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 52),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0720),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Logo Avatar 'A'
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
            child: const Text(
              'A',
              style: TextStyle(
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

          // Right Profile Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/agency-profile'),
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
                child: const Icon(Icons.person_outline_rounded, color: Color(0xFFA78BFA), size: 20),
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            iconBg: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF6366F1),
            value: '${provider.users.length}',
            label: 'Total Clients',
            isDark: isDark,
          ),
          Container(width: 1, height: 36, color: Colors.grey.withValues(alpha: 0.15)),

          // Unread Stat
          _buildMetricColumn(
            icon: Icons.description_rounded,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF59E0B),
            value: '${provider.totalUnreadCount}',
            label: 'Unread',
            isDark: isDark,
          ),
          Container(width: 1, height: 36, color: Colors.grey.withValues(alpha: 0.15)),

          // Online Stat
          _buildMetricColumn(
            icon: Icons.circle,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            value: '${provider.onlineUsersCount}',
            label: 'Online',
            isDark: isDark,
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
  }) {
    return Expanded(
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
          Column(
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
              ),
            ],
          ),
        ],
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

  // ─── Filter Chips Row ──────────────────────────────────────────────────────
  Widget _buildFilterRow({
    required AgencyProvider agencyProvider,
    required bool isDark,
  }) {
    final filters = [
      (AgencyUserFilterTab.all, 'All Clients', agencyProvider.users.length, Icons.people_rounded),
      (AgencyUserFilterTab.unread, 'Unread', agencyProvider.totalUnreadCount, Icons.mail_outline_rounded),
      (AgencyUserFilterTab.online, 'Online', agencyProvider.onlineUsersCount, Icons.circle),
    ];

    return Row(
      children: filters.map((f) {
        final tab = f.$1;
        final label = f.$2;
        final count = f.$3;
        final icon = f.$4;
        final isSelected = agencyProvider.selectedFilter == tab;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => agencyProvider.setFilter(tab),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0F092E)
                      : (isDark ? const Color(0xFF1B1836) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0F092E)
                        : const Color(0xFFE2E0FF),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: icon == Icons.circle ? 8 : 14,
                      color: isSelected
                          ? Colors.white
                          : (icon == Icons.circle
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$label ($count)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Floating Dark Pill Bottom Navigation Bar (Matching User Dashboard) ────
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
                icon: Icons.home_rounded,
                label: 'Dashboard',
                isSelected: _currentNavIndex == 0,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
              _buildNavItem(
                icon: Icons.people_outline_rounded,
                label: 'Clients',
                isSelected: _currentNavIndex == 1,
                onTap: () => setState(() => _currentNavIndex = 1),
              ),

              // Floating Center Circular Action Button (+)
              Transform.translate(
                offset: const Offset(0, -4),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                    onPressed: () {},
                  ),
                ),
              ),

              _buildNavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                isSelected: _currentNavIndex == 2,
                onTap: () => setState(() => _currentNavIndex = 2),
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: _currentNavIndex == 3,
                onTap: () => context.push('/agency-profile'),
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
    Color borderColor,
  ) {
    if (provider.isLoading) {
      return ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.only(top: 4),
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
      itemCount: displayList.length + (provider.isLoadingMore ? 1 : 0),
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      itemBuilder: (context, index) {
        if (index == displayList.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: AppLoadingSpinner(size: 28),
          );
        }
        final user = displayList[index];
        return AgencyUserTile(
          user: user,
          onTap: () => context.push('/chat/${user.id}', extra: user),
        );
      },
    );
  }
}
