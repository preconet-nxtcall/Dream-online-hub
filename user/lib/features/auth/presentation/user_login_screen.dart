import 'dart:async';
import 'package:flutter/material.dart';
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
      // OTP verification failed — error message displayed by authProvider
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
      // Reset session to unauthenticated state so user signs in via login form
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

    const cardBgColor = Color(0xFF0B1536);
    const bodyBgColor = Color(0xFF070D22);
    const textPrimaryColor = Colors.white;
    const textSecondaryColor = Color(0xFF8E9BAE);
    const inputFillColor = Color(0xFF070D22);
    const inputBorderColor = Color(0xFF1E2D5A);

    return Scaffold(
      backgroundColor: bodyBgColor,
      body: Stack(
        children: [
          // Ambient Neon Glow Orbs matching Dashboard
          Positioned(
            top: -70,
            left: -70,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.18),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 50,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryBlue.withValues(alpha: 0.22),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.22),
                    blurRadius: 60,
                    spreadRadius: 25,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: _isRegisterMode ? 12.0 : 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [


                    // DreamHub Official Brand Banner Logo Below
                    Container(
                      constraints: const BoxConstraints(maxWidth: 290, maxHeight: 85),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Image.asset(
                        'assets/images/dreamhub_banner_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isRegisterMode
                          ? 'Create an account to access Dream Online Hub User Portal'
                          : 'Sign in to access your Dream Online Hub User Portal',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Main Glassmorphism Cyber Form Card Container
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: _isRegisterMode ? 20.0 : 24.0,
                      ),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: primaryBlue.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 26,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.1),
                            blurRadius: 16,
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
                            // Header Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.verified_user_rounded, size: 15, color: accentColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isRegisterMode ? 'REGISTER NEW ACCOUNT' : 'PLAYER USER LOGIN',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: accentColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: _isRegisterMode ? 16 : 20),

                            // Error Banner
                            if (authProvider.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authProvider.errorMessage!,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
                                      onPressed: () => authProvider.clearError(),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // 2-STEP REGISTER FORM WITH OTP VERIFICATION
                            if (_isRegisterMode) ...[
                              if (_registrationStep == 1) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Register',
                                      style: GoogleFonts.outfit(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: textPrimaryColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person_add_alt_1_rounded, size: 14, color: accentColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            'STEP 1 OF 2',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
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
                                const SizedBox(height: 14),

                                // Go To Login Link
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () => _switchMode(false),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Go To Login',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: accentColor,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: accentColor,
                                          size: 16,
                                        ),
                                      ],
                                    ),
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
                                                  Text(
                                                    'Send Verification Code',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3,
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
                              ] else ...[
                                // STEP 2: OTP VERIFICATION VIEW
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Verify OTP',
                                      style: GoogleFonts.outfit(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: textPrimaryColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.shield_outlined, size: 14, color: accentColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            'STEP 2 OF 2',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
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
                                const SizedBox(height: 12),

                                // Phone number summary pill with edit icon
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: inputFillColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: inputBorderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone_iphone_rounded, size: 18, color: accentColor),
                                      const SizedBox(width: 8),
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
                                                fontSize: 13.5,
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
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            'Edit Phone',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
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
                                    Text(
                                      "Didn't get code?",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        color: textSecondaryColor,
                                      ),
                                    ),
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
                                                  Text(
                                                    'Verify & Create Account',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3,
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
                            ] else ...[
                              // RENDER LOGIN FORM
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.validateEmail,
                                style: GoogleFonts.plusJakartaSans(color: textPrimaryColor, fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: GoogleFonts.plusJakartaSans(color: textSecondaryColor, fontSize: 13),
                                  hintText: 'Email',
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

                              SizedBox(
                                height: 50,
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
                                                Text(
                                                  'Sign In to User Portal',
                                                  style: GoogleFonts.plusJakartaSans(
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
                              const SizedBox(height: 20),

                              // Register Now Row Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                              const SizedBox(height: 6),
                            ],
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
