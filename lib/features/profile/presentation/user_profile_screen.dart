import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_logout_dialog.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    AppLogoutDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authProvider.currentUser;

    final userName = user?.name ?? 'Apex Premier User';
    final userEmail = user?.email ?? 'user@apex888.com';
    final userPhone = user?.phone ?? '+91 98765 43210';
    final userId = user?.id ?? 'USR-888-9921';

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile', style: TextStyle(fontWeight: FontWeight.bold)),
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
            // 1. User Header & Avatar Card
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
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: isDark ? const Color(0xFF2C2F36) : const Color(0xFFF1F5F9),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Text(
                            'VIP',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.userAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PLAYER ACCOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.userAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ID: $userId',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Account Overview Metrics Cards
            Row(
              children: [
                _buildOverviewCard(
                  title: 'Wallet Balance',
                  value: '₹0.00',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFFFFD700),
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildOverviewCard(
                  title: 'Total Bids',
                  value: '12 Played',
                  icon: Icons.casino_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Read-Only Account Details Section
            const Text(
              'Account Information',
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
                    icon: Icons.phone_rounded,
                    label: 'Phone Number',
                    value: userPhone,
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.email_rounded,
                    label: 'Email Address',
                    value: userEmail,
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.verified_user_rounded,
                    label: 'Account Status',
                    value: 'Active • KYC Verified',
                    isDark: isDark,
                    valueColor: AppColors.success,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Member Since',
                    value: 'August 2026',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Quick Actions (Support & Logout)
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Support Chat Action Button
            InkWell(
              onTap: () => context.push('/chat/agency_support'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Support Helpdesk',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Chat live with customer support & recharge agent',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.primary),
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
                            'Logout',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error),
                          ),
                          Text(
                            'Sign out of account on this device',
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2128) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
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
          Icon(icon, size: 22, color: AppColors.primary),
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
