import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    final authProvider = context.read<AuthProvider>();
    
    // Fast snappy splash delay
    await Future.delayed(const Duration(milliseconds: 250));

    final isLoggedIn = await authProvider.checkAutoLogin();

    if (!mounted) return;

    if (isLoggedIn && authProvider.currentUser != null) {
      context.go('/agency-dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF04020A),
              Color(0xFF0C0720),
              Color(0xFF1B0B47),
              Color(0xFF04020A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Glowing Animated Logo Box
              ScaleTransition(
                scale: _scaleAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Container(
                        width: 105,
                        height: 105,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: const Color(0xFF0E0921),
                          border: Border.all(
                            color: const Color(0xFF00B2FF),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B2FF).withValues(alpha: 0.4),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // DreamHub Agency CRM Branding Title
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Dream',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Hub',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF00B2FF),
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF00B2FF).withValues(alpha: 0.5),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1035),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00B2FF).withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B2FF).withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          'DREAM ONLINE HUB AGENCY',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF00B2FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Loading & Progress Indicator
              const Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFC700),
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Initializing secure connection...',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
