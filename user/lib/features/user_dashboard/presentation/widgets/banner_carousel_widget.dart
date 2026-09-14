import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BannerItemData {
  final String subtitle;
  final String title;
  final String description;
  final String buttonText;
  final String badgeText;
  final IconData icon;
  final String? networkImageUrl;
  final String? assetImagePath;
  final List<Color> gradientColors;
  final Color accentColor;

  const BannerItemData({
    required this.subtitle,
    required this.title,
    this.description = 'Assign tasks, track progress, monitor performance, automate reminders, and keep your entire team connected in real time.',
    this.buttonText = 'Subscriptions',
    required this.badgeText,
    required this.icon,
    this.networkImageUrl,
    this.assetImagePath,
    required this.gradientColors,
    required this.accentColor,
  });
}

class BannerCarouselWidget extends StatefulWidget {
  final List<String>? networkBannerUrls;
  const BannerCarouselWidget({super.key, this.networkBannerUrls});

  @override
  State<BannerCarouselWidget> createState() => _BannerCarouselWidgetState();
}

class _BannerCarouselWidgetState extends State<BannerCarouselWidget> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  static const List<BannerItemData> _bannerItems = [
    BannerItemData(
      subtitle: 'PLAY  •  WIN  •  REPEAT',
      title: 'Boost Productivity &\nCollaboration',
      description: 'Assign tasks, track progress, monitor performance, automate reminders, and keep your entire team connected in real time.',
      buttonText: 'Subscriptions',
      badgeText: 'INSTANT PAYOUTS',
      icon: Icons.casino_rounded,
      assetImagePath: 'assets/images/satta_matka_banner.png',
      networkImageUrl: 'https://dreamonlinehub.club/uploads/photos/1784883728_Slider.png',
      gradientColors: [
        Color(0xFF070F28),
        Color(0xFF050B1F),
        Color(0xFF030716),
      ],
      accentColor: Color(0xFF00D2FF),
    ),
    BannerItemData(
      subtitle: 'LIVE  •  TABLES  •  24/7',
      title: 'Experience Premier\nLive Gaming',
      description: 'Join live tables, compete with top players, monitor scores, and elevate your gaming experience!',
      buttonText: 'Play Now',
      badgeText: '24/7 LIVE TABLES',
      icon: Icons.style_rounded,
      assetImagePath: 'assets/images/rummy_banner.png',
      gradientColors: [
        Color(0xFF091436),
        Color(0xFF060E28),
        Color(0xFF030716),
      ],
      accentColor: Color(0xFF00E5FF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final totalCount = (widget.networkBannerUrls != null && widget.networkBannerUrls!.isNotEmpty)
          ? (widget.networkBannerUrls!.length > 4 ? 4 : widget.networkBannerUrls!.length)
          : _bannerItems.length;
      if (totalCount <= 1) return;
      final nextIndex = (_currentIndex + 1) % totalCount;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant BannerCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkBannerUrls != widget.networkBannerUrls) {
      _currentIndex = 0;
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomBanners = widget.networkBannerUrls != null && widget.networkBannerUrls!.isNotEmpty;
    final displayBanners = hasCustomBanners ? widget.networkBannerUrls!.take(4).toList() : null;
    final bannerCount = displayBanners != null ? displayBanners.length : _bannerItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 215,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: bannerCount,
            itemBuilder: (context, index) {
              final defaultBanner = _bannerItems[index % _bannerItems.length];
              final overrideUrl = (displayBanners != null && displayBanners.isNotEmpty)
                  ? displayBanners[index]
                  : null;
              return _buildBannerCard(
                defaultBanner,
                index,
                bannerCount,
                overrideNetworkUrl: overrideUrl,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBannerCard(
    BannerItemData banner,
    int index,
    int totalCount, {
    String? overrideNetworkUrl,
  }) {
    final networkUrl = overrideNetworkUrl ?? banner.networkImageUrl;

    return Container(
      width: double.infinity,
      height: 215,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF070F28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF0066FF).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Full-Width Background Image (Completely Visible)
          Positioned.fill(
            child: networkUrl != null && networkUrl.isNotEmpty
                ? Image.network(
                    networkUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) {
                      if (banner.assetImagePath != null) {
                        return Image.asset(
                          banner.assetImagePath!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  )
                : (banner.assetImagePath != null
                    ? Image.asset(
                        banner.assetImagePath!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Container(
                        color: const Color(0xFF070F28),
                      )),
          ),

          // 2. Soft Dark Protection Vignette for Text Contrast
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xF5050A1A),
                    Color(0xD0070F28),
                    Color(0x80070F28),
                    Color(0x30070F28),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.40, 0.65, 0.85, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // 3. Upper Font / Text Content & Subscriptions Button Overlay
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Upper Tagline (PLAY • WIN • REPEAT)
                Text(
                  banner.subtitle,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.4,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Main Bold Header Title
                Text(
                  banner.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.3,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 6),

                // Subtitle / Description text
                SizedBox(
                  width: 260,
                  child: Text(
                    banner.description,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFD1D5DB),
                      fontSize: 11.5,
                      height: 1.32,
                      fontWeight: FontWeight.w400,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),

                // Bottom Row: Subscriptions Pill Button & Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Subscriptions Pill Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00D2FF),
                            Color(0xFF2563EB),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D2FF).withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  banner.buttonText,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Indicator Dots
                    _buildIndicatorDots(totalCount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorDots(int bannerCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(bannerCount, (index) {
        final isSelected = index == _currentIndex;
        const activeColor = Color(0xFF00D2FF);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 7,
          width: isSelected ? 22 : 7,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D2FF).withValues(alpha: 0.7),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

