import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/validators.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  static const Color accentColor = Color(0xFF00D2FF); // Electric Cyan
  static const Color primaryBlue = Color(0xFF0066FF); // Royal Blue
  static const Color cardBgColor = Color(0xFF0A1333);
  static const Color bodyBgColor = Color(0xFF05091A);
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Color(0xFF94A3B8);
  static const Color inputFillColor = Color(0xFF070E26);
  static const Color inputBorderColor = Color(0xFF1E2D5A);

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _isRegisterMode = false;

  // 2-Step Registration Flow
  int _registrationStep = 1; // 1: Info input, 2: OTP verification
  int _resendCountdown = 30;
  Timer? _resendTimer;
  String? _serverOtpHint;
  String? _otpSuccessMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: bodyBgColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _switchMode(bool registerMode) {
    FocusScope.of(context).unfocus();
    context.read<AuthProvider>().clearError();
    _formKey.currentState?.reset();
    _resendTimer?.cancel();
    setState(() {
      _isRegisterMode = registerMode;
      _registrationStep = 1;
      _otpController.clear();
      _serverOtpHint = null;
      _otpSuccessMessage = null;
    });
  }

  void _goToStepOne() {
    FocusScope.of(context).unfocus();
    context.read<AuthProvider>().clearError();
    _resendTimer?.cancel();
    setState(() {
      _registrationStep = 1;
      _otpController.clear();
      _serverOtpHint = null;
      _otpSuccessMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
      portalType: 'user',
    );

    if (!mounted) return;

    if (success && authProvider.currentUser != null) {
      context.go('/user-dashboard');
    }
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();

    final phone = _phoneController.text.trim();
    final res = await authProvider.sendOtp(phone);

    if (!mounted) return;

    if (res != null) {
      final msg = res['message']?.toString() ?? 'OTP sent to your phone!';
      final hint = (res['otp'] != null && res['otp'].toString().isNotEmpty)
          ? res['otp'].toString()
          : null;

      setState(() {
        _otpSuccessMessage = msg;
        _serverOtpHint = hint;
        _registrationStep = 2;
      });
      _startResendTimer();
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;
    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();

    final phone = _phoneController.text.trim();
    final res = await authProvider.sendOtp(phone);

    if (!mounted) return;

    if (res != null) {
      final msg = res['message']?.toString() ?? 'OTP Resent successfully!';
      final hint = (res['otp'] != null && res['otp'].toString().isNotEmpty)
          ? res['otp'].toString()
          : null;

      setState(() {
        _otpSuccessMessage = msg;
        _serverOtpHint = hint;
      });
      _startResendTimer();
    }
  }

  Future<void> _handleVerifyAndRegister() async {
    final otpCode = _otpController.text.trim();
    if (otpCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code received on your phone.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 1. Verify OTP with backend action "verify_otp"
    final isVerified = await authProvider.verifyOtp(phone, otpCode);

    if (!mounted) return;

    if (!isVerified) {
      return;
    }

    // 2. OTP verified successfully -> proceed to create account
    final success = await authProvider.register(
      _fullNameController.text.trim(),
      email,
      phone,
      password,
    );

    if (!mounted) return;

    if (success) {
      await authProvider.logout();

      if (!mounted) return;

      setState(() {
        _isRegisterMode = false;
        _registrationStep = 1;
        _emailController.text = email;
        _passwordController.text = password;
        _otpController.clear();
        _serverOtpHint = null;
        _otpSuccessMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created successfully! Your credentials have been prefilled. Tap Sign In to proceed.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          backgroundColor: const Color(0xFF0066FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: bodyBgColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bodyBgColor,
        body: Stack(
        children: [
          // Background Ambient Dynamic Glow Orbs
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.16),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.22),
                    blurRadius: 90,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryBlue.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 100,
                    spreadRadius: 35,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                    blurRadius: 70,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: _isRegisterMode ? 14.0 : 24.0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Brand Logo Badge Container
                            Container(
                              width: 88,
                              height: 88,
                              padding: const EdgeInsets.all(3.5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: const LinearGradient(
                                  colors: [accentColor, primaryBlue, Color(0xFF7C3AED)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.38),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFF090E26),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // App Title & Subtitle Header
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Dream ',
                                    style: GoogleFonts.outfit(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Online Hub',
                                    style: GoogleFonts.outfit(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: accentColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isRegisterMode
                                  ? 'Create a player account to start gaming'
                                  : 'Sign in to your player account portal',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Main Glassmorphism Form Card Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: EdgeInsets.symmetric(
                                horizontal: 22.0,
                                vertical: _isRegisterMode ? 22.0 : 26.0,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cardBgColor.withValues(alpha: 0.95),
                                    const Color(0xFF070D26).withValues(alpha: 0.98),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.28),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.12),
                                    blurRadius: 20,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Segmented Mode Switcher (Sign In vs Register)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF050A1E),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: primaryBlue.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                if (_isRegisterMode) _switchMode(false);
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                decoration: BoxDecoration(
                                                  gradient: !_isRegisterMode
                                                      ? const LinearGradient(
                                                          colors: [accentColor, primaryBlue],
                                                        )
                                                      : null,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: !_isRegisterMode
                                                      ? [
                                                          BoxShadow(
                                                            color: accentColor.withValues(alpha: 0.35),
                                                            blurRadius: 10,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.login_rounded,
                                                        size: 16,
                                                        color: !_isRegisterMode ? Colors.white : textSecondaryColor,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            'Sign In',
                                                            style: GoogleFonts.plusJakartaSans(
                                                              fontSize: 13,
                                                              fontWeight: !_isRegisterMode ? FontWeight.w800 : FontWeight.w600,
                                                              color: !_isRegisterMode ? Colors.white : textSecondaryColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                if (!_isRegisterMode) _switchMode(true);
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                decoration: BoxDecoration(
                                                  gradient: _isRegisterMode
                                                      ? const LinearGradient(
                                                          colors: [accentColor, primaryBlue],
                                                        )
                                                      : null,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: _isRegisterMode
                                                      ? [
                                                          BoxShadow(
                                                            color: accentColor.withValues(alpha: 0.35),
                                                            blurRadius: 10,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.person_add_alt_1_rounded,
                                                        size: 16,
                                                        color: _isRegisterMode ? Colors.white : textSecondaryColor,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            'Register',
                                                            style: GoogleFonts.plusJakartaSans(
                                                              fontSize: 13,
                                                              fontWeight: _isRegisterMode ? FontWeight.w800 : FontWeight.w600,
                                                              color: _isRegisterMode ? Colors.white : textSecondaryColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: _isRegisterMode ? 18 : 22),

                                    // Error Banner
                                    if (authProvider.errorMessage != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                authProvider.errorMessage!,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: AppColors.error,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
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
                                      const SizedBox(height: 16),
                                    ],

                                    // Content Form Switching View
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      child: _isRegisterMode
                                          ? (_registrationStep == 1
                                              ? _buildRegisterStepOne(context, authProvider)
                                              : _buildRegisterStepTwo(context, authProvider))
                                          : _buildLoginForm(context, authProvider),
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

                // Docked Bottom Footer Version Badge
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: textSecondaryColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      'v1.0.0',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textSecondaryColor,
                        letterSpacing: 1.0,
                      ),
                    ),
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

  Widget _buildLoginForm(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          style: GoogleFonts.plusJakartaSans(color: textPrimaryColor, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: GoogleFonts.plusJakartaSans(color: textSecondaryColor, fontSize: 13),
            hintText: 'Enter your email',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
            prefixIcon: const Icon(Icons.mail_outline_rounded, color: accentColor, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor: inputFillColor,
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: Validators.validatePassword,
          style: GoogleFonts.plusJakartaSans(color: textPrimaryColor, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: GoogleFonts.plusJakartaSans(color: textSecondaryColor, fontSize: 13),
            hintText: '••••••••',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: accentColor, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: textSecondaryColor,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor: inputFillColor,
          ),
        ),
        const SizedBox(height: 22),

        // Submit Sign In Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: accentColor.withValues(alpha: 0.45),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [accentColor, primaryBlue],
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
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Sign In to User Portal',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Footer Switch to Register Link
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () => _switchMode(true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Register Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: accentColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterStepOne(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Column(
      key: const ValueKey('register_step_1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step Header Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Account Information',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 13, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    'STEP 1 OF 2',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Full Name
        TextFormField(
          controller: _fullNameController,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
          style: GoogleFonts.plusJakartaSans(color: textPrimaryColor, fontSize: 13.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: GoogleFonts.plusJakartaSans(color: textSecondaryColor, fontSize: 13),
            hintText: 'Full Name',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
            isDense: true,
            prefixIcon: const Icon(Icons.person_outline_rounded, color: accentColor, size: 19),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor: inputFillColor,
          ),
        ),
        const SizedBox(height: 12),

        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          style: GoogleFonts.plusJakartaSans(color: textPrimaryColor, fontSize: 13.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: GoogleFonts.plusJakartaSans(color: textSecondaryColor, fontSize: 13),
            hintText: 'Email',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
            isDense: true,
            prefixIcon: const Icon(Icons.mail_outline_rounded, color: accentColor, size: 19),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor: inputFillColor,
          ),
        ),
        const SizedBox(height: 12),

        // Phone Number
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          validator: Validators.validatePhone,
          style: GoogleFonts.plusJakartaSans(color: textPrimaryColor, fontSize: 13.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            labelStyle: GoogleFonts.plusJakartaSans(color: textSecondaryColor, fontSize: 13),
            hintText: '10-digit Phone Number',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
            counterText: '',
            isDense: true,
            prefixIcon: const Icon(Icons.phone_iphone_rounded, color: accentColor, size: 19),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor: inputFillColor,
          ),
        ),
        const SizedBox(height: 12),

        // Password
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: Validators.validatePassword,
          style: GoogleFonts.plusJakartaSans(color: textPrimaryColor, fontSize: 13.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: GoogleFonts.plusJakartaSans(color: textSecondaryColor, fontSize: 13),
            hintText: '••••••••',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
            isDense: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: accentColor, size: 19),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: textSecondaryColor,
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: accentColor, width: 2),
            ),
            filled: true,
            fillColor: inputFillColor,
          ),
        ),
        const SizedBox(height: 18),

        // Send OTP Action Button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: accentColor.withValues(alpha: 0.45),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [accentColor, primaryBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                alignment: Alignment.center,
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Send Verification Code',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterStepTwo(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Column(
      key: const ValueKey('register_step_2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step Header Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Verify OTP Code',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 13, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    'STEP 2 OF 2',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Phone summary card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: inputBorderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_iphone_rounded, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code sent to phone:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: textSecondaryColor,
                      ),
                    ),
                    Text(
                      _phoneController.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _goToStepOne,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Success message banner
        if (_otpSuccessMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _otpSuccessMessage!,
                    style: GoogleFonts.plusJakartaSans(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Server OTP Hint Badge (if backend returns OTP in response)
        if (_serverOtpHint != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verification Code: ${_serverOtpHint!}',
                    style: GoogleFonts.plusJakartaSans(
                      color: accentColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // OTP Input Field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: GoogleFonts.outfit(
            color: textPrimaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 8.0,
          ),
          decoration: InputDecoration(
            labelText: 'Enter OTP Code',
            labelStyle: GoogleFonts.plusJakartaSans(color: textSecondaryColor, fontSize: 13),
            hintText: '••••••',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
            counterText: '',
            isDense: true,
            prefixIcon: const Icon(Icons.lock_clock_outlined, color: accentColor, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: accentColor, width: 2.2),
            ),
            filled: true,
            fillColor: inputFillColor,
          ),
        ),
        const SizedBox(height: 12),

        // Resend Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Didn't get code?",
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: textSecondaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: (_resendCountdown == 0 && !authProvider.isLoading)
                  ? _handleResendOtp
                  : null,
              child: Text(
                _resendCountdown > 0
                    ? 'Resend in ${_resendCountdown}s'
                    : 'Resend OTP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: _resendCountdown > 0 ? textSecondaryColor : accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Verify & Create Account Button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleVerifyAndRegister,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: accentColor.withValues(alpha: 0.45),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [accentColor, primaryBlue],
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
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Verify & Create Account',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
