import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/agency_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_logout_dialog.dart';

class AgencyProfileScreen extends StatelessWidget {
  const AgencyProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    AppLogoutDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final agencyProvider = context.watch<AgencyProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final agency = chatProvider.assignedAgency;
    final agencyName = agency?['name'] ?? 'Apex Premier Agency Support';
    final agencyId = agency?['id'] ?? 'AGENCY-APEX-01';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. Agency Header Banner & Logo Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2128) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.agencyAccent, AppColors.primary],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: isDark ? const Color(0xFF2C2F36) : const Color(0xFFF1F5F9),
                          child: const Icon(
                            Icons.business_center_rounded,
                            size: 44,
                            color: AppColors.agencyAccent,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.agencyAccent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Text(
                            'OFFICIAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    agencyName,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.agencyAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CODE: $agencyId',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.agencyAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Client Operations Metrics Grid
            Row(
              children: [
                _buildOverviewCard(
                  title: 'Total Clients',
                  value: '${agencyProvider.users.length}',
                  icon: Icons.people_alt_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _buildOverviewCard(
                  title: 'Unread Queue',
                  value: '${agencyProvider.totalUnreadCount}',
                  icon: Icons.mark_chat_unread_rounded,
                  color: const Color(0xFFDC3545),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _buildOverviewCard(
                  title: 'Online Now',
                  value: '${agencyProvider.onlineUsersCount}',
                  icon: Icons.wifi_tethering_rounded,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Read-Only Agency Information
            const Text(
              'Agency Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2128) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.support_agent_rounded,
                    label: 'Support Helpline',
                    value: '+91 1800 888 999',
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.access_time_filled_rounded,
                    label: 'Operating Hours',
                    value: '24/7 Live Payouts & Support',
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.star_rounded,
                    label: 'Rating & Tier',
                    value: '4.9 ⭐ • PREMIER AGENCY',
                    isDark: isDark,
                    valueColor: const Color(0xFFFFD700),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.verified_rounded,
                    label: 'Verification Status',
                    value: 'Verified System Partner',
                    isDark: isDark,
                    valueColor: AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Higher Escalation & Logout Actions
            const Text(
              'Management Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Higher Authority Channel Action
            InkWell(
              onTap: () => context.push('/chat/admin_higher_authority'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC3545).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDC3545).withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Color(0xFFDC3545), size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Higher Authority',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFDC3545)),
                          ),
                          Text(
                            'Direct escalation channel to system admin',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFFDC3545)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Logout Action Button
            InkWell(
              onTap: () => _showLogoutDialog(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logout Portal',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error),
                          ),
                          Text(
                            'Sign out of agency admin portal',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.error),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2128) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.agencyAccent),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor ?? (isDark ? Colors.grey[300] : Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
