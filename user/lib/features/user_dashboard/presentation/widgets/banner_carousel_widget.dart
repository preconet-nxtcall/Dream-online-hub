import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';

class BannerItemData {
  final String subtitle;
  final String title;
  final String badgeText;
  final IconData icon;
  final String? networkImageUrl;
  final String? assetImagePath;
  final List<Color> gradientColors;
  final Color accentColor;

  const BannerItemData({
    required this.subtitle,
    required this.title,
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
      subtitle: 'PLAY SATTA MATKA',
      title: 'ONLINE',
      badgeText: 'INSTANT PAYOUTS',
      icon: Icons.casino_rounded,
      networkImageUrl: 'https://telewiz.in/officemanage/uploads/photos/1784883728_Slider.png',
      assetImagePath: 'assets/images/satta_matka_banner.png',
      gradientColors: [
        Color(0xFF1F222A),
        Color(0xFF14161C),
        Color(0xFF0F1015),
      ],
      accentColor: Color(0xFFFFD700),
    ),
    BannerItemData(
      subtitle: 'PLAY RUMMY GAME',
      title: 'ONLINE',
      badgeText: '24/7 LIVE TABLES',
      icon: Icons.style_rounded,
      assetImagePath: 'assets/images/rummy_banner.png',
      gradientColors: [
        Color(0xFF1A1C29),
        Color(0xFF121420),
        Color(0xFF0A0C16),
      ],
      accentColor: Color(0xFFFF5252),
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
      children: [
        SizedBox(
          height: 155,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: bannerCount,
            itemBuilder: (context, index) {
              if (displayBanners != null) {
                return _buildNetworkImageBanner(displayBanners[index]);
              }
              final banner = _bannerItems[index];
              return _buildBannerCard(banner);
            },
          ),
        ),
        const SizedBox(height: 8),

        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(bannerCount, (index) {
            final isSelected = index == _currentIndex;
            final activeColor = hasCustomBanners ? const Color(0xFFFFD700) : _bannerItems[index].accentColor;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isSelected ? 22 : 6,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildNetworkImageBanner(String imageUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildBannerCard(_bannerItems.first);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF14161C),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: Color(0xFFFFD700),
              strokeWidth: 2,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerCard(BannerItemData banner) {
    if (banner.networkImageUrl != null && banner.networkImageUrl!.isNotEmpty) {
      return _buildNetworkImageBanner(banner.networkImageUrl!);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: banner.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: banner.accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Background Glow Orbs
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: banner.accentColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: banner.accentColor.withValues(alpha: 0.12),
              ),
            ),
          ),

          // Content Row Layout
          Padding(
            padding: AppSpacing.pAllLg,
            child: Row(
              children: [
                // Left Icon / Image Thumbnail Container
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: banner.accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: banner.accentColor, width: 1.5),
                  ),
                  child: ClipOval(
                    child: banner.assetImagePath != null
                        ? Image.asset(
                            banner.assetImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                banner.icon,
                                size: 36,
                                color: banner.accentColor,
                              );
                            },
                          )
                        : Icon(
                            banner.icon,
                            size: 36,
                            color: banner.accentColor,
                          ),
                  ),
                ),
                AppSpacing.hGapLg,

                // Right Title & Badges
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            banner.accentColor,
                            Colors.white,
                            banner.accentColor,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          banner.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            height: 1.0,
                          ),
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: banner.accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          banner.badgeText,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
