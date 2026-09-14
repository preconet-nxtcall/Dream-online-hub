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
      context.go('/user-dashboard');
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

              // Glowing Animated Logo Box & Banner Header
              ScaleTransition(
                scale: _scaleAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      // Upper Glowing App Logo Badge
                      Container(
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: const Color(0xFF0E0921),
                          border: Border.all(
                            color: const Color(0xFF00B2FF),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B2FF).withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                              blurRadius: 36,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // DreamHub Official Brand Banner Logo Below
                      Container(
                        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 100),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Image.asset(
                          'assets/images/dreamhub_banner_logo.png',
                          fit: BoxFit.contain,
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
