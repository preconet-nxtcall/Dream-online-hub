import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  int _selectedRoleIndex = 0; // 0 = Agency, 1 = User

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Color get _activeAccentColor {
    return _selectedRoleIndex == 0 ? AppColors.agencyAccent : AppColors.userAccent;
  }

  String get _activeRoleLabel {
    return _selectedRoleIndex == 0 ? 'Agency' : 'User';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
      portalType: _selectedRoleIndex == 0 ? 'agency' : 'user',
    );

    if (!mounted) return;

    if (success && authProvider.currentUser != null) {
      final user = authProvider.currentUser!;
      if (user.isAgency) {
        context.go('/agency-dashboard');
      } else {
        context.go('/user-dashboard');
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

    return Scaffold(
      backgroundColor: bodyBgColor,
      body: Stack(
        children: [
          // Background Gradient Glow Orbs
          Positioned(
            top: -60,
            left: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _activeAccentColor.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),

          // Main Login Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Icon with Dynamic Gradient
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_activeAccentColor, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: _activeAccentColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/icons/app_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header Text
                    Text(
                      'Apex Premier Portal',
                      style: GoogleFonts.outfit(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: textPrimaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to access your $_activeRoleLabel dashboard',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Main Glassmorphism Form Card
                    Container(
                      padding: const EdgeInsets.all(24.0),
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
                            // Segmented Role Selector Switcher
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedRoleIndex = 0),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _selectedRoleIndex == 0 ? AppColors.agencyAccent : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: _selectedRoleIndex == 0
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.agencyAccent.withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.business_rounded,
                                              size: 16,
                                              color: _selectedRoleIndex == 0 ? Colors.white : Colors.grey,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Agency Portal',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: _selectedRoleIndex == 0 ? Colors.white : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedRoleIndex = 1),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _selectedRoleIndex == 1 ? AppColors.userAccent : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: _selectedRoleIndex == 1
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.userAccent.withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person_rounded,
                                              size: 16,
                                              color: _selectedRoleIndex == 1 ? Colors.white : Colors.grey,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'User Portal',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: _selectedRoleIndex == 1 ? Colors.white : Colors.grey,
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
                            const SizedBox(height: 24),

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

                            // Email Address Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                              style: TextStyle(color: textPrimaryColor, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: _selectedRoleIndex == 0 ? 'agency@gmail.com' : 'user@gmail.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded, color: _activeAccentColor),
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
                                  borderSide: BorderSide(color: _activeAccentColor, width: 2),
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
                                prefixIcon: Icon(Icons.lock_outline_rounded, color: _activeAccentColor),
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
                                  borderSide: BorderSide(color: _activeAccentColor, width: 2),
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 26),

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
                                  shadowColor: _activeAccentColor.withValues(alpha: 0.4),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_activeAccentColor, AppColors.primary],
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
                                                'Sign In to $_activeRoleLabel Portal',
                                                style: const TextStyle(
                                                  fontSize: 15,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
