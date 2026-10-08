import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/validators.dart';

enum LoginRole { agency, employee }

class AgencyLoginScreen extends StatefulWidget {
  const AgencyLoginScreen({super.key});

  @override
  State<AgencyLoginScreen> createState() => _AgencyLoginScreenState();
}

class _AgencyLoginScreenState extends State<AgencyLoginScreen> {
  LoginRole _selectedRole = LoginRole.agency;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Color get _currentAccentColor {
    return _selectedRole == LoginRole.agency
        ? AppColors.agencyAccent // Purple (0xFF7C3AED / 0xFF6366F1)
        : const Color(0xFF10B981); // Emerald Green
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();

    final portalType = _selectedRole == LoginRole.agency ? 'agency' : 'employee';

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
      portalType: portalType,
    );

    if (!mounted) return;

    if (success && authProvider.currentUser != null) {
      final user = authProvider.currentUser!;
      final isEmployee = user.isEmployee || _selectedRole == LoginRole.employee;

      if (isEmployee) {
        context.go('/employee-dashboard');
      } else {
        context.go('/agency-dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bodyBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textPrimaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final accentColor = _currentAccentColor;

    final isAgency = _selectedRole == LoginRole.agency;

    return Scaffold(
      backgroundColor: bodyBgColor,
      body: Stack(
        children: [
          // Background Glow Orbs
          Positioned(
            top: -60,
            left: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Brand Logo Header
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFF0E0921),
                          border: Border.all(
                            color: const Color(0xFF00B2FF),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFF00B2FF).withValues(alpha: 0.25),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header Titles
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Dream',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: textPrimaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Hub',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF00B2FF),
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF00B2FF).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Role Subtitle Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              isAgency ? 'Agency Management' : 'Employee Verification',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAgency
                            ? 'Sign in to access your Dream Online Hub Agency Dashboard'
                            : 'Sign in to verify and manage Recharge & Withdrawal requests',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Role Selector Tabs (Agency vs Employee)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161F33) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // Agency Option
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_selectedRole != LoginRole.agency) {
                                    setState(() => _selectedRole = LoginRole.agency);
                                    authProvider.clearError();
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: isAgency
                                        ? (isDark ? const Color(0xFF282352) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isAgency
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings_rounded,
                                        size: 17,
                                        color: isAgency
                                            ? AppColors.agencyAccent
                                            : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Agency Login',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isAgency ? FontWeight.w800 : FontWeight.w600,
                                            color: isAgency
                                                ? (isDark ? Colors.white : AppColors.agencyAccent)
                                                : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Employee Option
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_selectedRole != LoginRole.employee) {
                                    setState(() => _selectedRole = LoginRole.employee);
                                    authProvider.clearError();
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: !isAgency
                                        ? (isDark ? const Color(0xFF13362B) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: !isAgency
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.badge_rounded,
                                        size: 17,
                                        color: !isAgency
                                            ? const Color(0xFF10B981)
                                            : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Employee Login',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: !isAgency ? FontWeight.w800 : FontWeight.w600,
                                            color: !isAgency
                                                ? (isDark ? Colors.white : const Color(0xFF10B981))
                                                : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                    // Login Form Card
                    Container(
                      padding: const EdgeInsets.all(22.0),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Portal Pill
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isAgency
                                        ? Icons.admin_panel_settings_rounded
                                        : Icons.badge_rounded,
                                    size: 16,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAgency
                                        ? 'AGENCY MANAGER LOGIN'
                                        : 'EMPLOYEE VERIFIER LOGIN',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Error Banner
                            if (authProvider.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        authProvider.errorMessage!,
                                        style: const TextStyle(color: AppColors.error, fontSize: 12.5, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                                      onPressed: () => authProvider.clearError(),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],

                            // Username / Mobile / Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.text,
                              validator: Validators.validateUsernameEmailOrPhone,
                              style: TextStyle(color: textPrimaryColor, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Username / Mobile / Email',
                                hintText: 'Enter Username, Mobile or Email',
                                prefixIcon: Icon(Icons.person_outline_rounded, color: accentColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: accentColor, width: 2),
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: Validators.validatePassword,
                              style: TextStyle(color: textPrimaryColor, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '••••••••',
                                prefixIcon: Icon(Icons.lock_outline_rounded, color: accentColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: accentColor, width: 2),
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sign In Action Button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: accentColor.withValues(alpha: 0.4),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isAgency
                                          ? [accentColor, AppColors.primary]
                                          : [const Color(0xFF10B981), const Color(0xFF059669)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: authProvider.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                isAgency
                                                    ? 'Sign In to Agency Portal'
                                                    : 'Sign In to Employee Portal',
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
