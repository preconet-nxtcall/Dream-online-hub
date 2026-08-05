import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      if (authProvider.currentUser!.isAgency) {
        context.go('/agency-dashboard');
      } else {
        context.go('/user-dashboard');
      }
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
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0E0921),
                          border: Border.all(
                            color: const Color(0xFFFFC700),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFC700).withValues(alpha: 0.4),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC700),
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // GOLDEN 888 Branding Title
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'GOLDEN ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            TextSpan(
                              text: '888',
                              style: TextStyle(
                                color: Color(0xFFFFC700),
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tagline Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1035),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Text(
                          'PREMIUM GAMING & AGENCY PORTAL',
                          style: TextStyle(
                            color: Color(0xFFC4B5FD),
                            fontSize: 10.5,
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
